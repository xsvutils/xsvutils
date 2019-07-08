use std::io;
use std::io::BufRead;
use std::io::Write;
use structopt::*;

#[derive(StructOpt, Debug)]
pub struct Opt {
    #[structopt(long)]
    name: String,
    #[structopt(long)]
    src: String,
}

// ---- main procedure ---------------------------------------------------------

pub fn run(opt: Opt, input: &mut impl BufRead, output: &mut impl Write) -> Result<(), io::Error> {
    let mut buff = String::new();
    let index: usize = {
        let len = input.read_line(&mut buff)?;
        if len == 0 {
            die!(); // NoInput
        }
        let buff = buff.trim_end_matches(|c: char| c == '\n');
        let index = match buff.split("\t").position(|x: &str| x == &opt.src) {
            Some(x) => x,
            None => die!("Column not found: {}", &opt.src),
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
