package cmd

import (
	"bufio"
	"fmt"
	"os/exec"
)

func executeShell(shelltext string, args []string) error {
	shellfile, err := getShellFile(shelltext)
	if err != nil {
		return err
	}
	args = append([]string{shellfile}, args...)
	cmd := exec.Command(fmt.Sprint(
		"/bin/bash"), args...)
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
	}

	cmd.Wait()
	return nil
}
