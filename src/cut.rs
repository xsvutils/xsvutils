use crate::util;
use lazy_static::lazy_static;
use memchr::memchr;
use regex::Regex;
use std::io;
use std::io::BufRead;
use std::io::Write;

pub struct CutCommand;
impl crate::command::Command for CutCommand {
    fn execute<R: BufRead, W: Write>(
        args: Vec<String>,
        input: &mut R,
        output: &mut W,
    ) -> Result<(), io::Error> {
        cut(args, input, output)
    }
}

// ---- command line arguments -------------------------------------------------

#[derive(Debug)]
enum LR {
    Left,
    Right,
}

/// cutコマンドに渡されたコマンドライン引数を表現する構造体
#[derive(Debug, Default)]
struct CmdOpt {
    col: String,
    head: String,
    last: String,
    remove: String,
    update: Option<LR>,
}

impl CmdOpt {
    /// args をコマンドライン引数だと思って解析し、解析結果の構造体を返す
    pub fn parse(mut args: Vec<String>) -> CmdOpt {
        let mut opt = CmdOpt::default();
        while args.len() > 0 {
            let arg = args.remove(0);
            match arg.as_str() {
                "--col" => {
                    opt.col = util::pop_first_or_else(&mut args, || {
                        die!("option --col needs an argument")
                    })
                }
                "--head" => {
                    opt.head = util::pop_first_or_else(&mut args, || {
                        die!("option --head needs an argument")
                    })
                }
                "--last" => {
                    opt.last = util::pop_first_or_else(&mut args, || {
                        die!("option --last needs an argument")
                    })
                }
                "--remove" => {
                    opt.remove = util::pop_first_or_else(&mut args, || {
                        die!("option --remove needs an argument")
                    })
                }
                "--left-update" => opt.update = Some(LR::Left),
                "--right-update" => opt.update = Some(LR::Right),
                _ => die!("Unknown argument: {}", &arg),
            }
        }
        return opt;
    }

    /// コマンドライン引数と入力されたヘッダ配列から、出力対象の列のインデックス配列を返す
    pub fn create_indexes(&self, header: &[&str]) -> Vec<usize> {
        let mut lasts = CmdOpt::find_all_indexes(&self.last, header);

        let mut indexes = CmdOpt::find_all_indexes(&self.head, header);
        if self.col.len() > 0 {
            let mut center = CmdOpt::find_all_indexes(&self.col, header);
            indexes.append(&mut center);
        } else {
            for ix in 0..header.len() {
                if !util::contains(&indexes, &ix) && !util::contains(&lasts, &ix) {
                    indexes.push(ix);
                }
            }
        }
        indexes.append(&mut lasts);

        let removes = CmdOpt::find_all_indexes(&self.remove, header);
        indexes.retain(|x| !util::contains(&removes, x));

        match self.update {
            Some(LR::Left) => {
                let mut updated = vec![];
                indexes.into_iter().for_each(|ix| {
                    if !util::contains(&updated, &ix) {
                        updated.push(ix);
                    }
                });
                return updated;
            }
            Some(LR::Right) => {
                let mut updated = vec![];
                indexes.into_iter().rev().for_each(|ix| {
                    if !util::contains(&updated, &ix) {
                        updated.push(ix);
                    }
                });
                updated.reverse();
                return updated;
            }
            None => return indexes,
        }
    }

    /// ヘッダの配列からカンマ区切りで指定したヘッダのインデックスを返す。
    /// col1..col3 は col1,col2,col3 に展開される。
    fn find_all_indexes(col: &str, header: &[&str]) -> Vec<usize> {
        if col.is_empty() {
            return vec![];
        }
        let mut indexes = vec![];
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
                            CmdOpt::append_index(&col, header, &mut indexes);
                        }
                    } else {
                        for n in (n2..n1 + 1).rev() {
                            let col = format!("{}{}", s1, n);
                            CmdOpt::append_index(&col, header, &mut indexes);
                        }
                    }
                }
            } else {
                CmdOpt::append_index(col, header, &mut indexes);
            }
        });
        if indexes.is_empty() {
            die!("Columns not specified.");
        }
        return indexes;
    }

    /// `header` から `name` のインデックスを探し、見つかれば `indexes` に加える
    fn append_index(name: &str, header: &[&str], indexes: &mut Vec<usize>) {
        if let Some(ix) = header.iter().position(|x| x == &name) {
            indexes.push(ix);
        } else {
            eprintln!("Unknown column: {}", name);
        }
    }
}

// ---- main procedure ---------------------------------------------------------

/// 入力からTSVを読み取り、指定した列のみを出力する
fn cut<R: BufRead, W: Write>(
    args: Vec<String>,
    input: &mut R,
    output: &mut W,
) -> Result<(), io::Error> {
    let opt = CmdOpt::parse(args);

    // 表示する列のインデックス
    let target_col_idx = {
        let mut buff = String::new();
        let len = input.read_line(&mut buff)?;
        if len == 0 {
            die!(); // NoInput
        }
        let header: Vec<_> = buff.trim_end().split("\t").collect();
        let target_col_idx = opt.create_indexes(&header);
        let mut first = true;
        for &ix in &target_col_idx {
            if first {
                first = false;
            } else {
                output.write_all(b"\t")?;
            }
            if let Some(val) = header.get(ix) {
                output.write_all(val.as_bytes())?;
            }
        }
        output.write_all(b"\n")?;
        output.flush()?;

        target_col_idx
    };

    // 表示する列インデックスの最大値
    let max_col_idx = target_col_idx.iter().max().cloned().unwrap_or(0);
    // 行バッファのバイト列
    // Rustではバイト列を文字列に変換するとき内部でUTF-8のバリデーションを行うので、
    // バイト列そのままのほうがオーバーヘッドが減る
    let mut buff = Vec::new();
    // 各列の先頭位置
    let mut pos_vec = Vec::with_capacity(max_col_idx + 2);
    // 下のコードでタブ位置で列の開始位置を検索しているが、タブが足りないときの処理が面倒なので、
    // 常に行末の改行コードを削った上で十分なタブで埋めることで、検索コードをシンプルにしている
    let tabs = vec![b'\t'; max_col_idx + 1];
    loop {
        buff.clear();
        pos_vec.clear();
        let len = input.read_until(b'\n', &mut buff)?;
        if len == 0 {
            break;
        }
        util::trim_newline(&mut buff);
        buff.write_all(&tabs)?;
        pos_vec.push(0);

        // 最大インデックス+2 のサイズだけ計算する。それ以降は不要
        // 例えば最大 max_col_idx=2 の場合、 pos_vec[3] までアクセスするので pos_vec.len() == 4
        let mut start = 0;
        for _ in 0..max_col_idx + 1 {
            let index = start + memchr(b'\t', &buff[start..]).unwrap() + 1;
            pos_vec.push(index);
            start = index;
        }
        let mut first = true;
        for &ix in &target_col_idx {
            // pos_vec は列の開始位置が入っており、
            // buff[ pos_vec[i] .. pos_vec[i+1] ] だと文字列の最後にタブ文字を含んでしまう。
            let s = pos_vec[ix];
            let e = pos_vec[ix + 1] - 1;
            let cell = &buff[s..e];
            if first {
                first = false;
            } else {
                output.write_all(b"\t")?;
            }
            output.write_all(cell)?;
        }
        output.write_all(b"\n")?;
    }
    Ok(())
}
