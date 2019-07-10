use csv::ReaderBuilder;
use std::io;
use std::io::BufRead;
use std::io::Write;

pub fn run(input: &mut impl BufRead, output: &mut impl Write) -> Result<(), io::Error> {
    let mut rdr = ReaderBuilder::new().has_headers(false).from_reader(input);

    for result in rdr.byte_records() {
        let record = result?;
        let mut first = true;
        for s in record.iter() {
            if first {
                first = false;
            } else {
                output.write_all(b"\t")?;
            }
            let mut first = true;
            for slice in s.split(|&b| b < 0x20 || b == 0x7F) {
                if first {
                    first = false;
                } else {
                    output.write_all(b" ")?;
                }
                output.write_all(slice)?;
            }
        }
        output.write_all(b"\n")?;
    }
    Ok(())
}
