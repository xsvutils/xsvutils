package cmd

import (
	"log"
	"os"

	"github.com/spf13/cobra"

	"github.com/yomon8/xsvutils/shellcmd"
)

func init() {
	RootCmd.AddCommand(dummyshCmd)
}

var dummyshCmd = &cobra.Command{
	Use:   "dummy",
	Short: "dummy bash cmd",
	Long:  "dummy bash cmd",
	Run: func(cmd *cobra.Command, args []string) {
		err := executeShell(shellcmd.DummyCmd, []string{})
		if err != nil {
			log.Println(err)
			os.Exit(1)
		}
	},
}
