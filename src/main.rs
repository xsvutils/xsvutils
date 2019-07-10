#[macro_use]
mod util;

use std::io;
use std::io::BufWriter;
mod addcopy;
mod command;
mod cut;
mod from_csv;
mod uriparams;

use structopt::*;

#[derive(StructOpt, Debug)]
enum Opt {
    #[structopt(name = "addcopy")]
    AddCopy(addcopy::Opt),

    #[structopt(name = "fromcsv")]
    FromCsv,

    #[structopt(name = "cut")]
    Cut(cut::Opt),

    #[structopt(name = "uriparams")]
    UriParams(uriparams::Opt),
}

fn main() {
    let opt = Opt::from_args();
    let stdin = io::stdin();
    let mut stdin = stdin.lock();
    let stdout = io::stdout();
    let stdout = stdout.lock();
    let mut stdout = BufWriter::new(stdout);

    let _ = match opt {
        Opt::AddCopy(x) => addcopy::run(x, &mut stdin, &mut stdout),
        Opt::FromCsv => from_csv::run(&mut stdin, &mut stdout),
        Opt::Cut(x) => cut::run(x, &mut stdin, &mut stdout),
        Opt::UriParams(x) => uriparams::run(x, &mut stdin, &mut stdout),
    };
}
