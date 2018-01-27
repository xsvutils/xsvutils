package buffer

import (
	"bufio"
	"fmt"
	"io"
	"io/ioutil"
	"strings"
	"os"
)

const (
	toolname = "xsvutils_buffer"
	readSize = 1024
	bufferChannelSize = 1024 * 1024
	bufferDataMinimumCount = 512 * 1024
	//bufferFileContentMaxSize = 1024
)

type output struct {
	path string
	file *os.File
	outputPipe chan []byte
	bufferFilePos int
	finishedFlag bool
}

type outputMessage struct {
	index int
	message int
}

const (
	stepOutputMessage = 1
	closeOutputMessage = 2
)

var (
	debug = true
	bufferFileDirPath string
	outputs []*output
	fastestOutputIndex int = -1
	inputCountNeeded int = bufferDataMinimumCount
	inputClosed bool = false
	closedOutputCount int = 0
)

/*
func openBufferFileReader(counter int) *os.File {
	path := fmt.Sprintf("%s/%d", bufferFileDirPath, counter)
	file, err := os.Open(path)
	if err != nil {
		panic(err)
	}
	return file
}

func openBufferFileWriter(counter int) *os.File {
	path := bufferFileDirPath + "/" + string(counter)
	file, err := os.OpenFile(path, os.O_WRONLY|os.O_CREATE, 0700)
	if err != nil {
		panic(err)
	}
	return file
}
*/

func readFromFile(inputPipe chan<- []byte, file *os.File) {
	rd := bufio.NewReader(file)
	for {
		readbuf, isEOF := readFromReader(rd, file)
		if debug {
			fmt.Fprintf(os.Stderr, "readFromFile %s %d %v\n", file.Name(), len(readbuf), isEOF)
		}
		if isEOF {
			break
		}

		inputPipe <- readbuf
	}

	close(inputPipe)
}

func readFromReader(rd *bufio.Reader, file *os.File) (readbuf []byte, isEOF bool) {
	readbuf = make([]byte, readSize)
	l, err := rd.Read(readbuf)
	readbuf = readbuf[:l]
	if err == io.EOF {
		return readbuf, true
	} else if err != nil {
		panic(err)
	}
	return readbuf, false
}

func writeToFile(outputPipe <-chan []byte, file *os.File, outputIndex int, messageCh chan<- outputMessage) {
	defer func() {
		messageCh <- outputMessage { outputIndex, closeOutputMessage }
	}()

	wr := bufio.NewWriter(file)

	for {
		if debug {
			fmt.Fprintf(os.Stderr, "writeToFile outputIndex:%d DEBUG 1\n", outputIndex)
		}
		readbuf, more := <- outputPipe
		if !more {
			break
		}
		messageCh <- outputMessage { outputIndex, stepOutputMessage }
		if debug {
			fmt.Fprintf(os.Stderr, "writeToFile outputIndex:%d len:%d\n", outputIndex, len(readbuf))
		}
		if writeToWriter(readbuf, wr, true) {
			if debug {
				fmt.Fprintf(os.Stderr, "writeToFile outputIndex:%d return\n", outputIndex)
			}
			return // 出力先がなくなった場合はそのまま終了する
		}
	}

	err := wr.Flush()
	if err != nil {
		if strings.Index(err.Error(), "broken pipe") >= 0 {
			return // 出力先がなくなった場合はそのまま終了する
		}
		panic(err)
	}

	// TODO close
}

func writeToWriter(readbuf []byte, wr *bufio.Writer, handleBrokenPipe bool) bool {
	for {
		if debug {
			fmt.Fprintf(os.Stderr, "writeToWriter 1\n")
		}
		l2, err := wr.Write(readbuf)
		if debug {
			fmt.Fprintf(os.Stderr, "writeToWriter 2 %d\n", l2)
		}
		if err != nil {
			if handleBrokenPipe && strings.Index(err.Error(), "broken pipe") >= 0 {
				return true // 出力先がなくなった場合はそのまま終了する
			}
			panic(err)
		}
		if l2 == len(readbuf) {
			break
		}
		readbuf = readbuf[l2:]
	}
	return false
}

// 1回出力ごとに呼び出されるハンドラ
func onOutputStep(index int) {
	if debug {
		fmt.Fprintf(os.Stderr, "onOutputStep index:%d\n", index)
	}

	// fastestOutputIndex, inputCountNeeded を更新
	if outputs[index].bufferFilePos >= 0 {
		// no operation
	} else if fastestOutputIndex < 0 {
		c := len(outputs[index].outputPipe)
		if c < bufferDataMinimumCount {
			fastestOutputIndex = index
			inputCountNeeded = bufferDataMinimumCount - c
		}
	} else if index == fastestOutputIndex {
		inputCountNeeded++
	} else {
		c := len(outputs[index].outputPipe)
		if len(outputs[fastestOutputIndex].outputPipe) > c {
			fastestOutputIndex = index
			inputCountNeeded = bufferDataMinimumCount - c
		}
	}
}

// 出力goroutine終了のハンドラ
func onOutputFinished(index int) bool {
	if debug {
		fmt.Fprintf(os.Stderr, "onOutputFinish index:%d\n", index)
	}
	outputs[index].finishedFlag = true
	closedOutputCount++
	if index == fastestOutputIndex {
		fastestOutputIndex = -1
		inputCountNeeded = 1
	}
	if closedOutputCount == len(outputs) {
		return true
	} else {
		return false
	}
}


//	// バッファファイルへの入力側ファイルの切り替え
//	nextInputBufferFile := func() {
//		if debug {
//			fmt.Fprintf(os.Stderr, "nextInputBufferFile %d->%d\n", bufferFileCounter, bufferFileCounter + 1)
//		}
//		if bufferFileCounter > 0 {
//			err := bufferFileWriter.Flush()
//			if err != nil {
//				panic(err)
//			}
//			bufferFileHandle.Close()
//		}
//		bufferFileCounter++
//		bufferFileHandle = openBufferFileWriter(bufferFileCounter)
//		bufferFileWriter = bufio.NewWriter(bufferFileHandle)
//		bufferFileContentSize = 0
//	}
//
//	startOutputBufferFile := func(index int) {
//		nextInputBufferFile()
//		if debug {
//			fmt.Fprintf(os.Stderr, "startOutputBufferFile outputIndex: %d\n", index)
//		}
//		output := outputs[index]
//		output.bufferFileFlag = true
//		output.bufferFileCounter = bufferFileCounter
//		output.bufferFileHandle = nil
//	}
//
//	endOutputBufferFile := func(index int) {
//		nextInputBufferFile()
//		if debug {
//			fmt.Fprintf(os.Stderr, "endOutputBufferFile outputIndex: %d\n", index)
//		}
//		output := outputs[index]
//		for {
//			output.bufferFileHandle
//		}
//		// TODO
//	}

//func bufferFileToOutputPipe(index int) {
//	output := outputs[index]
//	if output.bufferFileCounter == bufferFileCounter {
//		
//		// TODO
//	}

//	if output.bufferFileReader != nil {
//		//readbuf, isEOF := readFromReader(output.bufferFileReader, output.bufferFileHandle)
//		_, isEOF := readFromReader(output.bufferFileReader, output.bufferFileHandle)
//		if isEOF {
//			err := output.bufferFileHandle.Close
//			if err != nil {
//				panic(err)
//			}
//			output.bufferFileCounter++
//			output.bufferFileHandle = nil
//			output.bufferFileReader = nil
//			bufferFileToOutputPipe(index)
//			return
//		}
//	}
//	//if len(output.outputPipe) < bufferDataMinimumCount {
//	//}
//}

func Buffer(outputPathList []string, debug_ bool) {

	debug = debug_

	func () {
		var err error
		bufferFileDirPath, err = ioutil.TempDir("", fmt.Sprintf("%s_", toolname))
		if err != nil {
			panic(err)
		}
	}()

	// 入力用goroutine起動
	inputPipe := make(chan []byte, 0)
	go readFromFile(inputPipe, os.Stdin)

	messageCh := make(chan outputMessage, len(outputPathList) + 1)

	// 出力先一覧を作成
	outputs = make([]*output, len(outputPathList) + 1)
	outputs[0] = &output {
		path: "",
		file: os.Stdout,
		outputPipe: make(chan []byte, bufferChannelSize),
		bufferFilePos: -1,
		finishedFlag: false,
	}
	for i, path := range(outputPathList) {
		file, err := os.OpenFile(path, os.O_WRONLY|os.O_CREATE, 0700)
		if err != nil {
			panic(err)
		}
		outputs[1 + i] = &output {
			path: path,
			file: file,
			outputPipe: make(chan []byte, bufferChannelSize),
		}
	}

	// 出力用goroutine起動
	for i, output := range(outputs) {
		go writeToFile(output.outputPipe, output.file, i, messageCh)
	}

	L1: for {
		if debug {
			//fmt.Fprintf(os.Stderr, "DEBUG process1 inputClosed:%v inputCountNeeded:%d fastestOutputIndex:%d\n", inputClosed, inputCountNeeded, fastestOutputIndex)
		}
		if inputClosed || inputCountNeeded == 0 {
			// 入力元が閉じられている場合
			// または、すべての出力先にバッファが溜まっていて入力を取り込む必要がない場合
			msg, _ := <- messageCh
			if msg.message == stepOutputMessage {
				onOutputStep(msg.index)
			} else if msg.message == closeOutputMessage {
				if onOutputFinished(msg.index) {
					break L1
				}
			}
		} else {
			select {
			case msg, _ := <- messageCh:
				if msg.message == stepOutputMessage {
					onOutputStep(msg.index)
				} else if msg.message == closeOutputMessage {
					if onOutputFinished(msg.index) {
						break L1
					}
				}

			case readbuf, more := <- inputPipe:
				if !more {
					for _, output := range(outputs) {
						close(output.outputPipe)
					}
					inputClosed = true
					break
				}
				inputCountNeeded--
				//for index, output := range(outputs) {
				for _, output := range(outputs) {
					if !output.finishedFlag && output.bufferFilePos < 0 {
						select {
						case output.outputPipe <- readbuf:
							// no operation
						default:
							//startOutputBufferFile(index)
						}
					}
/*
					if bufferFileCounter > 0 {
						writeToWriter(readbuf, bufferFileWriter, false)
						bufferFileContentSize++
						if bufferFileContentSize == bufferFileContentMaxSize {
							bufferFileContent = nil
							bufferFileContentSize = -1
						} else if bufferFileContentSize >= 0 {
							bufferFileContent[bufferFileContentSize] = readbuf
							bufferFileContentSize++
						}
					}
*/
				}

			}
		}
	}
}

type fileBuffer struct {
	file []*oneFileBuffer
}

type oneFileBuffer struct {
	startPos int
	file *os.File
	writer *bufio.Writer
	bufferFileContent [][]byte //= make([][]byte, bufferFileContentMaxSize)
	bufferFileContentSize int
}

var (
	fileBufferInfo *fileBuffer
)

func startOutputBufferFile() {
	fileBufferInfo = &fileBuffer {
		
	}
/*
	nextInputBufferFile()
	if debug {
		fmt.Fprintf(os.Stderr, "startOutputBufferFile outputIndex: %d\n", index)
	}
	output := outputs[index]
	output.bufferFileFlag = true
	output.bufferFileCounter = bufferFileCounter
	output.bufferFileHandle = nil
*/
}

/*
func pushToFileBuffer(buf []byte) {
}

func popFromFileBuffer(pos int) (buf [][]byte, pos int) {
}

func setFileBufferLastPosition(pos int) {
}
*/

