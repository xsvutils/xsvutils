package csv2tsv

import (
	"encoding/csv"
	"fmt"
	"io"
	"log"
)

func Convert(rd io.Reader) {
	r := csv.NewReader(rd)
	r.FieldsPerRecord = -1
	for {
		record, err := r.Read()
		if err == io.EOF {
			break
		}
		if err != nil {
			log.Fatal(err)
		}
		for _, field := range record[:len(record)-1] {
			fmt.Print(replace(field), "\t")
		}
		fmt.Print(replace(record[len(record)-1]), "\n")
	}
}

func replace(src string) string {
	s := make([]byte, len(src))
	for i, b := range []byte(src) {
		if 0x00 <= b && b < 0x20 || b == 0x7F {
			s[i] = byte(' ')
		} else {
			s[i] = b
		}
	}
	return string(s)
}
