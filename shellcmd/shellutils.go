package shellcmd

import (
	"crypto/sha1"
	"fmt"
	"io/ioutil"
	"os"
)

func GetShellFile(shell string) (string, error) {
	shellbytes := []byte(shell)
	tmpfile, err := ioutil.TempFile("", fmt.Sprintf("%x", sha1.Sum(shellbytes)))
	if err != nil {
		return "", err
	}
	defer tmpfile.Close()
	err = ioutil.WriteFile(tmpfile.Name(), shellbytes, os.ModePerm)
	if err != nil {
		return "", err
	}

	return tmpfile.Name(), nil
}
