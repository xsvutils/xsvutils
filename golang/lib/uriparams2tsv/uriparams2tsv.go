package uriparams2tsv

import (
	"bufio"
	"os"
	"strings"
)

func printHeaderNamesAsTsv(wr *bufio.Writer) {
	_, err := wr.WriteString("names\n")
	if err != nil {
		os.Exit(0); // 出力先がなくなった場合はそのまま終了する
	}
}

func printHeaderAsTsv(wr *bufio.Writer, header map[string]int) {
	headerLength := len(header)
	for i := 0; i < headerLength; i++ {
		if i > 0 {
			err := wr.WriteByte(byte('\t'))
			if err != nil {
				os.Exit(0); // 出力先がなくなった場合はそのまま終了する
			}
		}
		for k, v := range header {
			if v != i {
				continue
			}
			_, err := wr.WriteString(k)
			if err != nil {
				os.Exit(0); // 出力先がなくなった場合はそのまま終了する
			}
			break
		}
	}
	err := wr.WriteByte(byte('\n'))
	if err != nil {
		os.Exit(0); // 出力先がなくなった場合はそのまま終了する
	}
}

func printLineAsTsv(wr *bufio.Writer, line []string) {
	lineLength := len(line)
	for i, l := range line {
		_, err := wr.WriteString(l)
		if err != nil {
			os.Exit(0); // 出力先がなくなった場合はそのまま終了する
		}
		if i == lineLength - 1 {
			break
		}
		err = wr.WriteByte(byte('\t'))
		if err != nil {
			os.Exit(0); // 出力先がなくなった場合はそのまま終了する
		}
	}
	err := wr.WriteByte(byte('\n'))
	if err != nil {
		os.Exit(0); // 出力先がなくなった場合はそのまま終了する
	}
}

func Convert(in *os.File, out *os.File, query string, namesAction bool, multiValueB bool) error {
	wr := bufio.NewWriter(out)
	keys := strings.Split(query, ",")
	header := make(map[string]int, len(keys))
	if namesAction {
		printHeaderNamesAsTsv(wr)
	} else {
		for i, k := range keys {
			header[k] = i
		}
		printHeaderAsTsv(wr, header)
	}
	err := wr.Flush()
	if err != nil {
		os.Exit(0); // 出力先がなくなった場合はそのまま終了する
	}

	sc := bufio.NewScanner(in)
	for i := 0; sc.Scan(); i++ {
		line := make([]string, len(keys))

		var querystring = sc.Text()
		if strings.HasPrefix(querystring, "http://") {
			var querystring2 = querystring[7:]
			p1 := strings.Index(querystring2, "/")
			if p1 >= 0 {
				querystring2 = querystring2[p1 + 1:]
				p2 := strings.Index(querystring2, "?")
				if p2 >= 0 {
					querystring = querystring2[p2 + 1:]
				} else {
					querystring = "";
				}
			}
		} else if strings.HasPrefix(querystring, "https://") {
			var querystring2 = querystring[7:]
			p1 := strings.Index(querystring2, "/")
			if p1 >= 0 {
				querystring2 = querystring2[p1 + 1:]
				p2 := strings.Index(querystring2, "?")
				if p2 >= 0 {
					querystring = querystring2[p2 + 1:]
				} else {
					querystring = "";
				}
			}
		} else {
			p2 := strings.Index(querystring, "?")
			if p2 >= 0 {
				querystring = querystring[p2 + 1:]
			}
		}

		params := strings.Split(querystring, "&")
		for _, p := range params {
			kv := strings.SplitN(p, "=", 2)
			name := kv[0]
			if strings.HasSuffix(name, "[]") {
				name = name[:len(name)-2]
			}

			if namesAction {
				if multiValueB {
					line[0] += name + ";";
				} else {
					if len(name) > 0 && len(kv) == 2 && len(kv[1]) > 0 {
						if len(line[0]) == 0 {
							line[0] = name
						} else {
							line[0] += ";" + name
						}
					}
				}
				continue
			}

			index, ok := header[name]
			if !ok {
				continue
			}
			var value string
			if len(kv) == 2 {
				value = kv[1]
			} else {
				value = ""
			}
			if multiValueB {
				line[index] += value + ";";
			} else {
				if len(value) > 0 {
					if len(line[index]) == 0 {
						line[index] = value
					} else {
						line[index] += ";" + value
					}
				}
			}
		}

		if i % 1000 == 0 {
			wr.Flush()
		}
		printLineAsTsv(wr, line)
	}
	err = wr.Flush()
	if err != nil {
		return err
	}
	return nil
}
