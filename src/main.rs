use std::io;
use std::io::BufWriter;

#[macro_use]
extern crate lazy_static;
extern crate memchr;
extern crate regex;

use std::env;

#[macro_use]
mod util;
mod cut;

fn main() {
    let mut argv = env::args();
    let _ = argv.next();
    let sub_command = argv.next();
    let rest: Vec<_> = argv.collect();

    if let Some(sub_command) = sub_command {
        match sub_command.as_str() {
            "cut" => {
                let stdin = io::stdin();
                let mut stdin = stdin.lock();
                let stdout = io::stdout();
                let stdout = stdout.lock();
                let mut stdout = BufWriter::new(stdout);
                let _ = cut::cut(rest, &mut stdin, &mut stdout);
            }
            _ => {
                die!("unknown subcommand: {}", &sub_command);
            }
        }
    } else {
        die!("subcommand is not specified");
    }
}
