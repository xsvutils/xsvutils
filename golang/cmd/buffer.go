package cmd

import (
	"../lib/buffer"

	"github.com/spf13/cobra"
)

var (
	bufferSize int
	maxFileNum int
)

func init() {
	RootCmd.AddCommand(bufferCmd)
	bufferCmd.Flags().IntVarP(&bufferSize, "buffer-size", "", 100000, "Buffer Size(KB)")
	bufferCmd.Flags().IntVarP(&maxFileNum, "tmp-file-limit", "", 4096, "tmp file limit")
}

var bufferCmd = &cobra.Command{
	Use:   "buffer",
	Short: "buffer pipe",
	Long:  "buffer pipe",
	Run: func(cmd *cobra.Command, args []string) {
		buffer.Buffer(bufferSize, maxFileNum)
	},
}
