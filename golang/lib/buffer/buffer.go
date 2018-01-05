package buffer

import (
	"bufio"
	"fmt"
	"io"
	"io/ioutil"
	"math"
	"os"
	"sync"
)

const (
	toolname = "xsvutils_buffer"
)

var (
	bufsize        int
	readBufferSize int
	buf            chan []byte
	bufFile        chan *os.File
	bwg            *sync.WaitGroup
	fwg            *sync.WaitGroup
)

func read() {
	rd := bufio.NewReader(os.Stdin)
	// bufsizeに達するまでメモリで処理する
	for {
		readbuf := make([]byte, readBufferSize)
		_, err := rd.Read(readbuf)
		if err == io.EOF {
			buf <- readbuf
			break
		} else if err != nil {
			panic(err)
		}
		buf <- readbuf
		if cap(buf)-len(buf) == 0 {
			break
		}
	}
	close(buf)

	// bufsize以上のデータを読み込む場合はtmpファイルに出力
	maxFileSize := bufsize
	var (
		tmpf      *os.File
		wr        *bufio.Writer
		fileCount = 0
	)
	for i := 0; ; {
		readbuf := make([]byte, readBufferSize)
		_, err := rd.Read(readbuf)
		if err == io.EOF {
			if wr != nil {
				wr.Flush()
			}
			break
		} else if err != nil {
			panic(err)
		}
		if i == 0 {
			fileCount++
			tmpf, err = ioutil.TempFile("", fmt.Sprintf("%s_%d_", toolname, fileCount))
			fmt.Println(tmpf.Name())
			if err != nil {
				panic(err)
			}
			wr = bufio.NewWriter(tmpf)
			bufFile <- tmpf
		}
		wr.Write(readbuf)
		i++
		if maxFileSize == i {
			wr.Flush()
			maxFileSize = int(math.Pow(float64(maxFileSize), 2.0))
			i = 0
		}
	}
	close(bufFile)
}

func write() {
	wr := bufio.NewWriter(os.Stdout)
	// バッファーに乗っているものを書き出し
	for {
		b, more := <-buf
		if !more {
			break
		}
		_, err := wr.Write(b)
		if err != nil {
			panic(err)
		}
		wr.Flush()
	}

	// tmpファイルに保存されたものを書き出し
	for {
		f, more := <-bufFile
		if !more {
			break
		}
		rf, err := os.Open(f.Name())
		if err != nil {
			panic(err)
		}
		defer func() {
			f.Close()
			os.Remove(f.Name())
		}()
		rd := bufio.NewReader(rf)
		readbuf := make([]byte, readBufferSize)
		for {
			_, err := rd.Read(readbuf)
			if err == io.EOF {
				wr.Write(readbuf)
				wr.Flush()
				break
			} else if err != nil {
				panic(err)
			}
			wr.Write(readbuf)
			wr.Flush()
		}
	}
	wr.Flush()
	bwg.Done()
	fwg.Done()
}

func Buffer(bufferSize int, maxFileNum int) {
	bufsize = bufferSize
	readBufferSize = 1024
	buf = make(chan []byte, bufsize)
	bufFile = make(chan *os.File, maxFileNum)
	bwg = new(sync.WaitGroup)
	fwg = new(sync.WaitGroup)
	bwg.Add(1)
	fwg.Add(1)
	go read()
	go write()
	bwg.Wait()
	fwg.Wait()
}
