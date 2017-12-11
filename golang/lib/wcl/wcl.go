package wcl

import (
	"encoding/csv"
	"fmt"
	"io"
	"os"
)

func Count(rd io.Reader, hasHeader bool) {
	lineCount := 0
	errLineCount := 0
	errmsgs := make([]string, 0)

	r := csv.NewReader(rd)
	r.Comma = '\t'
	r.FieldsPerRecord = -1

	if hasHeader {
		r.Read()
	}

	for {
		_, err := r.Read()
		if err == io.EOF {
			break
		}
		if err != nil {
			errLineCount++
			errmsgs = append(errmsgs, err.Error())
		}
		lineCount++
	}

	if errLineCount == 0 {
		fmt.Println(lineCount)
		os.Exit(0)
	} else {
		fmt.Println(line)
		for _, msg := range errmsgs {
			fmt.Fprint(os.Stderr, msg)
		}
		os.Exit(1)
	}
}
