package shellcmd

import (
	"bufio"
	"crypto/sha1"
	"fmt"
	"os"
)

func GetShellFile(shell string) (string, error) {
	shellbytes := []byte(shell)
	hash := fmt.Sprintf("%x", sha1.Sum(shellbytes))
	wd, err := os.Getwd()
	if err != nil {
		return "", err
	}
	tmpfile := wd + "/" + hash
	wf, err := os.OpenFile(tmpfile, os.O_RDWR|os.O_CREATE, 0666)
	defer wf.Close()
	if err != nil {
		return "", err
	}
	wr := bufio.NewWriter(wf)
	_, err = wr.Write([]byte(shell))
	if err != nil {
		return "", err
	}
	err = wr.Flush()
	if err != nil {
		return "", err
	}

	return wf.Name(), nil
}
