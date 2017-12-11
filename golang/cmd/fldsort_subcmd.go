package cmd

import (
	"os"

	"../lib/fldsort"

	"github.com/spf13/cobra"
)

var (
	sortQuery string
	descSort  bool
)

func init() {
	RootCmd.AddCommand(fldsortCmd)
	fldsortCmd.Flags().StringVarP(&sortQuery, "fields", "", "", "sort fields")
	fldsortCmd.Flags().BoolVarP(&descSort, "desc", "", false, "sort desc")
}

var fldsortCmd = &cobra.Command{
	Use:   "fldsort",
	Short: "sort by specific fields",
	Long:  "sort by specific fields",
	Run: func(cmd *cobra.Command, args []string) {
		ds := fldsort.Read(os.Stdin, hasHeader, descSort, sortQuery)
		ds.Sort()
		ds.Print()
	},
}
