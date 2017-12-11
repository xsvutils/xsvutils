package fldsort

import (
	"encoding/csv"
	"fmt"
	"io"
	"log"
	"os"
	"sort"
	"strconv"
	"strings"
)

const (
	readBufferSize = 1000
)

type query struct {
	field string
	mode  string
}

type documents struct {
	headers   map[string]int
	records   [][]string
	orderDesc bool
	sortQuery []*query
}

func (d documents) Len() int {
	return len(d.records)
}

func (d documents) Less(i, j int) bool {
	if d.orderDesc {
		return d.fieldLess(i, j, 0)
	} else {
		return !d.fieldLess(i, j, 0)
	}
}

func (d *documents) fieldLess(i, j, fi int) bool {
	if fi == len(d.sortQuery) {
		return false
	}
	ival := d.records[i][d.headers[d.sortQuery[fi].field]]
	jval := d.records[j][d.headers[d.sortQuery[fi].field]]
	if ival == jval {
		return d.fieldLess(i, j, fi+1)
	} else {
		//number mode
		if d.sortQuery[fi].mode == "n" {
			ivalint, err := strconv.Atoi(ival)
			if err == nil {
				jvalint, err := strconv.Atoi(jval)
				if err == nil {
					return ivalint > jvalint
				}
			}
		}
		return ival < jval
	}
}

func (d *documents) setSortQuery(sortQuery string) {
	commasep := strings.Split(sortQuery, ",")
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

func (d documents) Swap(i, j int) {
	d.records[i], d.records[j] = d.records[j], d.records[i]
}

func (d *documents) Print() {
	for _, r := range d.records {
		for _, f := range r[:len(r)-1] {
			fmt.Fprintf(os.Stdout, "%s\t", f)
		}
		fmt.Fprintf(os.Stdout, "%s\n", r[len(r)-1])
	}
}

func (d *documents) Sort() {
	sort.Sort(d)
}

func Read(rd io.Reader, hasHeader bool, sortDesc bool, query string) *documents {
	ds := &documents{
		records:   make([][]string, 0),
		orderDesc: sortDesc,
	}

	r := csv.NewReader(rd)
	r.Comma = '\t'
	r.FieldsPerRecord = -1

	readHeader := hasHeader
	if hasHeader {
		record, err := r.Read()
		if err != nil {
			log.Fatal(err)
		}
		ds.headers = make(map[string]int, len(record))
		for i, hf := range record[:len(record)-1] {
			ds.headers[hf] = i
		}
		if query != "" {
			ds.setSortQuery(query)
		} else {
			ds.setSortQuery(record[0])
		}
	}

	buf := make([][]string, readBufferSize)
	for i := 0; ; {
		record, err := r.Read()
		if err == io.EOF {
			ds.records = append(ds.records, buf[:i]...)
			break
		}
		if err != nil {
			log.Fatal(err)
		}
		if readHeader == false {
			ds.headers = make(map[string]int, len(record))
			// Headerが無い場合は連番を設定する
			for i := 0; i < len(record); i++ {
				ds.headers[string(i+1)] = i
			}
			if query != "" {
				ds.setSortQuery(query)
			} else {
				ds.setSortQuery(record[0])
			}
			readHeader = true
		}
		buf[i] = record
		if i == readBufferSize-1 {
			ds.records = append(ds.records, buf...)
			buf = make([][]string, readBufferSize)
			i = 0
			continue
		}
		i++
	}
	return ds
}
