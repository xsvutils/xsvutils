use std::io;
use std::io::BufRead;
use std::io::Write;
use crate::util;

pub struct AddCopyCommand;
impl crate::command::Command for AddCopyCommand {
    fn execute<R: BufRead, W: Write>(
        args: Vec<String>,
        input: &mut R,
        output: &mut W,
    ) -> Result<(), io::Error> {
        add_copy(args, input, output)
    }
}

// ---- command line arguments -------------------------------------------------


/// コマンドに渡されたコマンドライン引数を表現する構造体
#[derive(Debug, Default)]
struct CmdOpt {
    name: String,
    src: String,
}

impl CmdOpt {
    /// args をコマンドライン引数だと思って解析し、解析結果の構造体を返す
    pub fn parse(mut args: Vec<String>) -> CmdOpt {
        let mut opt = CmdOpt::default();
        while args.len() > 0 {
            let arg = args.remove(0);
            match arg.as_str() {
                "--name" => {
                    opt.name = util::pop_first_or_else(&mut args, || {
                        die!("option --name needs an argument")
                    })
                }
                "--src" => {
                    opt.src = util::pop_first_or_else(&mut args, || {
                        die!("option --src needs an argument")
                    })
                }
                _ => die!("Unknown argument: {}", &arg),
            }
        }
        return opt;
    }
}

// ---- main procedure ---------------------------------------------------------

fn add_copy<R: BufRead, W: Write>(
    args: Vec<String>,
    input: &mut R,
    output: &mut W,
) -> Result<(), io::Error> {
    let opt = CmdOpt::parse(args);

    let mut buff = String::new();
    let index: usize = {
        let len = input.read_line(&mut buff)?;
        if len == 0 {
            die!(); // NoInput
        }
        let buff = buff.trim_end_matches(|c: char| c == '\n');
        let index = match buff.split("\t").position(|x: &str| x == &opt.src) {
            Some(x) => x,
            None => die!("Column not found: {}", &opt.src)
        };
        output.write_all(opt.name.as_bytes())?;
        output.write_all(b"\t")?;
        output.write_all(buff.as_bytes())?;
        output.write_all(b"\n")?;
        index
    };
    loop {
        buff.clear();
        let len = input.read_line(&mut buff)?;
        if len == 0 {
            break;
        }
        let buff = buff.trim_end_matches(|c: char| c == '\n');
        let lead = buff.split("\t").nth(index).unwrap_or(Default::default());
        output.write_all(lead.as_bytes())?;
        output.write_all(b"\t")?;
        output.write_all(buff.as_bytes())?;
        output.write_all(b"\n")?;
    }
    Ok(())
}
