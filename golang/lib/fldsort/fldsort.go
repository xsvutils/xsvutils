package fldsort

import (
	"bufio"
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"sort"
)

const (
	toolname = "xsvutils_sort"
	source   = "/Users/yusuke/repo/xsvutils/golang/lib/fldsort/in.txt"
)

func writeRow(r string, w *bufio.Writer) error {
	_, err := w.WriteString(r)
	if err != nil {
		return err
	}
	err = w.WriteByte(byte('\n'))
	if err != nil {
		return err
	}
	return nil
}

type data struct {
	hasHeader   bool
	header      *string
	srcfile     *os.File
	buf         []string
	buffiles    []*os.File
	tmpdir      string
	splitRate   int
	printRate   int
}

func newData(
	srcfile *os.File,
	hasHeader bool,
	splitRate int) *data {

	return &data{
		hasHeader:   hasHeader,
		header:      nil,
		srcfile:     srcfile,
		buf:         nil,
		buffiles:    make([]*os.File, 0),
		tmpdir:      "",
		splitRate:   splitRate,
		printRate:   10000,
	}
}

func (d data) Swap(i, j int) {
	d.buf[i], d.buf[j] = d.buf[j], d.buf[i]
}

func (d data) Less(i, j int) bool {
	return d.buf[i] < d.buf[j]
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
	for _, r := range d.buf {
		err := writeRow(r, out)
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

func (d *data) readSource() error {
	defer d.srcfile.Close()

	sc := bufio.NewScanner(d.srcfile)

	//initialize
	if d.hasHeader {
		sc.Scan()
		if err := sc.Err(); err != nil {
			return err
		}
		t := sc.Text()
		d.header = &t
	}

	//read data
	b := make([]string, d.splitRate)
	for i := 0; ; {
		if ! sc.Scan() {
			d.buf = b[:i]
			sort.Sort(d)
			break
		}
		b[i] = sc.Text()
		if i == d.splitRate-1 {
			d.buf = b
			err := d.SortToFile()
			if err != nil {
				return err
			}
			i = 0
			continue
		}
		i++
	}

	if err := sc.Err(); err != nil && err != io.EOF {
		return err
	}

	if len(d.buffiles) > 0 {
		if d.Len() > 0 {
			err := d.SortToFile()
			if err != nil {
				return err
			}
		}
	}

	return nil
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
	defer f1.Close() // TODO mergeが再帰呼び出しなので、不要なタイミングで閉じれてない。分割ファイル数が多すぎると too many open files と言われてしまう。
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

func FieldSort(
	srcfile *os.File,
	hasHeader bool,
	splitRate int) error {

	d := newData(srcfile, hasHeader, splitRate)
	err := d.readSource()
	if err != nil {
		return err
	}

	w := bufio.NewWriter(os.Stdout)
	if err != nil {
		return err
	}

	if hasHeader {
		writeRow(*d.header, w)
		w.Flush()
	}

	if len(d.buffiles) == 0 {
		for i, r := range d.buf {
			writeRow(r, w)
			if (i % d.printRate) == 0 {
				w.Flush()
			}
		}
		w.Flush()
	} else {
		file, err := d.merge()
		if err != nil {
			return err
		}
		f, err := os.Open(file.Name())
		if err != nil {
			return err
		}
		sc := bufio.NewScanner(f)
		defer file.Close()

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
	return nil
}
