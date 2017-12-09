package cmd

import (
	"crypto/sha1"
	"fmt"
	"io/ioutil"
	"os"
)

func getShellFile(shell string) (string, error) {
	shellbytes := []byte(shell)
	tmpdir := os.Getenv("TMPDIR")
	if len(tmpdir) == 0 {
		tmpdir = "/tmp"
	}
	tmpfile := tmpdir + "/xsvutils-" + fmt.Sprintf("%x", sha1.Sum(shellbytes))
	_, err := os.Stat(tmpfile)
	if err != nil {
		err = ioutil.WriteFile(tmpfile, shellbytes, 0666)
		if err != nil {
			return "", err
		}
	}

	return tmpfile, nil
}
