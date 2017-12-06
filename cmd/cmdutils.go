package cmd

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"
	"strings"

	"github.com/yomon8/xsvutils/shellcmd"
)

func executeShell(shellfile string, args []string) {
	cmd := exec.Command("/bin/bash", "-s")
	cmd.Stdin = strings.NewReader(shellcmd.DummyCmd)
	stdout, err := cmd.StdoutPipe()
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	cmd.Start()

	scanner := bufio.NewScanner(stdout)
	for scanner.Scan() {
		fmt.Println(scanner.Text())
		fmt.Println()
	}

	cmd.Wait()

}
