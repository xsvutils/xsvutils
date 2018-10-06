
import java.io.InputStream;
import java.io.BufferedInputStream;
import java.io.FileInputStream;
import java.io.OutputStream;
import java.io.BufferedOutputStream;
import java.io.FileOutputStream;
//import java.io.OutputStreamWriter;
//import java.io.BufferedWriter;
//import java.io.PrintWriter;

import scala.io.Source;

case class FilterCommandParser (
	column: Option[String],
	operator: Option[String],
	value: Option[String],
	stridxInput: Option[Either[String, (QueryParser, Boolean)]]
) extends CommandParser {

	override def eatSubquery: Boolean = {
		stridxInput match {
			case Some(Right((q, false))) => true;
			case _ => false;
		}
	}

	def eat(args: List[String]): Option[(CommandParser, List[String])] = {
		import GlobalParser.ColumnNamePattern;
		import FilterCommandParser._;

		stridxInput match {
			case Some(Right((q, false))) =>
				val (subQuery2, tail, isClosed) = q.eat(args);
				Some((this.copy(stridxInput = Some(Right((subQuery2, isClosed)))), tail));
			case _ =>
				args match {
					case "--stridx" :: "[" :: tail =>
						stridxInput match {
							case Some(_) =>
								throw new UserException("duplicated option: " + args.head);
							case None =>
								Some((this.copy(stridxInput = Some(Right((QueryParser(queryCommandName = Some("filter"),
									inputOk = true, outputOk = false,
									existsDefaultInput = false, existsDefaultOutput = true), false)))), tail));
						}
					case "--stridx" :: arg :: tail =>
						stridxInput match {
							case Some(_) =>
								throw new UserException("duplicated option: " + args.head);
							case None =>
								if (!(new java.io.File(arg)).exists) {
									throw new UserException("File not found: " + arg);
								}
								Some((this.copy(stridxInput = Some(Left(arg))), tail));
						}
					case GlobalParser.OptionPattern() :: tail =>
						None;
					case (column @ColumnNamePattern()) :: (operator @NumberOperatorPattern()) :: (value @NumberPattern()) :: tail =>
						(this.column, this.operator, this.value) match {
							case (Some(_), _, _) => throw new UserException("duplicated argument");
							case (_, Some(_), _) => throw new UserException("duplicated argument");
							case (_, _, Some(_)) => throw new UserException("duplicated argument");
							case (None, None, None) =>
								Some((this.copy(column = Some(column), operator = Some(operator), value = Some(value)), tail));
						}
					case (column @ColumnNamePattern()) :: (operator @StringOperatorPattern()) :: value :: tail =>
						(this.column, this.operator, this.value) match {
							case (Some(_), _, _) => throw new UserException("duplicated argument");
							case (_, Some(_), _) => throw new UserException("duplicated argument");
							case (_, _, Some(_)) => throw new UserException("duplicated argument");
							case (None, None, None) =>
								Some((this.copy(column = Some(column), operator = Some(operator), value = Some(value)), tail));
						}
					case _ =>
						None;
				}
		}
	}

	def createCommand(): Command = {
		val stridxInput2: Option[QueryTree] = stridxInput match {
			case Some(Left(path)) =>
				Some(QueryTree.create(
					input = Some(ExternalInputResourceFormat(FileInputResource(path), None, None)),
					output = None,
					existsDefaultInput = false, existsDefaultOutput = true, commands = Nil));
			case Some(Right((q, _))) =>
				Some(q.createTree());
			case None =>
				None;
		}

		(column, operator, value) match {
			case (Some(column), Some(operator), Some(value)) =>
				(stridxInput2, operator) match {
					case (Some(stridxInput2), "eq") =>
						FilterStridxCommand(column, value, stridxInput2);
					case (Some(_), _) =>
						throw new UserException("operator `" + operator + "` is not allowed with `--stridx` option on `filter` or `where` subcommand");
					case (None, _) =>
						FilterCommand(column, operator, value);
				}
			case _ =>
				throw new UserException("subcommand `filter` needs arguments");
		}
	}

}

object FilterCommandParser {

	val NumberPattern = "(?:0|[1-9][0-9]*)".r;
	val NumberOperatorPattern = "(?:[!=]=|[><]=?)".r;
	val StringOperatorPattern = "(?:eq|ne|[gl][et]|[!=]~)".r;

}

case class FilterCommand (
	column: String,
	operator: String,
	value: String
) extends Command {

	def createCommandLines(input: InputResource, output: OutputResource): List[CommandLine] = {
		val options = NormalArgument(column) :: NormalArgument(operator) :: NormalArgument(value) :: Nil;
		CommandLineImpl(NormalArgument("perl") :: ToolDirArgument("where.pl") :: options,
			Some(input.arg), Some(output.arg), true, ParserMain.commandLineIOStringForDebug(input, output)) :: Nil;
	}

}

case class FilterStridxCommand (
	column: String,
	value: String,
	stridxInput: QueryTree
) extends Command {

	override def externalInputFormatWrapper: List[InputFormatWrapper] = {
		stridxInput.externalInputFormatWrapper;
	}

	override def stdins: List[InputFormatWrapper] = {
		stridxInput.stdins;
	}

	def createCommandLines(input: InputResource, output: OutputResource): List[CommandLine] = {
		// Input ----------------- FilterStridxExecutor - Output
		//                         /
		// stridxInput - stridxFifo

		val stridxFifo = GlobalParser.createFifo(); // output of stridxInput and input of filter subcommand

		val stridxInputCmds = stridxInput.createCommandLines(None, Some(stridxFifo.o), true);
		val (stridxFifoI, stridxFifoCmds) = if (stridxInputCmds.isEmpty) {
			val stridxInputResource: ExternalInputResource = stridxInput.inputFormatWrapper.get.input.input;
			(stridxInputResource, Nil);
		} else {
			val stridxFifoCmds = stridxFifo.createMkfifoCommandLines();
			(stridxFifo.i, stridxFifoCmds);
		}

		val executor = FilterStridxExecutor(column, value, stridxFifoI.arg);
		val command = JvmCommandLine(executor, input.arg, output.arg,
			ParserMain.commandLineIOStringForDebug(input, output));
		val debug = CommandLineImpl(Nil, None, None, false,
			ParserMain.commandLineIOStringForDebug(stridxFifoI, output));

		stridxFifoCmds ::: stridxInputCmds ::: command :: debug :: Nil;
	}
}

case class FilterStridxExecutor(column: String, value: String, stridxFile: CommandLineArgument) extends CommandExecutor {

	def exec(inputFilePath: String, outputFilePath: String) {
		val inputStream = new BufferedInputStream(new FileInputStream(inputFilePath));

		val stridxFilePath = stridxFile.toRaw;

		val stridxInputStream = new FileInputStream(stridxFilePath);
		val stridxLineIterator = Source.fromInputStream(stridxInputStream, "UTF-8").getLines;
		val outputStream = new BufferedOutputStream(new FileOutputStream(outputFilePath));
		try {
			exec(inputStream, stridxLineIterator, outputStream);
		} finally {
			outputStream.close();
			stridxInputStream.close();
			inputStream.close();
		}
	}

	private[this] def exec(inputStream: BufferedInputStream, stridxLineIterator: Iterator[String], outputStream: BufferedOutputStream) {
		val rangeList = searchRangeList(stridxLineIterator);
		val srList = rangeList.getOrElse(FileRangeList(Nil)).toSkipAndReadList;

		if (srList.isEmpty) {
			val (_, bufList: List[(Array[Byte], Int)]) = readHeader(inputStream, -1);
			bufList.foreach { t =>
				val (buf, len) = t;
				outputStream.write(buf, 0, len);
			}
		} else {
			val srHead = srList.head;
			val firstOffset = srHead.skip;
			val (offset, bufList: List[(Array[Byte], Int)]) = readHeader(inputStream, firstOffset);
			bufList.foreach { t =>
				val (buf, len) = t;
				outputStream.write(buf, 0, len);
			}

			val srList2: List[FileSkipAndRead] = FileSkipAndRead(firstOffset - offset, srHead.read) :: srList.tail;

			val buf: Array[Byte] = new Array[Byte](4096);

			srList2.foreach { sr =>
				var skip: Long = sr.skip;
				skipStream(inputStream, skip, buf);
				var read: Long = sr.read;
				while (read > 0) {
					val l = if (read >= buf.length) {
						inputStream.read(buf);
					} else {
						inputStream.read(buf, 0, read.toInt);
					}
					read = read - l;
					outputStream.write(buf, 0, l);
				}
			}
		}
	}

	private[this] def searchRangeList(stridxLineIterator: Iterator[String]): Option[FileRangeList] = {
		var f: Boolean = true;
		var rangeList: Option[FileRangeList] = None;
		while (f) {
			if (stridxLineIterator.hasNext) {
				val line = stridxLineIterator.next;
				val cols = line.split("\t", 2);
				if (cols.size < 2) {
					throw new UserException("Illegal filter stridx input line: " + line);
				}
				if (cols(0) == value) {
					rangeList = try {
						Some(FileRangeList.parse(cols(1)));
					} catch { case _: IllegalArgumentException =>
						throw new UserException("Illegal filter stridx input line: " + line);
					}
					f = false;
				}
			} else {
				f = false;
			}
		}
		rangeList;
	}

	private[this] def readHeader(inputStream: BufferedInputStream, firstOffset: Long): (Int, List[(Array[Byte], Int)]) = {
		var offset: Int = 0;
		var bufList: List[(Array[Byte], Int)] = Nil;
		var f: Boolean = true;
		var headLen: Int = 0;
		while (f) {
			val buf: Array[Byte] = new Array[Byte](1024);
			val len = if (firstOffset < 0) {
				buf.length;
			} else {
				val rest = firstOffset - offset;
				if (rest < buf.length) {
					rest.toInt;
				} else {
					buf.length;
				};
			}
			val len2 = inputStream.read(buf, 0, len);
			if (len2 < 0) {
				return (offset, bufList.reverse);
			}
			offset = offset + len2;
			val pos = (0 until len2).indexWhere(i => buf(i) == '\n');
			if (pos >= 0) {
				headLen = headLen + pos + 1;
				bufList = (buf, headLen + 1) :: bufList;
				return (offset, bufList.reverse);
			}
			headLen = headLen + len2;
			bufList = (buf, len2) :: bufList;
		}
		throw new AssertionError();
	}

	private[this] def skipStream(inputStream: BufferedInputStream, skip: Long, buf: Array[Byte]) {
		var skip2: Long = skip;
		while (skip2 > 0) {
			val l = if (skip2 >= buf.length) {
				inputStream.read(buf);
			} else {
				inputStream.read(buf, 0, skip2.toInt);
			}
			skip2 = skip2 - l;
		}
	}

}

