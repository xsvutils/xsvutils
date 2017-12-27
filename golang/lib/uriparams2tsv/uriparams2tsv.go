package uriparams2tsv

import (
	"bufio"
	"os"
	"strings"
)

func printHeaderAsTsv(wr *bufio.Writer, header map[string]int) error {
	headerLength := len(header)
	for i := 1; i <= headerLength; i++ {
		for k, v := range header {
			if v != i {
				continue
			}
			_, err := wr.WriteString(k)
			if err != nil {
				return err
			}
			err = wr.WriteByte(byte('\t'))
			if err != nil {
				return err
			}
		}
	}
	err := wr.WriteByte(byte('\n'))
	if err != nil {
		return err
	}
	return nil
}

func printLineAsTsv(wr *bufio.Writer, line []string, nullText string) error {
	lineLength := len(line)
	for i, l := range line {
		if l == "" {
			wr.WriteString(nullText)
		} else {
			wr.WriteString(l)
		}
		if i == lineLength-1 {
			break
		}
		err := wr.WriteByte(byte('\t'))
		if err != nil {
			return err
		}
	}
	err := wr.WriteByte(byte('\n'))
	if err != nil {
		return err
	}

	return nil
}

func Convert(in *os.File, out *os.File, query string, defalutValue string, nullValue string, fullUrl bool) error {
	wr := bufio.NewWriter(out)
	keys := strings.Split(query, ",")
	header := make(map[string]int, len(keys))
	for i, k := range keys {
		header[k] = i
	}
	printHeaderAsTsv(wr, header)
	err := wr.Flush()
	if err != nil {
		return err
	}

	sc := bufio.NewScanner(in)
	for i := 0; sc.Scan(); i++ {
		line := make([]string, len(keys))

		var querystring = ""
		if fullUrl {
			line2 := strings.SplitN(sc.Text(), "?", 2);
			if len(line2) == 2 {
				querystring = line2[1];
			}
		} else {
			querystring = sc.Text()
		}
		params := strings.Split(querystring, "&")
		for _, p := range params {
			kv := strings.SplitN(p, "=", 2)
			index, ok := header[kv[0]]
			if !ok {
				continue
			}
			if len(kv) == 2 {
				line[index] = kv[1]
			} else {
				line[index] = defalutValue
			}
		}

		if i % 100000 == 0 {
			wr.Flush()
		}
		err = printLineAsTsv(wr, line, nullValue)
		if err != nil {
			return err
		}
	}
	err = wr.Flush()
	if err != nil {
		return err
	}
	return nil
}
