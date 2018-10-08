package cmd

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"

	"github.com/suzuki-navi/xsvutils/buffer"
	"github.com/suzuki-navi/xsvutils/csv2tsv"
	"github.com/suzuki-navi/xsvutils/fldsort"
	"github.com/suzuki-navi/xsvutils/uriparams2tsv"
	"github.com/suzuki-navi/xsvutils/wcl"
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
