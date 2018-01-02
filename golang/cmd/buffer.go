package cmd

import (
	"../lib/buffer"

	"github.com/spf13/cobra"
)

func init() {
	RootCmd.AddCommand(bufferCmd)
}

var bufferCmd = &cobra.Command{
	Use:   "buffer",
	Short: "buffer pipe",
	Long:  "buffer pipe",
	Run: func(cmd *cobra.Command, args []string) {
		buffer.Buffer()
	},
}
