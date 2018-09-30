
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
		val executor = StridxExecutor();
		JvmCommandLine(executor, input.arg, output.arg,
			ParserMain.commandLineIOStringForDebug(input, output)) :: Nil;
	}

}

case class StridxExecutor() extends CommandExecutor {

	def exec(inputFilePath: String, outputFilePath: String) {
		val inputStream = new FileInputStream(inputFilePath);
		val lineIterator = Source.fromInputStream(inputStream, "UTF-8").getLines;
		val outputStream =new FileOutputStream(outputFilePath);
		val writer = new PrintWriter(new BufferedWriter(new OutputStreamWriter(outputStream, "UTF-8")));
		try {
			exec(lineIterator, writer);
		} finally {
			writer.close();
			inputStream.close();
		}
	}

	private def exec(lineIterator: Iterator[String], writer: PrintWriter) {
		writer.println("value\trange");

		val header = lineIterator.next();
		val indexData = new IndexData();
		lineIterator.foreach { line =>
			val record = readLine(line);
			indexData.add(record._1, record._2);
		}
		indexData.output(writer);
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

	private case class RangeList(records: List[FileRange]) {

		def add(other: FileRange): RangeList = {
			val h = records.head;
			if (h.offset + h.length == other.offset) {
				RangeList(FileRange(h.offset, h.length + other.length) :: records.tail);
			} else {
				RangeList(other :: records);
			}
		}

		def toFileRangeList = FileRangeList(records.reverse);

	}

	private object RangeList {
		def apply(r: FileRange) = new RangeList(r :: Nil);
	}

	private class IndexData {

		private[this] val map = new HashMap[String, RangeList]();

		def add(value: String, range: FileRange) {
			if (map.containsKey(value)) {
				val r = map.get(value);
				map.put(value, r.add(range));
			} else {
				map.put(value, RangeList(range));
			}
		}

		def output(writer: PrintWriter) {
			val values = map.keySet.asScala.toSeq.sorted;
			values.foreach { value =>
				val rangeList = map.get(value);
				val s = rangeList.toFileRangeList.toString;
				writer.println(value + "\t" + s);
			}
		}

	}

}


