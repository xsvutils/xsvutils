package main

import (
	"bufio"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"sort"
)

const (
	toolname = "xsvutils_sort"
	source   = "/Users/yusuke/repo/xsvutils/golang/lib/fldsort/in.txt"
)

type data struct {
	srcfile   string
	buf       []string
	buffiles  []*os.File
	tmpdir    string
	writeRate int
	printRate int
}

func NewData(srcfile string, writeRate int) *data {
	return &data{
		srcfile:   srcfile,
		buf:       nil,
		buffiles:  make([]*os.File, 0),
		tmpdir:    "",
		writeRate: writeRate,
		printRate: 10000,
	}
}

func (d data) Swap(i, j int) {
	d.buf[i], d.buf[j] = d.buf[j], d.buf[i]
}

func (d data) Less(i, j int) bool {
	return d.buf[j] > d.buf[i]
}

func (d data) Len() int {
	return len(d.buf)
}

func (d *data) SortToFile() error {
	tmpf, err := ioutil.TempFile(d.tmpdir, fmt.Sprintf("%s_", toolname))
	if err != nil {
		return err
	}
	defer tmpf.Close()
	out := bufio.NewWriter(tmpf)
	//sort buffer
	sort.Sort(d)
	for _, s := range d.buf {
		if s == "" {
			break
		}
		_, err := out.WriteString(s)
		if err != nil {
			return err
		}
		err = out.WriteByte(byte('\n'))
		if err != nil {
			return err
		}
	}
	err = out.Flush()
	if err != nil {
		return err
	}
	d.buffiles = append(d.buffiles, tmpf)
	d.buf = nil
	return nil
}

func (d *data) preSort() (error, bool) {
	needAdditinalSort := false
	src, err := os.Open(d.srcfile)
	if err != nil {
		return err, needAdditinalSort
	}
	defer src.Close()

	sc := bufio.NewScanner(src)
	b := make([]string, d.writeRate)
	for i := 0; ; {
		more := sc.Scan()
		if !more {
			d.buf = b[:i]
			if len(d.buf) != 0 {
				err = d.SortToFile()
				if err != nil {
					return err, needAdditinalSort
				}
			}
			break
		}
		b[i] = sc.Text()
		if i == d.writeRate-1 {
			needAdditinalSort = true
			d.buf = b
			err := d.SortToFile()
			if err != nil {
				return err, needAdditinalSort
			}
			i = 0
			continue
		}
		i++
	}
	return nil, needAdditinalSort
}

func (d *data) merge() (*os.File, error) {
	if len(d.buffiles) == 1 {
		return d.buffiles[0], nil
	}
	tmpf, err := ioutil.TempFile(d.tmpdir, fmt.Sprintf("%s_m%d_", toolname, len(d.buffiles)))
	if err != nil {
		return nil, err
	}
	out := bufio.NewWriter(tmpf)
	f1, err := os.Open(d.buffiles[0].Name())
	if err != nil {
		return nil, err
	}
	f2, err := os.Open(d.buffiles[1].Name())
	if err != nil {
		return nil, err
	}
	defer f1.Close()
	defer f2.Close()
	sc1 := bufio.NewScanner(f1)
	sc2 := bufio.NewScanner(f2)

	var next1, next2 bool
	var t1, t2 string
	next1 = sc1.Scan()
	next2 = sc2.Scan()
	for i := 0; ; i++ {
		if !next1 && !next2 {
			out.Flush()
			break
		} else if !next1 && next2 {
			out.WriteString(t2)
			out.WriteByte(byte('\n'))
			for sc2.Scan() {
				out.WriteString(sc2.Text())
				out.WriteByte(byte('\n'))
			}
			next2 = false
			continue
		} else if next1 && !next2 {
			out.WriteString(t1)
			out.WriteByte(byte('\n'))
			for sc1.Scan() {
				out.WriteString(sc1.Text())
				out.WriteByte(byte('\n'))
			}
			next1 = false
			continue
		}

		t1 = sc1.Text()
		t2 = sc2.Text()
		if t1 <= t2 {
			out.WriteString(t1)
			next1 = sc1.Scan()
		} else {
			out.WriteString(t2)
			next2 = sc2.Scan()
		}
		out.WriteByte(byte('\n'))
		if (i % d.printRate) == 0 {
			out.Flush()
		}
	}

	d.buffiles = append(d.buffiles[2:], tmpf)
	return d.merge()
}

func main() {
	d := NewData(source, 100000)
	err, needAdditinalSort := d.preSort()
	if err != nil {
		log.Println(err.Error())
		os.Exit(1)
	}
	if needAdditinalSort {
		file, err := d.merge()
		if err != nil {
			log.Println(err.Error())
			os.Exit(1)
		}
		f, err := os.Open(file.Name())
		if err != nil {
			log.Println(err.Error())
			os.Exit(1)
		}
		sc := bufio.NewScanner(f)
		defer file.Close()
		w := bufio.NewWriter(os.Stdout)
		if err != nil {
			log.Println(err.Error())
			os.Exit(1)
		}

		i := 0
		for sc.Scan() {
			w.WriteString(sc.Text())
			w.WriteByte(byte('\n'))
			if (i % d.printRate) == 0 {
				w.Flush()
			}
			i++
		}
		w.Flush()
	}
}
