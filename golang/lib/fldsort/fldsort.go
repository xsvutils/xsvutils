package fldsort

import (
	"bufio"
	"encoding/csv"
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"sort"
	"strconv"
	"strings"
)

const (
	toolname = "xsvutils_sort"
	source   = "/Users/yusuke/repo/xsvutils/golang/lib/fldsort/in.txt"
)

type row struct {
	column []string
}

func (r *row) writeRow(w *bufio.Writer) error {
	for _, c := range r.column[:len(r.column)-1] {
		_, err := w.WriteString(c)
		if err != nil {
			return err
		}
		err = w.WriteByte(byte('\t'))
		if err != nil {
			return err
		}
	}
	_, err := w.WriteString(r.column[len(r.column)-1])
	if err != nil {
		return err
	}
	err = w.WriteByte(byte('\n'))
	if err != nil {
		return err
	}
	return nil
}

type query struct {
	field string
	mode  string
}

type data struct {
	hasHeader   bool
	headers     map[string]int
	srcfile     *os.File
	buf         []*row
	buffiles    []*os.File
	tmpdir      string
	splitRate   int
	printRate   int
	orderDesc   bool
	sortQuery   []*query
	querystring string
}

func newData(
	srcfile *os.File,
	hasHeader bool,
	orderDesc bool,
	querystring string,
	splitRate int) *data {

	return &data{
		hasHeader:   hasHeader,
		headers:     nil,
		srcfile:     srcfile,
		buf:         nil,
		buffiles:    make([]*os.File, 0),
		tmpdir:      "",
		splitRate:   splitRate,
		printRate:   10000,
		orderDesc:   orderDesc,
		sortQuery:   nil,
		querystring: querystring,
	}
}

func (d data) Swap(i, j int) {
	d.buf[i], d.buf[j] = d.buf[j], d.buf[i]
}

func (d data) Less(i, j int) bool {
	if d.orderDesc {
		return !d.fieldLess(i, j, 0)
	} else {
		return d.fieldLess(i, j, 0)
	}
}

func (d data) Len() int {
	return len(d.buf)
}

func (d *data) fieldLess(i, j, fi int) bool {
	if fi == len(d.sortQuery) {
		return false
	}
	ival := d.buf[i].column[d.headers[d.sortQuery[fi].field]]
	jval := d.buf[j].column[d.headers[d.sortQuery[fi].field]]
	if ival == jval {
		return d.fieldLess(i, j, fi+1)
	} else {
		//numeric mode
		if d.sortQuery[fi].mode == "n" {
			ivalint, err := strconv.Atoi(ival)
			if err == nil {
				jvalint, err := strconv.Atoi(jval)
				if err == nil {
					return ivalint < jvalint
				}
			}
		}
		return ival < jval
	}
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
		err := r.writeRow(out)
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

func (d *data) setSortQuery() {
	commasep := strings.Split(d.querystring, ",")
	sq := make([]*query, len(commasep))
	for i, csq := range commasep {
		colonsep := strings.Split(csq, ":")
		if len(colonsep) == 2 && colonsep[1] == "n" {
			sq[i] = &query{
				field: colonsep[0],
				mode:  colonsep[1],
			}
		} else {
			sq[i] = &query{
				field: csq,
				mode:  "",
			}
		}
	}
	d.sortQuery = sq
}

func (d *data) readSource() error {
	defer d.srcfile.Close()

	r := csv.NewReader(d.srcfile)
	r.Comma = '\t'
	r.FieldsPerRecord = -1

	//initialize
	if d.hasHeader {
		record, err := r.Read()
		if err != nil {
			return err
		}
		d.headers = make(map[string]int, len(record))
		for i, hf := range record {
			d.headers[hf] = i
		}
		if d.querystring == "" {
			d.querystring = record[0]
		}
		d.setSortQuery()
	}

	//read data
	b := make([]*row, d.splitRate)
	for i := 0; ; {
		r, err := r.Read()
		if err == io.EOF {
			d.buf = b[:i]
			sort.Sort(d)
			break
		}
		if err != nil {
			return err
		}
		b[i] = &row{
			column: r,
		}
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

func FieldSort(
	srcfile *os.File,
	hasHeader bool,
	orderDesc bool,
	querystring string,
	splitRate int) error {

	d := newData(srcfile, hasHeader, orderDesc, querystring, splitRate)
	err := d.readSource()
	if err != nil {
		return err
	}

	w := bufio.NewWriter(os.Stdout)
	if err != nil {
		return err
	}

	if hasHeader {
		i := 0
		hlen := len(d.headers)
		for k, _ := range d.headers {
			i++
			w.WriteString(k)
			if i == hlen {
				w.WriteByte(byte('\n'))
				break
			}
			w.WriteByte(byte('\t'))
		}
		w.Flush()
	}

	if len(d.buffiles) == 0 {
		for i, r := range d.buf {
			r.writeRow(w)
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
