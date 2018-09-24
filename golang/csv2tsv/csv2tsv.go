package csv2tsv

import (
	"encoding/csv"
	"fmt"
	"io"
	"log"
	"os"
	"github.com/spf13/cobra"
)

func InitCmd(RootCmd *cobra.Command) {
	RootCmd.AddCommand(csv2tsvCmd)
}

var csv2tsvCmd = &cobra.Command{
	Use:   "csv2tsv",
	Short: "convert csv to tsv",
	Long:  "convert csv to tsv",
	Run: func(cmd *cobra.Command, args []string) {
		Convert(os.Stdin)
	},
}

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
