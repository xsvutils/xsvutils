package cmd

import (
	"os"

	"../lib/wcl"

	"github.com/spf13/cobra"
)

func init() {
	RootCmd.AddCommand(wclCmd)
}

var wclCmd = &cobra.Command{
	Use:   "wcl",
	Short: "count lines",
	Long:  "count lines",
	Run: func(cmd *cobra.Command, args []string) {
		wcl.Count(os.Stdin, hasHeader)
	},
}
