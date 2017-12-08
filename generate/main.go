package main

import (
	"fmt"
	"io/ioutil"
	"os"
	"path"
	"strings"
	"text/template"
)

var tmpl = template.Must(template.New("").Parse(`package {{.Package}}
var {{.Command}} = "{{.Body}}"
`))

func generate(srcdir, tgtdir string) error {
	dirinfo, err := ioutil.ReadDir(srcdir)
	if err != nil {
		return err
	}
	for _, f := range dirinfo {
		if f.IsDir() || !strings.Contains(f.Name(), ".sh") {
			continue
		}
		body, err := ioutil.ReadFile(path.Join(srcdir, f.Name()))
		if err != nil {
			return err
		}
		n := strings.Split(f.Name(), ".")[0]
		cmdName := append([]byte(strings.ToUpper(string(n[0]))), n[1:]...)
		f, err := os.Create(fmt.Sprintf("%s.go", path.Join(tgtdir, strings.ToLower(string(cmdName)))))
		if err != nil {
			return err
		}
		defer f.Close()
		return tmpl.Execute(f, map[string]interface{}{
			"Package": "shellcmd",
			"Command": string(cmdName),
			"Body":    string(body),
		})
	}
	return nil
}

func main() {
	err := generate("./shell", "./shellcmd")
	if err != nil {
		panic(err)
	}
}
