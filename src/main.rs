#[macro_use]
extern crate lazy_static;
extern crate regex;

use std::env;

macro_rules! die {
    () => {{
        use std;
        std::process::exit(1);
    }};
    ($( $x:expr ),*) => {{
        use std;
        eprintln!($( $x ),*);
        std::process::exit(1);
    }}
}

mod cut;

fn main() {
    let mut argv = env::args();
    let _ = argv.next();
    let sub_command = argv.next();
    let rest: Vec<_> = argv.collect();

    if let Some(sub_command) = sub_command {
        match sub_command.as_str() {
            "cut" => {
                let _ = cut::cut(rest);
            }
            _ => {
                die!("unknown subcommand: {}", &sub_command);
            }
        }
    } else {
        die!("subcommand is not specified");
    }
}
