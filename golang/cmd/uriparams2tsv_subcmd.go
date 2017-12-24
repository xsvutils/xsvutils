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
)

func init() {
	RootCmd.AddCommand(uriparams2tsvCmd)
	uriparams2tsvCmd.Flags().StringVarP(&fields, "fields", "", "", "target fields")
	uriparams2tsvCmd.Flags().StringVarP(&defalutval, "default-string", "", "Exists", "default value")
	uriparams2tsvCmd.Flags().StringVarP(&nullval, "null-string", "", "Null", "null string")
}

var uriparams2tsvCmd = &cobra.Command{
	Use:   "uriparams2tsv",
	Short: "Convert uri parameters as TSV",
	Long:  "Convert uri parameters as TSV",
	Run: func(cmd *cobra.Command, args []string) {
		err := uriparams2tsv.Convert(os.Stdin, os.Stdout, fields, defalutval, nullval)
		if err != nil {
			log.Println(err)
			os.Exit(1)
		}
	},
}
