package cmd

import (
	"../lib/buffer"

	"github.com/spf13/cobra"
)

var (
	debug bool
)

func init() {
	RootCmd.AddCommand(bufferCmd)
	bufferCmd.Flags().BoolVarP(&debug, "debug", "", false, "debug mode")
}

var bufferCmd = &cobra.Command{
	Use:   "buffer",
	Short: "buffer pipe",
	Long:  "buffer pipe",
	Run: func(cmd *cobra.Command, args []string) {
		buffer.Buffer(args, debug)
	},
}
