package wcl

import (
	"fmt"
	"io"
	"os"
	"github.com/spf13/cobra"
)

var hasHeader bool

func InitCmd(RootCmd *cobra.Command) {
	RootCmd.AddCommand(wclCmd)
	wclCmd.Flags().BoolVarP(&hasHeader, "header", "H", false, "default false(=noheader)")
}

var wclCmd = &cobra.Command{
	Use:   "wcl",
	Short: "count lines",
	Long:  "count lines",
	Run: func(cmd *cobra.Command, args []string) {
		Count(os.Stdin, hasHeader)
	},
}

func Count(rd io.Reader, hasHeader bool) {
	lineCount := 0

	var lastLF bool = false;
	buf := make([]byte, 4096)
	for {
		len, err := rd.Read(buf)
		if err == io.EOF {
			if !lastLF {
				lineCount++;
			}
			break
		}
		if err != nil {
			fmt.Fprintln(os.Stderr, err.Error())
			break
		}

		for i := 0; i < len; i++ {
			if buf[i] == '\n' {
				lineCount++;
				//if lineCount % 1000000 == 0 {
				//	fmt.Fprintf(os.Stderr, "Record: %d\n", lineCount);
				//}
			}
		}
		if buf[len - 1] == '\n' {
			lastLF = true;
		} else {
			lastLF = false;
		}
	}

	if hasHeader {
		lineCount--;
	}

	fmt.Println("count")
	fmt.Println(lineCount)
	os.Exit(0)
}
