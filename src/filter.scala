
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
		// Input - tee-header.pl - fifo1 ------------------------ union-header.pl - Output
		//                     \                                  /
		//                     fifo2 - FilterStridxExecutor - fifo3
		//                            /
		//    stridxInput - stridxFifo

		val stridxFifo = GlobalParser.createFifo(); // output of stridxInput and input of paste subcommand

		val stridxInputCmds = stridxInput.createCommandLines(None, Some(stridxFifo.o), true);
		val (stridxFifoI, stridxFifoCmds) = if (stridxInputCmds.isEmpty) {
			val stridxInputResource: ExternalInputResource = stridxInput.inputFormatWrapper.get.input.input;
			(stridxInputResource, Nil);
		} else {
			val stridxFifoCmds = stridxFifo.createMkfifoCommandLines();
			(stridxFifo.i, stridxFifoCmds);
		}

		val fifo1 = GlobalParser.createFifo();
		val fifo2 = GlobalParser.createFifo();
		val fifo3 = GlobalParser.createFifo();
		val fifoCmds: List[CommandLine] = {
			val teeHeaderCmd = CommandLineImpl(NormalArgument("perl") :: ToolDirArgument("tee-header.pl") :: fifo1.arg :: Nil,
				Some(input.arg), Some(fifo2.arg), true, ParserMain.commandLineIOStringForDebug(input, fifo2.o));
			val teeHeaderDebug = CommandLineImpl(Nil, None, None, false,
				ParserMain.commandLineIOStringForDebug(input, fifo1.o));
			val unionHeaderCmd = CommandLineImpl(NormalArgument("perl") :: ToolDirArgument("union-header.pl") :: fifo1.arg :: Nil,
				Some(fifo3.arg), Some(output.arg), true, ParserMain.commandLineIOStringForDebug(fifo3.i, output));
			val unionHeaderDebug = CommandLineImpl(Nil, None, None, false,
				ParserMain.commandLineIOStringForDebug(fifo1.i, output));
			fifo1.createMkfifoCommandLines() ::: fifo2.createMkfifoCommandLines() ::: fifo3.createMkfifoCommandLines() :::
				teeHeaderCmd :: teeHeaderDebug :: unionHeaderCmd :: unionHeaderDebug :: Nil;
		}

		val executor = FilterStridxExecutor(column, value, stridxFifoI.arg);
		val command = JvmCommandLine(executor, fifo2.arg, fifo3.arg,
			ParserMain.commandLineIOStringForDebug(fifo2.i, fifo3.o));
		val debug = CommandLineImpl(Nil, None, None, false,
			ParserMain.commandLineIOStringForDebug(stridxFifoI, fifo3.o));

		fifoCmds ::: stridxFifoCmds ::: stridxInputCmds :::
		command :: debug :: Nil;
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

		val buf: Array[Byte] = new Array[Byte](4096);

		srList.foreach { sr =>
			var skip: Long = sr.skip;
			while (skip > 0) {
				val l = if (skip >= buf.length) {
					inputStream.read(buf);
				} else {
					inputStream.read(buf, 0, skip.toInt);
				}
				//val l = inputStream.skip(skip);
				skip = skip - l;
			}
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

}

