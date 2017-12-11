package cmd

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
)

var isCsvInput bool
var hasHeader bool

var RootCmd = &cobra.Command{
	Use:   "xsvutils",
	Short: "xsvutils",
	Long:  "xsvutils",
}

func Execute() {
	if err := RootCmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}

func init() {
	RootCmd.PersistentFlags().BoolVarP(&isCsvInput, "incsv", "c", false, "default false(=tsv)")
	RootCmd.PersistentFlags().BoolVarP(&hasHeader, "header", "H", false, "default false(=noheader)")
}
