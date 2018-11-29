use std::io;
use std::io::BufRead;
use std::io::Write;

pub trait Command {
    fn execute<R: BufRead, W: Write>(
        args: Vec<String>,
        input: &mut R,
        output: &mut W,
    ) -> Result<(), io::Error>;
}
