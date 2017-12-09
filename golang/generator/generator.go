// Should be called from Make
package main

import (
	"fmt"
	"io/ioutil"
	"os"
	"path"
	"strings"
	"text/template"
)

var tmpl = template.Must(template.New("").Parse(`package cmd

import (
	"log"
	"os"

	"github.com/spf13/cobra"
)

func init() {
	RootCmd.AddCommand({{.Command}}Cmd)
}


var {{.Command}}Cmd = &cobra.Command{
	Use:   "{{.Desc}}",
	Short: "{{.Desc}}",
	Long:  "{{.Desc}}",
	Run: func(cmd *cobra.Command, args []string) {
		err := executeShell({{.Body}}, []string{})
		if err != nil {
			log.Println(err)
			os.Exit(1)
		}
	},
}`))

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
		f, err := os.Create(fmt.Sprintf("%s_subcmd.go", path.Join(tgtdir, strings.ToLower(string(n)))))
		if err != nil {
			return err
		}
		defer f.Close()
		shellbody := make([]byte, len(body)+2)
		shellbody[0] = '`'
		shellbody[len(shellbody)-1] = '`'
		copy(shellbody[1:len(shellbody)-1], body)
		return tmpl.Execute(f, map[string]interface{}{
			"Command": string(n),
			"Desc":    string(n),
			"Body":    string(shellbody),
		})
	}
	return nil
}

func main() {
	err := generate("./shell", "./cmd")
	if err != nil {
		panic(err)
	}
}
