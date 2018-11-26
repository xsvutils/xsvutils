/// 標準エラーに出力し、ステータスコード255でプロセスを終了する
#[macro_export]
macro_rules! die {
    () => {{
        use std;
        std::process::exit(255);
    }};
    ($( $x:expr ),*) => {{
        eprintln!($( $x ),*);
        die!();
    }}
}

/// 配列が空でなければ先頭の要素を返し、空なら引数の関数を実行する
pub fn pop_first_or_else<T, F: FnOnce() -> T>(vec: &mut Vec<T>, f: F) -> T {
    if vec.len() > 0 {
        vec.remove(0)
    } else {
        f()
    }
}

/// 配列に指定した要素が含まれているかどうか
pub fn contains<T: PartialEq>(slice: &[T], elem: &T) -> bool {
    slice.iter().position(|x| x == elem).is_some()
}

/// バイト列の末尾から改行コードを取り除く
pub fn trim_newline(bytes: &mut Vec<u8>) {
    if bytes.len() > 0 && bytes[bytes.len() - 1] == b'\n' {
        bytes.pop();
    }
    if bytes.len() > 0 && bytes[bytes.len() - 1] == b'\r' {
        bytes.pop();
    }
}
