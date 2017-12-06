package cmd

import (
	"github.com/spf13/cobra"
)

func init() {
	RootCmd.AddCommand(dummyshCmd)
}

var dummyshCmd = &cobra.Command{
	Use:   "dummy",
	Short: "dummy bash cmd",
	Long:  "dummy bash cmd",
	Run: func(cmd *cobra.Command, args []string) {
		executeShell("dummy.sh", []string{})
	},
}
