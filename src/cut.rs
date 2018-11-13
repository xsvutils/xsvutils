use std::io;
use std::io::BufRead;
use std::io::BufWriter;
use std::io::Write;

use regex::Regex;

type ColIx = u16;

#[derive(Debug)]
enum LR {
    Left,
    Right,
}

#[derive(Debug, Default)]
struct CmdOpt {
    col: String,
    head: String,
    last: String,
    remove: String,
    update: Option<LR>,
}

impl CmdOpt {
    pub fn create_indexes(&self, header: &[&str]) -> Vec<ColIx> {
        let mut last_indexes = vec![];
        if self.last.len() > 0 {
            CmdOpt::append_indexes(&self.last, header, &mut last_indexes);
        }
        let mut remove_indexes = vec![];
        if self.remove.len() > 0 {
            CmdOpt::append_indexes(&self.remove, header, &mut remove_indexes);
        }

        let mut indexes = vec![];
        if self.head.len() > 0 {
            CmdOpt::append_indexes(&self.head, header, &mut indexes);
        }
        if self.col.len() > 0 {
            CmdOpt::append_indexes(&self.col, header, &mut indexes);
        } else {
            for i in 0..header.len() {
                let ix = i as ColIx;
                if !contains(&indexes, &ix) && !contains(&last_indexes, &ix) {
                    indexes.push(ix);
                }
            }
        }
        indexes.append(&mut last_indexes);
        indexes.retain(|x| !contains(&remove_indexes, x));

        match self.update {
            Some(LR::Left) => {
                let mut updated = vec![];
                indexes.into_iter().for_each(|ix| {
                    if !contains(&updated, &ix) {
                        updated.push(ix);
                    }
                });
                return updated;
            }
            Some(LR::Right) => {
                let mut updated = vec![];
                indexes.into_iter().rev().for_each(|ix| {
                    if !contains(&updated, &ix) {
                        updated.push(ix);
                    }
                });
                updated.reverse();
                return updated;
            }
            None => return indexes,
        }
    }

    fn append_indexes(col: &str, header: &[&str], indexes: &mut Vec<ColIx>) {
        let mut changed = false;
        lazy_static! {
            static ref RE: Regex = Regex::new(r"^(.+)(\d+)\.\.(.+)(\d+)$").unwrap();
        }
        col.split(",").for_each(|col| {
            if let Some(m) = RE.captures(col) {
                let s1 = m.get(1).unwrap().as_str();
                let s2 = m.get(3).unwrap().as_str();
                if s1 == s2 {
                    let n1: u32 = m.get(2).unwrap().as_str().parse().unwrap();
                    let n2: u32 = m.get(4).unwrap().as_str().parse().unwrap();
                    if n1 <= n2 {
                        for n in n1..n2 + 1 {
                            let col = format!("{}{}", s1, n);
                            changed |= CmdOpt::append_index(&col, header, indexes);
                        }
                    } else {
                        for n in (n2..n1 + 1).rev() {
                            let col = format!("{}{}", s1, n);
                            changed |= CmdOpt::append_index(&col, header, indexes);
                        }
                    }
                }
            } else {
                changed |= CmdOpt::append_index(col, header, indexes);
            }
        });
        if !changed {
            die!("Columns not specified.");
        }
    }

    fn append_index(name: &str, header: &[&str], indexes: &mut Vec<ColIx>) -> bool {
        if let Some(ix) = header.iter().position(|x| x == &name) {
            indexes.push(ix as ColIx);
            return true;
        } else {
            eprintln!("Unknown column: {}", name);
            return false;
        }
    }
}

pub fn cut(args: Vec<String>) -> Result<(), io::Error> {
    let opt = parse_opt(args);

    let mut buff = String::new();
    let stdin = io::stdin();
    let mut stdin = stdin.lock();
    let stdout = io::stdout();
    let stdout = stdout.lock();
    let mut stdout = BufWriter::new(stdout);

    let len = stdin.read_line(&mut buff)?;
    if len == 0 {
        die!(); // NoInput
    }
    let indexes = {
        let header: Vec<_> = buff.trim_end().split("\t").collect();
        let indexes = opt.create_indexes(&header);
        write_line(&header, &indexes, &mut stdout)?;
        indexes
    };
    loop {
        buff.clear();
        let len = stdin.read_line(&mut buff)?;
        if len == 0 {
            break;
        }
        let row: Vec<_> = buff.trim_end().split("\t").collect();
        write_line(&row, &indexes, &mut stdout)?;
    }
    Ok(())
}

fn parse_opt(mut args: Vec<String>) -> CmdOpt {
    let mut opt = CmdOpt::default();
    while args.len() > 0 {
        let arg = args.remove(0);
        match arg.as_str() {
            "--col" => {
                if args.len() > 0 {
                    opt.col = args.remove(0);
                } else {
                    die!("option --col needs an argument")
                }
            }
            "--head" => {
                if args.len() > 0 {
                    opt.head = args.remove(0);
                } else {
                    die!("option --head needs an argument")
                }
            }
            "--last" => {
                if args.len() > 0 {
                    opt.last = args.remove(0);
                } else {
                    die!("option --last needs an argument")
                }
            }
            "--remove" => {
                if args.len() > 0 {
                    opt.remove = args.remove(0);
                } else {
                    die!("option --remove needs an argument")
                }
            }
            "--left-update" => opt.update = Some(LR::Left),
            "--right-update" => opt.update = Some(LR::Right),
            _ => die!("Unknown argument: {}", &arg),
        }
    }
    return opt;
}

fn write_line<W: Write>(
    cells: &[&str],
    indexes: &[ColIx],
    writer: &mut W,
) -> Result<(), io::Error> {
    let mut first_line = true;
    for &ix in indexes {
        if first_line {
            first_line = false;
        } else {
            writer.write(b"\t")?;
        }
        if let Some(val) = cells.get(ix as usize) {
            writer.write(val.as_bytes())?;
        }
    }
    writer.write(b"\n")?;
    Ok(())
}

fn contains<T: PartialEq>(slice: &[T], elem: &T) -> bool {
    slice.iter().position(|x| x == elem).is_some()
}
