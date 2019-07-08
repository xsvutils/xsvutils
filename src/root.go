package cmd

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"

	"github.com/xsvutils/xsvutils/buffer"
	"github.com/xsvutils/xsvutils/fldsort"
	"github.com/xsvutils/xsvutils/uriparams2tsv"
	"github.com/xsvutils/xsvutils/wcl"
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
	fldsort.InitCmd(RootCmd)
	uriparams2tsv.InitCmd(RootCmd)
	wcl.InitCmd(RootCmd)
}
