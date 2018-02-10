package cmd

import (
	"log"
	"os"

	"../lib/uriparams2tsv"

	"github.com/spf13/cobra"
)

var (
	fields     string
	defalutval string
	nullval    string
	fullUrl    bool
	multiValueB bool
)

func init() {
	RootCmd.AddCommand(uriparams2tsvCmd)
	uriparams2tsvCmd.Flags().StringVarP(&fields, "fields", "", "", "target fields")
	uriparams2tsvCmd.Flags().BoolVarP(&fullUrl, "full-url", "", false, "full url")
	uriparams2tsvCmd.Flags().BoolVarP(&multiValueB, "multi-value-b", "", false, "multi value b")
}

var uriparams2tsvCmd = &cobra.Command{
	Use:   "uriparams2tsv",
	Short: "Convert uri parameters as TSV",
	Long:  "Convert uri parameters as TSV",
	Run: func(cmd *cobra.Command, args []string) {
		err := uriparams2tsv.Convert(os.Stdin, os.Stdout, fields, fullUrl, multiValueB)
		if err != nil {
			log.Println(err)
			os.Exit(1)
		}
	},
}
