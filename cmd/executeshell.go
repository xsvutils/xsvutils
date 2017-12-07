package cmd

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"

	"github.com/yomon8/xsvutils/shellcmd"
)

func executeShell(shelltext string, args []string) error {
	shellfile, err := shellcmd.GetShellFile(shelltext)
	if err != nil {
		return err
	}
	wd, err := os.Getwd()
	if err != nil {
		return err
	}
	fmt.Println(wd)
	cmd := exec.Command(fmt.Sprint(
		"/bin/bash",
		" ",
		shellfile,
		" "),
		args...)
	stdout, err := cmd.StdoutPipe()
	if err != nil {
		fmt.Println(err)
		return err
	}

	err = cmd.Start()
	if err != nil {
		fmt.Println(err)
		return err
	}

	scanner := bufio.NewScanner(stdout)
	for scanner.Scan() {
		fmt.Println(scanner.Text())
		fmt.Println()
	}

	cmd.Wait()
	return nil
}
