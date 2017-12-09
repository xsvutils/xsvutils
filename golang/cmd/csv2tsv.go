package cmd

import (
	"os"

	"../lib/csv2tsv"

	"github.com/spf13/cobra"
)

func init() {
	RootCmd.AddCommand(csv2tsvCmd)
}

var csv2tsvCmd = &cobra.Command{
	Use:   "csv2tsv",
	Short: "convert csv to tsv",
	Long:  "convert csv to tsv",
	Run: func(cmd *cobra.Command, args []string) {
		csv2tsv.Convert(os.Stdin)
	},
}
