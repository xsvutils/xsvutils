use crate::util;
use lazy_static::lazy_static;
use memchr::memchr;
use regex::Regex;
use std::io;
use std::io::BufRead;
use std::io::Write;
use std::iter;
use url;

pub struct UriParamsCommand;
impl crate::command::Command for UriParamsCommand {
    fn execute<R: BufRead, W: Write>(
        args: Vec<String>,
        input: &mut R,
        output: &mut W,
    ) -> Result<(), io::Error> {
        uriparams(args, input, output)
    }
}

// ---- command line arguments -------------------------------------------------

#[derive(Debug, Copy, Clone)]
enum AB {
    A,
    B,
}

impl Default for AB {
    fn default() -> Self {
        AB::A
    }
}

#[derive(Debug)]
enum Decode {
    UTF8,
    ShiftJIS,
    None,
}

impl Default for Decode {
    fn default() -> Self {
        Decode::UTF8
    }
}

#[derive(Debug, Default)]
struct CmdOpt {
    names: String,
    name_list: bool,
    col: String,
    decode: Decode,
    multi_value: AB,
}

impl CmdOpt {
    pub fn parse(mut args: Vec<String>) -> CmdOpt {
        let mut opt = CmdOpt::default();
        while args.len() > 0 {
            let arg = args.remove(0);
            match arg.as_str() {
                "--names" => {
                    opt.names = util::pop_first_or_else(&mut args, || {
                        die!("option --names needs an argument")
                    })
                }
                "--name-list" => opt.name_list = true,
                "--col" => {
                    opt.col = util::pop_first_or_else(&mut args, || {
                        die!("option --col needs an argument")
                    })
                }
                "--no-decode" => opt.decode = Decode::None,
                "--sjis" => opt.decode = Decode::ShiftJIS,
                "--multi-value-a" => opt.multi_value = AB::A,
                "--multi-value-b" => opt.multi_value = AB::B,
                _ => die!("Unknown argument: {}", &arg),
            }
        }
        return opt;
    }
}

// ---- main procedure ---------------------------------------------------------

fn uriparams<R: BufRead, W: Write>(
    args: Vec<String>,
    input: &mut R,
    output: &mut W,
) -> Result<(), io::Error> {
    let opt = CmdOpt::parse(args);

    let mut buff = String::new();
    let (index, num_cols) = {
        let len = input.read_line(&mut buff)?;
        if len == 0 {
            die!(); // NoInput
        }
        let header: Vec<_> = buff.trim_end().split("\t").collect();
        let index = match header.iter().position(|&x| x == &opt.col) {
            Some(x) => x,
            None => {
                // uri のある列が無いので cat のように振る舞う
                eprintln!("Unknown column: {}", &opt.col);
                output.write_all(buff.as_bytes())?;
                io::copy(input, output)?;;
                return Ok(());
            }
        };

        // write header
        for h in &header {
            output.write_all(h.as_bytes())?;
            output.write_all(b"\t")?;
        }
        if opt.name_list {
            output.write_all(b"name-list\n")?;
        } else {
            let mut first = true;
            for name in opt.names.split(",") {
                if first {
                    first = false;
                } else {
                    output.write_all(b"\t")?;
                }
                output.write_all(name.as_bytes())?;
            }
            output.write_all(b"\n")?;
            output.flush()?;
        }
        (index, header.len())
    };
    let names: Vec<_> = opt.names.split(",").collect();
    loop {
        buff.clear();
        let len = input.read_line(&mut buff)?;
        if len == 0 {
            return Ok(());
        }
        let row: Vec<_> = buff
            .trim_end()
            .split("\t")
            .chain(iter::repeat(""))
            .take(num_cols)
            .collect();
        for cell in &row {
            output.write_all(cell.as_bytes())?;
            output.write_all(b"\t")?;
        }
        let url = row[index].as_bytes();
        let append = match (opt.name_list, opt.multi_value) {
            (true, AB::A) => name_list_a(url),
            (true, AB::B) => name_list_b(url),
            (false, AB::A) => names_a(url, &names),
            (false, AB::B) => names_b(url, &names),
        };
        output.write_all(append.as_bytes())?;
        output.write_all(b"\n")?;
    }
}
lazy_static! {
    static ref RE: Regex = Regex::new(r"\[\d*\]$").unwrap();
}

fn names_a(url: &[u8], names: &[&str]) -> String {
    let mut buff_vec = vec![String::new(); names.len()];
    for (k, v) in parse(url) {
        let k = RE.replace_all(k.as_ref(), "");
        if let Some(ix) = names.iter().position(|&x| x == k) {
            let v = v.as_ref();
            if !v.is_empty() {
                if !buff_vec[ix].is_empty() {
                    buff_vec[ix].push_str(";");
                }
                let v = &escape(v);
                buff_vec[ix].push_str(v);
            }
        }
    }
    let mut buff = String::new();
    let mut first = true;
    for s in &buff_vec {
        if first {
            first = false;
        } else {
            buff.push_str("\t");
        }
        buff.push_str(s);
    }
    return buff;
}

fn names_b(url: &[u8], names: &[&str]) -> String {
    let mut buff_vec = vec![String::new(); names.len()];
    for (k, v) in parse(url) {
        let k = RE.replace_all(k.as_ref(), "");
        if let Some(ix) = names.iter().position(|&x| x == k) {
            let v = &escape(v.as_ref());
            buff_vec[ix].push_str(v);
            buff_vec[ix].push_str(";");
        }
    }
    let mut buff = String::new();
    let mut first = true;
    for s in &buff_vec {
        if first {
            first = false;
        } else {
            buff.push_str("\t");
        }
        buff.push_str(s);
    }
    return buff;
}

fn name_list_a(url: &[u8]) -> String {
    let mut buff = String::new();
    let mut first = true;
    for (k, v) in parse(url) {
        if !v.is_empty() {
            if first {
                first = false;
            } else {
                buff.push(';');
            }
            let k = RE.replace_all(k.as_ref(), "");
            buff.push_str(k.as_ref());
        }
    }
    return buff;
}

fn name_list_b(url: &[u8]) -> String {
    let mut buff = String::new();
    for (k, _) in parse(url) {
        let k = RE.replace_all(k.as_ref(), "");
        buff.push_str(k.as_ref());
        buff.push(';');
    }
    return buff;
}

fn escape(str: &str) -> String {
    use std::fmt::Write;

    let mut buff = String::new();
    for ch in str.chars() {
        match ch {
            '\\' => buff.push_str("\\\\"),
            ';' => buff.push_str("\\x3B"),
            '\x00'..='\x1F' | '\x7F' => write!(buff, "\\x{:02X}", ch as u8).unwrap(),
            _ => buff.push(ch),
        }
    }
    return buff;
}

fn parse(url: &[u8]) -> url::form_urlencoded::Parse<'_> {
    let url = match memchr(b'?', url) {
        Some(ix) => &url[ix + 1..],
        None => url,
    };
    return url::form_urlencoded::parse(url);
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_escape() {
        assert_eq!("a\\x00b", &names_a("q=a%00b".as_bytes(), &["q"]));
        assert_eq!("a\\x1Fb", &names_a("q=a%1Fb".as_bytes(), &["q"]));
        assert_eq!("a b", &names_a("q=a%20b".as_bytes(), &["q"]));
        assert_eq!("a b", &names_a("q=a+b".as_bytes(), &["q"]));
        assert_eq!("a\\x3Bb", &names_a("q=a%3Bb".as_bytes(), &["q"]));
        assert_eq!("a\\x3Bb", &names_a("q=a;b".as_bytes(), &["q"]));
        assert_eq!("a\\\\b", &names_a("q=a%5Cb".as_bytes(), &["q"]));
        assert_eq!("a\\x7Fb", &names_a("q=a%7Fb".as_bytes(), &["q"]));
    }

    #[test]
    fn query_string_types() {
        assert_eq!("q;r", &name_list_a("q=aaa&r=xxx".as_bytes()));
        assert_eq!("q;r", &name_list_a("?q=aaa&r=xxx".as_bytes()));
        assert_eq!("q;r", &name_list_a("foo.html?q=aaa&r=xxx".as_bytes()));
        assert_eq!(
            "q;r",
            &name_list_a("http://www.example.com/foo.html?q=aaa&r=xxx".as_bytes())
        );
        assert_eq!(
            "q;r",
            &name_list_a("https://www.example.com/foo.html?q=aaa&r=xxx".as_bytes())
        );
    }

    #[test]
    fn test_names_a() {
        assert_eq!("", &names_a("r=xxx".as_bytes(), &["q"]));
        assert_eq!("", &names_a("q=&r=xxx".as_bytes(), &["q"]));
        assert_eq!("aaa", &names_a("q=aaa&r=xxx".as_bytes(), &["q"]));
        assert_eq!("aaa;bbb", &names_a("q=aaa&q=bbb&r=xxx".as_bytes(), &["q"]));
        assert_eq!("bbb", &names_a("q=&q=bbb&r=xxx".as_bytes(), &["q"]));
        assert_eq!("aaa", &names_a("q=aaa&q=&r=xxx".as_bytes(), &["q"]));
        assert_eq!("", &names_a("q=&q=&r=xxx".as_bytes(), &["q"]));
    }

    #[test]
    fn test_names_b() {
        assert_eq!("", &names_b("r=xxx".as_bytes(), &["q"]));
        assert_eq!(";", &names_b("q=&r=xxx".as_bytes(), &["q"]));
        assert_eq!("aaa;", &names_b("q=aaa&r=xxx".as_bytes(), &["q"]));
        assert_eq!("aaa;bbb;", &names_b("q=aaa&q=bbb&r=xxx".as_bytes(), &["q"]));
        assert_eq!(";bbb;", &names_b("q=&q=bbb&r=xxx".as_bytes(), &["q"]));
        assert_eq!("aaa;;", &names_b("q=aaa&q=&r=xxx".as_bytes(), &["q"]));
        assert_eq!(";;", &names_b("q=&q=&r=xxx".as_bytes(), &["q"]));
    }

    #[test]
    fn test_name_list_a() {
        assert_eq!("r", &name_list_a("r=xxx".as_bytes()));
        assert_eq!("r", &name_list_a("q=&r=xxx".as_bytes()));
        assert_eq!("q;r", &name_list_a("q=aaa&r=xxx".as_bytes()));
        assert_eq!("q;q;r", &name_list_a("q=aaa&q=bbb&r=xxx".as_bytes()));
        assert_eq!("q;r", &name_list_a("q=&q=bbb&r=xxx".as_bytes()));
        assert_eq!("q;r", &name_list_a("q=aaa&q=&r=xxx".as_bytes()));
        assert_eq!("r", &name_list_a("q=&q=&r=xxx".as_bytes()));
    }

    #[test]
    fn test_name_list_b() {
        assert_eq!("r;", &name_list_b("r=xxx".as_bytes()));
        assert_eq!("q;r;", &name_list_b("q=&r=xxx".as_bytes()));
        assert_eq!("q;r;", &name_list_b("q=aaa&r=xxx".as_bytes()));
        assert_eq!("q;q;r;", &name_list_b("q=aaa&q=bbb&r=xxx".as_bytes()));
        assert_eq!("q;q;r;", &name_list_b("q=&q=bbb&r=xxx".as_bytes()));
        assert_eq!("q;q;r;", &name_list_b("q=aaa&q=&r=xxx".as_bytes()));
        assert_eq!("q;q;r;", &name_list_b("q=&q=&r=xxx".as_bytes()));
    }

    #[test]
    fn file_test() {
        let input = include_str!("../test/data/sample-querystring.tsv");

        let exptected = include_str!("../test/expected/case-uriparams-1.tsv");
        let actual = run_uriparams(&["--col", "querystring", "--names", "q,r"], input).unwrap();
        for (exp, act) in exptected.lines().zip(actual.lines()) {
            assert_eq!(exp, act);
        }

        let exptected = include_str!("../test/expected/case-uriparams-2.tsv");
        let actual = run_uriparams(
            &["--col", "querystring", "--names", "q,r", "--multi-value-b"],
            input,
        )
        .unwrap();
        for (exp, act) in exptected.lines().zip(actual.lines()) {
            assert_eq!(exp, act);
        }

        let exptected = include_str!("../test/expected/case-uriparams-3.tsv");
        let actual = run_uriparams(&["--col", "querystring", "--name-list"], input).unwrap();
        for (exp, act) in exptected.lines().zip(actual.lines()) {
            assert_eq!(exp, act);
        }

        let exptected = include_str!("../test/expected/case-uriparams-4.tsv");
        let actual = run_uriparams(
            &["--col", "querystring", "--name-list", "--multi-value-b"],
            input,
        )
        .unwrap();
        for (exp, act) in exptected.lines().zip(actual.lines()) {
            assert_eq!(exp, act);
        }
    }

    fn run_uriparams(args: &[&str], input: &str) -> Result<String, io::Error> {
        let mut input = io::Cursor::new(input);
        let mut output = Vec::new();
        uriparams(to_string_vec(args), &mut input, &mut output)?;
        let s: String = String::from_utf8(output).unwrap();
        return Ok(s);
    }

    fn to_string_vec(args: &[&str]) -> Vec<String> {
        let mut vec: Vec<String> = Vec::new();
        for arg in args {
            vec.push(arg.to_string());
        }
        return vec;
    }
}
