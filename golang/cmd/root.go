package cmd

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"

	"../buffer"
	"../csv2tsv"
	"../fldsort"
	"../uriparams2tsv"
	"../wcl"
)

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
	buffer.InitCmd(RootCmd)
	csv2tsv.InitCmd(RootCmd)
	fldsort.InitCmd(RootCmd)
	uriparams2tsv.InitCmd(RootCmd)
	wcl.InitCmd(RootCmd)
}
