
// このソースコードが実装している機能はいったん廃止されました。
// このソースコードはいまはビルドの対象にはなっていません。
// 将来機能を復活させる前提でソースは残しています。

import java.io.InputStream;
import java.io.FileInputStream;
import java.io.OutputStream;
import java.io.FileOutputStream;
import java.io.OutputStreamWriter;
import java.io.BufferedWriter;
import java.io.PrintWriter;
import java.util.HashMap;

import scala.io.Source;
import scala.collection.JavaConverters._;

case class StridxCommandParser (
) extends CommandParser {

	def eat(args: List[String]): Option[(CommandParser, List[String])] = {
		None;
	}

	def createCommand(): Command = {
		StridxCommand();
	}

}

case class StridxCommand () extends Command {

	def createCommandLines(input: InputResource, output: OutputResource): List[CommandLine] = {
		val tempFile = GlobalParser.createHardTempFile();
		val executor = StridxExecutor(tempFile);
		JvmCommandLine(executor, input.arg, output.arg,
			ParserMain.commandLineIOStringForDebug(input, output)) :: Nil;
	}

}

case class StridxExecutor(tempFile: HardTempFileResource) extends CommandExecutor {

	private[this] val maxIndexMemorySize: Long = 100 * 1024 * 1024; // 100MB
	private[this] val mergeFileCount: Int = 10;

	def exec(inputFilePath: String, outputFilePath: String) {
		val inputStream = new FileInputStream(inputFilePath);
		val lineIterator = Source.fromInputStream(inputStream, "UTF-8").getLines;
		val outputStream = new FileOutputStream(outputFilePath);
		val writer = new PrintWriter(new BufferedWriter(new OutputStreamWriter(outputStream, "UTF-8")));
		try {
			exec(lineIterator, writer);
		} finally {
			writer.close();
			inputStream.close();
		}
	}

	private[this] def exec(lineIterator: Iterator[String], writer: PrintWriter) {
		val header = lineIterator.next();

		var tempFileId: Int = 0;
		execSub(lineIterator, tempFileId, writer);
		if (lineIterator.hasNext) {
			tempFileId = tempFileId + 1;
			execSub(lineIterator, tempFileId, writer);
			tempFileId = tempFileId + 1;
			while (lineIterator.hasNext) {
				execSub(lineIterator, tempFileId, writer);
				tempFileId = tempFileId + 1;
			}
			mergeTempFiles(tempFileId, writer);
		}
	}

	private[this] def execSub(lineIterator: Iterator[String], tempFileId: Int, resultWriter: PrintWriter) {
		val indexData = createIndexData(lineIterator);
		if (tempFileId == 0 && !lineIterator.hasNext) {
			outputHeader(resultWriter);
			indexData.output(resultWriter);
		} else {
			val path = tempFilePath(tempFileId);
			val outputStream = new FileOutputStream(path);
			val writer = new PrintWriter(new BufferedWriter(new OutputStreamWriter(outputStream, "UTF-8")));
			try {
				indexData.output(writer);
			} finally {
				writer.close();
			}
		}
	}

	private[this] def createIndexData(lineIterator: Iterator[String]): IndexData = {
		val indexData = new IndexData();
		while (lineIterator.hasNext && indexData.roughSize() < maxIndexMemorySize) {
			val line = lineIterator.next();
			val record = readLine(line);
			indexData.add(record._1, record._2);
		}
		indexData;
	}

	private def readLine(line: String): (String, FileRange) = {
		val cols = line.split("\t", -1);
		if (cols.length != 3) {
			throw new UserException("Illegal stridx input line: " + line);
		}
		try {
			(cols(0), FileRange(cols(1).toLong, cols(2).toLong));
		} catch { case _: NumberFormatException =>
			throw new UserException("Illegal stridx input line: " + line);
		}
	}

	private[this] def mergeTempFiles(tempFileCount: Int, resultWriter: PrintWriter) {
		@scala.annotation.tailrec
		def sub(tempFileIdStart: Int, tempFileIdEnd: Int) {
			val end = tempFileIdStart + mergeFileCount;
			if (tempFileIdEnd  <= end) {
				outputHeader(resultWriter);
				mergeTempFilesSub(tempFileIdStart, tempFileIdEnd, resultWriter);
			} else {
				val path = tempFilePath(tempFileIdEnd);
				val outputStream = new FileOutputStream(path);
				val writer = new PrintWriter(new BufferedWriter(new OutputStreamWriter(outputStream, "UTF-8")));
				try {
					mergeTempFilesSub(tempFileIdStart, end, writer);
				} finally {
					writer.close();
				}
				sub(end, tempFileIdEnd + 1);
			}
		}

		sub(0, tempFileCount);
	}

	private[this] def mergeTempFilesSub(tempFileIdStart: Int, tempFileIdEnd: Int, writer: PrintWriter) {
		class Input(lineIterator: Iterator[String], inputStream: InputStream, path: String) {

			private[this] var _hasValue: Boolean = true;
			private[this] var _value: String = "";
			private[this] var _rangeList: FileRangeList = FileRangeList(Nil);

			if (lineIterator.hasNext) {
				parseLine(lineIterator.next());
			} else {
				_hasValue = false;
			}

			def hasValue: Boolean = _hasValue;
			def value: String = _value;
			def rangeList: FileRangeList = _rangeList;

			def next() {
				if (lineIterator.hasNext) {
					parseLine(lineIterator.next());
				} else {
					_hasValue = false;
				}
			}

			def close() {
				try {
					inputStream.close();
					(new java.io.File(path)).delete();
				} catch { case _: java.io.IOException =>
					// nop
				}
			}

			private[this] def parseLine(line: String) {
				val cols = line.split("\t", -1);
				if (cols.size != 2) {
					throw new IllegalArgumentException(line);
				}
				_value = cols(0);
				_rangeList = FileRangeList.parse(cols(1));
			}
		}

		val inputs: IndexedSeq[Input] = (tempFileIdStart until tempFileIdEnd).map { i =>
			val path = tempFilePath(i);
			val inputStream = new FileInputStream(path);
			val lineIterator = Source.fromInputStream(inputStream, "UTF-8").getLines;
			new Input(lineIterator, inputStream, path);
		}

		@scala.annotation.tailrec
		def sub(inputs: IndexedSeq[Input]) {
			if (inputs.isEmpty) {
				return;
			}
			val value = inputs.minBy(_.value).value;
			val inputs2 = inputs.filter(_.value == value);
			val fr: FileRangeList = if (inputs2.size == 1) {
				val i = inputs2.head;
				val fr = i.rangeList;
				i.next();
				fr;
			} else {
				val fr = inputs2.map(_.rangeList).foldLeft[FileRangeList](FileRangeList(Nil)) { (fr1, fr2) =>
					fr1 merge fr2;
				}
				inputs2.foreach(_.next());
				fr;
			}
			outputSub(value, fr, writer);
			sub(inputs.filter(_.hasValue));
		}

		try {
			sub(inputs.filter(_.hasValue));
		} finally {
			inputs.foreach { input =>
				input.close();
			}
		}
	}

	private[this] def tempFilePath(tempFileId: Int): String = tempFile.path + "-" + tempFileId;

	private[this] def outputHeader(writer: PrintWriter) {
		writer.println("value\trange");
	}

	private case class ReverseRangeList(ranges: List[FileRange]) {

		def add(other: FileRange): ReverseRangeList = {
			val h = ranges.head;
			if (h.offset + h.length == other.offset) {
				ReverseRangeList(FileRange(h.offset, h.length + other.length) :: ranges.tail);
			} else {
				ReverseRangeList(other :: ranges);
			}
		}

		def toFileRangeList = FileRangeList(ranges.reverse);

	}

	private object ReverseRangeList {
		def apply(r: FileRange) = new ReverseRangeList(r :: Nil);
	}

	private class IndexData {

		private[this] val map = new HashMap[String, ReverseRangeList]();
		private[this] var _roughSize: Long = 0;

		def add(value: String, range: FileRange) {
			if (map.containsKey(value)) {
				val r = map.get(value);
				map.put(value, r.add(range));
				_roughSize = _roughSize + 32;
			} else {
				map.put(value, ReverseRangeList(range));
				_roughSize = _roughSize + 3 * value.length + 32 + 32;
			}
		}

		def roughSize(): Long = _roughSize;

		def output(writer: PrintWriter) {
			val values = map.keySet.asScala.toSeq.sorted;
			values.foreach { value =>
				val rangeList = map.get(value);
				outputSub(value, rangeList.toFileRangeList, writer);
			}
		}

	}

	private[this] def outputSub(value: String, rangeList: FileRangeList, writer: PrintWriter) {
		val s = rangeList.toString;
		writer.println(value + "\t" + s);
	}

}


