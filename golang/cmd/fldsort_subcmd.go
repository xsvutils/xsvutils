package cmd

import (
	"log"
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
		if sortQuery != "" && !hasHeader {
			log.Println("--fields and --header option should be set together")
			os.Exit(-1)
		}
		err := fldsort.FieldSort(os.Stdin, hasHeader, descSort, sortQuery, 10)
		if err != nil {
			log.Println(err)
			os.Exit(1)
		}
	},
}
