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
	if err != nil { // if not exists tmpfile
		tmpfile2 := tmpfile + ".tmp"
		err = ioutil.WriteFile(tmpfile2, shellbytes, 0666)
		if err != nil {
			return "", err
		}
		err = os.Rename(tmpfile2, tmpfile)
		if err != nil {
			return "", err
		}
	}

	return tmpfile, nil
}
