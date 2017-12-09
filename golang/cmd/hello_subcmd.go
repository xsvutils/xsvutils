package cmd

import (
	"log"
	"os"

	"github.com/spf13/cobra"
)

func init() {
	RootCmd.AddCommand(helloCmd)
}


var helloCmd = &cobra.Command{
	Use:   "hello",
	Short: "hello",
	Long:  "hello",
	Run: func(cmd *cobra.Command, args []string) {
		err := executeShell(`#!/bin/bash
echo Hello
`, []string{})
		if err != nil {
			log.Println(err)
			os.Exit(1)
		}
	},
}