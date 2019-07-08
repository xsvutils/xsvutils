use csv::ReaderBuilder;
use std::io;
use std::io::BufRead;
use std::io::Write;

pub fn run(input: &mut impl BufRead, output: &mut impl Write) -> Result<(), io::Error> {
    let mut rdr = ReaderBuilder::new().has_headers(false).from_reader(input);

    for result in rdr.records() {
        let record = result?;
        let mut first = true;
        for s in &record {
            if first {
                first = false;
            } else {
                output.write_all(b"\t")?;
            }
            for &b in s.as_bytes() {
                if b < 0x20 || b == 0x7F {
                    output.write_all(b" ")?;
                } else {
                    output.write_all(&[b])?;
                }
            }
        }
        output.write_all(b"\n")?;
    }
    Ok(())
}
