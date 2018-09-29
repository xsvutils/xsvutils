
import ParserMain._;

class UserException(message: String) extends Exception(message);

//==================================================================================================

case class GlobalParser (
	globalQuery: QueryParser,
	explain: Boolean,
	isInputTty: Boolean,
	isOutputTty: Boolean
) {

	def eat(args: List[String]): (GlobalParser, List[String]) = {
		args match {
			case "--explain" :: tail =>
				(this.copy(explain = true), tail);
			case "--input-tty" :: tail =>
				(this.copy(isInputTty = true), tail);
			case "--output-tty" :: tail =>
				(this.copy(isOutputTty = true), tail);
			case _ =>
				val (query, tail, _) = globalQuery.eat(args);
				(this.copy(globalQuery = query), tail);
		}
	}

	def createTree(): GlobalTree = {
		StdinResource.isInputTty = isInputTty;
		StdoutResource.isOutputTty = isOutputTty;
		val queryTree = globalQuery.createTree();
		new GlobalTree(queryTree, explain);
	}

}

object GlobalParser {

	val OptionPattern = "-.*".r;
	val ColumnNamePattern = "[_0-9a-zA-Z][-_0-9a-zA-Z]*".r;

	def apply() = new GlobalParser(QueryParser(None, true, true, false, false), false, false, false);

	def parse(args: List[String]): GlobalParser = {
		@scala.annotation.tailrec
		def sub(opt: GlobalParser, args: List[String]): GlobalParser = {
			val (opt2, args2) = opt.eat(args);
			args2 match {
				case Nil =>
					opt2;
				case _ if (args2 == args) =>
					throw new AssertionError();
				case _ =>
					sub(opt2, args2);
			}
		}
		sub(GlobalParser(), args);
	}

	private var fifoCounter: Int = 0;
	private var fifoCommandLines: Set[Int] = Set.empty;

	def createFifo(): FifoResource = {
		fifoCounter = fifoCounter + 1;
		FifoResource(fifoCounter);
	}

	def createMkfifoCommandLines(id: Int): Boolean = {
		if (fifoCommandLines.contains(id)) {
			false;
		} else {
			fifoCommandLines = fifoCommandLines + id;
			true;
		}
	}

	def createInputFormatWrapper(input: ExternalInputResourceFormat): InputFormatWrapper = {
		val resultFifo = createFifo();
		val streamFifo = createFifo();
		new InputFormatWrapper(input, resultFifo, streamFifo);
	}

}

//==================================================================================================

case class QueryParser (
	queryCommandName: Option[String],
	inputOk: Boolean,
	outputOk: Boolean,
	existsDefaultInput: Boolean,
	existsDefaultOutput: Boolean,
	inputPath: Option[Either[Unit, String]], // Left: stdin, Right: file
	inputFormat: Option[InputFileFormat],
	inputHeader: Option[List[String]],
	outputPath: Option[Either[Unit, String]], // Left: stdout, Right: file
	outputFormat: Option[OutputFileFormat],
	outputHeader: Option[Boolean],
	commands: List[CommandParser],
	lastCommand: Option[CommandParser]
) {

	def eat(args: List[String]): (QueryParser, List[String], Boolean) = {
		args match {
			case Nil =>
				(this, args, false);
			case "-" :: tail if (inputPath.isEmpty) =>
				throwIfUnexpectedInputOption(queryCommandName, inputOk);
				(this.copy(inputPath = Some(Left(()))), tail, false);
			case a :: tail if (QueryParser.commands.contains(a)) =>
				if (inputPath.isEmpty && (new java.io.File(a)).exists) {
					throwIfUnexpectedInputOption(queryCommandName, inputOk);
					throw new UserException("ambiguous parameter: " + a + ", use -i");
				}
				lastCommand match {
					case None =>
						(this.copy(lastCommand = Some(QueryParser.commands(a)())), tail, false);
					case Some(c) =>
						(this.copy(commands = c :: commands, lastCommand = Some(QueryParser.commands(a)())), tail, false);
				}
			case a :: tail if (!a.matches("-.*") && inputPath.isEmpty && (new java.io.File(a)).exists) &&
					!(lastCommand.map(_.eatFilePathPriority).getOrElse(false)) =>
				throwIfUnexpectedInputOption(queryCommandName, inputOk);
				(this.copy(inputPath = Some(Right(a))), tail, false);
			case "--tsv" :: tail =>
				throwIfUnexpectedInputOption(queryCommandName, inputOk);
				inputFormat match {
					case None => (this.copy(inputFormat = Some(TsvFileFormat)), tail, false);
					case _ => throw new UserException("duplicated option: " + args.head);
				}
			case "--csv" :: tail =>
				throwIfUnexpectedInputOption(queryCommandName, inputOk);
				inputFormat match {
					case None => (this.copy(inputFormat = Some(CsvFileFormat)), tail, false);
					case _ => throw new UserException("duplicated option: " + args.head);
				}
			case "--o-tsv" :: tail =>
				throwIfUnexpectedOutputOption(queryCommandName, outputOk);
				outputFormat match {
					case None => (this.copy(outputFormat = Some(TsvFileFormat)), tail, false);
					case _ => throw new UserException("duplicated option: " + args.head);
				}
			case "--o-csv" :: tail =>
				throwIfUnexpectedOutputOption(queryCommandName, outputOk);
				outputFormat match {
					case None => (this.copy(outputFormat = Some(CsvFileFormat)), tail, false);
					case _ => throw new UserException("duplicated option: " + args.head);
				}
			case "--o-table" :: tail =>
				throwIfUnexpectedOutputOption(queryCommandName, outputOk);
				outputFormat match {
					case None => (this.copy(outputFormat = Some(TableFileFormat)), tail, false);
					case _ => throw new UserException("duplicated option: " + args.head);
				}
			case "--o-diffable" :: tail =>
				throwIfUnexpectedOutputOption(queryCommandName, outputOk);
				outputFormat match {
					case None => (this.copy(outputFormat = Some(DiffableFileFormat)), tail, false);
					case _ => throw new UserException("duplicated option: " + args.head);
				}
			//case "--o-chart" :: tail =>
			case "-i" :: "-" :: tail =>
				throwIfUnexpectedInputOption(queryCommandName, inputOk);
				inputPath match {
					case None => (this.copy(inputPath = Some(Left(()))), tail, false);
					case _ => throw new UserException("duplicated option: " + args.head);
				}
			case "-i" :: a :: tail =>
				throwIfUnexpectedInputOption(queryCommandName, inputOk);
				inputPath match {
					case None => (this.copy(inputPath = Some(Right(a))), tail, false);
					case _ => throw new UserException("duplicated option: " + args.head);
				}
			case "-o" :: "-" :: tail =>
				throwIfUnexpectedOutputOption(queryCommandName, outputOk);
				outputPath match {
					case None => (this.copy(outputPath = Some(Left(()))), tail, false);
					case _ => throw new UserException("duplicated option: " + args.head);
				}
			case "-o" :: a :: tail =>
				throwIfUnexpectedOutputOption(queryCommandName, outputOk);
				outputPath match {
					case None => (this.copy(outputPath = Some(Right(a))), tail, false);
					case _ => throw new UserException("duplicated option: " + args.head);
				}
			case "--header" :: Nil =>
				throw new UserException("option " + args.head + " needs an argument");
			case "--header" :: (arg @QueryParser.HeaderArgPattern()) :: tail =>
				throwIfUnexpectedInputOption(queryCommandName, inputOk);
				inputHeader match {
					case Some(_) => throw new UserException("duplicated option: " + args.head);
					case None =>
						val cols = arg.split(",").toList;
						(this.copy(inputHeader = Some(cols)), tail, false);
				}
			case "--header" :: arg :: tail =>
				throw new UserException("Illegal argument of " + args.head + ": " + arg);
			case "--ltsv" :: Nil =>
				throw new UserException("option " + args.head + " needs an argument");
			case "--ltsv" :: (arg @QueryParser.HeaderArgPattern()) :: tail =>
				throwIfUnexpectedInputOption(queryCommandName, inputOk);
				inputFormat match {
					case Some(_) => throw new UserException("duplicated option: " + args.head);
					case None =>
						val cols = arg.split(",").toList;
						(this.copy(inputFormat = Some(LtsvFileFormat), inputHeader = Some(cols)), tail, false);
				}
			case "--ltsv" :: arg :: tail =>
				throw new UserException("Illegal argument of " + args.head + ": " + arg);
			case "--o-no-header" :: tail =>
				throwIfUnexpectedOutputOption(queryCommandName, outputOk);
				outputHeader match {
					case None => (this.copy(outputHeader = Some(false)), tail, false);
					case _ => throw new UserException("duplicated option: " + args.head);
				}
			case "]" :: tail if queryCommandName.isDefined =>
				(this, tail, true);
			case a :: tail if (lastCommand.isDefined) =>
				lastCommand.get.eat(args) match {
					case Some((c2, tail)) =>
						(this.copy(lastCommand = Some(c2)), tail, false);
					case None =>
						eatSub(args, queryCommandName, inputOk, outputOk);
				}
			case a :: tail =>
				eatSub(args, queryCommandName, inputOk, outputOk);
		}
	}

	private[this] def eatSub(args: List[String], queryCommandName: Option[String],
		inputOk: Boolean, outputOk: Boolean): (QueryParser, List[String], Boolean) = {
		args match {
			case "]" :: tail =>
				throw new UserException("Unexpected argument: " + "]");
			case a :: tail =>
				throw new UserException("Unknown argument: " + a);
			case Nil =>
				throw new AssertionError("Unlikely to be reached here");
		}
	}

	private[this] def throwIfUnexpectedInputOption(queryCommandName: Option[String], inputOk: Boolean) {
		if (!inputOk) {
			throw new UserException("sub query of " + queryCommandName.get + " must not have input option");
		}
	}

	private[this] def throwIfUnexpectedOutputOption(queryCommandName: Option[String], outputOk: Boolean) {
		if (!outputOk) {
			throw new UserException("sub query of " + queryCommandName.get + " must not have output option");
		}
	}

	def createTree(): QueryTree = {
		val inputPath2 = (inputPath, inputFormat, inputHeader) match {
			case (Some(_), _, _) => inputPath;
			case (None, Some(_), _) => Some(Left(()));
			case (None, _, Some(_)) => Some(Left(()));
			case _ if (!existsDefaultInput) => Some(Left(()));
			case _ => None;
		}
		val input: Option[ExternalInputResourceFormat] = inputPath2 match {
			case None => None;
			case Some(Left(_)) => Some(ExternalInputResourceFormat(StdinResource(), inputFormat, inputHeader));
			case Some(Right(path)) => Some(ExternalInputResourceFormat(FileInputResource(path), inputFormat, inputHeader));
		}

		val outputPath2 = (outputPath, outputFormat, outputHeader) match {
			case (Some(_), _, _) => outputPath;
			case (None, Some(_), _) => Some(Left(()));
			case (None, _, Some(_)) => Some(Left(()));
			case _ if (!existsDefaultOutput) => Some(Left(()));
			case _ => None;
		}
		val outputHeader2 = outputHeader.getOrElse(true);
		val output: Option[ExternalOutputResourceFormat] = outputPath2 match {
			case None => None;
			case Some(Left(_)) => Some(ExternalOutputResourceFormat(StdoutResource(), outputFormat, outputHeader2));
			case Some(Right(path)) => Some(ExternalOutputResourceFormat(FileOutputResource(path), outputFormat, outputHeader2));
		}

		val newCommands: List[Command] = (lastCommand match {
			case None => commands;
			case Some(c) => c :: commands;
		}).reverse.map(_.createCommand());

		QueryTree.create(
			input,
			output,
			existsDefaultInput,
			existsDefaultOutput,
			newCommands
		);
	}

}

object QueryParser {

	def apply(queryCommandName: Option[String],
		inputOk: Boolean, outputOk: Boolean, existsDefaultInput: Boolean, existsDefaultOutput: Boolean) = {
		new QueryParser(queryCommandName, inputOk, outputOk, existsDefaultInput, existsDefaultOutput,
			inputPath = None, inputFormat = None, inputHeader = None,
			outputPath = None, outputFormat = None, outputHeader = None,
			commands = Nil, lastCommand = None);
	}

	val commands: Map[String, () => CommandParser] = Map(
		"paste" -> (() => PasteCommandParser(None)),
		"cut" -> (() => CutCommandParser(None)),
		"cutidx" -> (() => CutidxCommandParser(None)),
		"update" -> (() => UpdateCommandParser(None, None, None)),
		"wcl" -> (() => WclCommandParser()),
		"stridx" -> (() => StridxCommandParser())
	);

	private val HeaderArgPattern = "[_0-9a-zA-Z][-_0-9a-zA-Z,]*".r;

}

trait CommandParser {
	def eat(args: List[String]): Option[(CommandParser, List[String])];
	def createCommand(): Command;
	def eatFilePathPriority: Boolean = false;
}

//==================================================================================================

class GlobalTree (
	val query: QueryTree,
	val explain: Boolean
) {

	def checkStdin() {
		query.checkStdin();
	}
	def checkStdout() {
		query.checkStdout();
	}

	def stdin: Option[InputFormatWrapper] = query.stdin;
	def stdout: Option[OutputFormatWrapper] = query.stdout;

}

class QueryTree private (
	val inputFormatWrapper: Option[InputFormatWrapper],
	val outputFormatWrapper: Option[OutputFormatWrapper],
	existsDefaultInput: Boolean,
	existsDefaultOutput: Boolean,
	commands: List[Command]
) {

	def externalInputFormatWrapper: List[InputFormatWrapper] = {
		(inputFormatWrapper match {
			case Some(i) => i :: Nil;
			case _ => Nil;
		}) ::: commands.flatMap(_.externalInputFormatWrapper);
	}

	def checkStdin() {
		stdins match {
			case Nil => ;
			case o :: Nil => ;
			case _ => throw new UserException("multiple stdins");
		}
	}

	def checkStdout() {
		stdouts match {
			case Nil => ;
			case o :: Nil => ;
			case _ => throw new UserException("multiple stdouts");
		}
	}

	def stdin: Option[InputFormatWrapper] = {
		stdins match {
			case Nil => None;
			case i :: Nil => Some(i);
			case _ => throw new AssertionError();
		}
	}

	def stdout: Option[OutputFormatWrapper] = {
		stdouts match {
			case Nil => None;
			case o :: Nil => Some(o);
			case _ => throw new AssertionError();
		}
	}

	def stdins: List[InputFormatWrapper] = {
		(inputFormatWrapper match {
			case Some(i) => i.stdins;
			case None => Nil;
		}) ::: commands.flatMap(_.stdins);
	}

	def stdouts: List[OutputFormatWrapper] = {
		(outputFormatWrapper match {
			case Some(o) => o.stdouts;
			case None => Nil;
		}) ::: commands.flatMap(_.stdouts);
	}

	def createCommandLines(defaultInput: Option[InputResource], defaultOutput: Option[OutputResource]): List[CommandLine] = {
		//if (existsDefaultInput && defaultInput.isEmpty) {
		//	throw new AssertionError();
		//}
		//if (existsDefaultOutput && defaultOutput.isEmpty) {
		//	throw new AssertionError();
		//}
		if (!existsDefaultInput && defaultInput.isDefined) {
			throw new AssertionError();
		}
		if (!existsDefaultOutput && defaultOutput.isDefined) {
			throw new AssertionError();
		}

		val (in: InputResource, cmds1: List[Command]) = (inputFormatWrapper, defaultInput) match {
			case (Some(in), _) => in.toCommands;
			case (None, Some(in)) => (in, Nil);
			case (None, None) => (StdinResource(), Nil);
		}
		val (out: OutputResource, cmds2: List[Command]) = (outputFormatWrapper, defaultOutput) match {
			case (Some(out), _) => out.toCommands;
			case (None, Some(out)) => (out, Nil);
			case (None, None) => (StdoutResource(), Nil);
		}

		val commandsReversed = (cmds1 ::: commands ::: cmds2) match {
			case Nil => CatCommand() :: Nil;
			case cmds => cmds.reverse;
		}
		val last = commandsReversed.head;
		val middle = commandsReversed.tail.reverse;
		val (in2, sourcesReversed1, sourcesReversed2) = middle.foldLeft[(InputResource, List[CommandLine], List[CommandLine])]((in, Nil, Nil)) { (t, cmd) =>
			val (in3, sources1, sources2) = t;
			val fifo = GlobalParser.createFifo();
			val lines1 = fifo.createMkfifoCommandLines().reverse;
			val lines2 = cmd.createCommandLines(in3, fifo.o).reverse;
			(fifo.i, lines1 ::: sources1, lines2 ::: sources2);
		}
		val sources1 = sourcesReversed1.reverse;
		val sources2 = (last.createCommandLines(in2, out).reverse ::: sourcesReversed2).reverse;

		sources1 ::: sources2;
	}

}

object QueryTree {

	def create(
		input: Option[ExternalInputResourceFormat],
		output: Option[ExternalOutputResourceFormat],
		existsDefaultInput: Boolean,
		existsDefaultOutput: Boolean,
		commands: List[Command]
	): QueryTree = {
		val inputFormatWrapper: Option[InputFormatWrapper] = input match {
			case Some(input) => Some(GlobalParser.createInputFormatWrapper(input));
			case None => None;
		}
		val outputFormatWrapper: Option[OutputFormatWrapper] = output match {
			case Some(output) => Some(new OutputFormatWrapper(output));
			case None => None;
		}
		new QueryTree(inputFormatWrapper, outputFormatWrapper, existsDefaultInput, existsDefaultOutput, commands);
	}

}

trait Command {
	def externalInputFormatWrapper: List[InputFormatWrapper] = Nil;
	def stdins: List[InputFormatWrapper] = Nil;
	def stdouts: List[OutputFormatWrapper] = Nil;
	def createCommandLines(input: InputResource, output: OutputResource): List[CommandLine];
//	def output: OutputResource;
}

trait CommandExecutor {
	def exec(inputFilePath: String, outputFilePath: String);
}

//==================================================================================================

sealed trait CommandLineArgument {
	def toRaw: String;
	def toBash: String;
	def toDebug: String;
}
case class NormalArgument(arg: String) extends CommandLineArgument {
	def toRaw: String = arg;
	def toBash: String = escapeForBash(arg);
	def toDebug: String = escapeForBash(arg);
}
case class WorkingDirArgument(fname: String) extends CommandLineArgument {
	def toRaw: String = WORKING_DIR + "/" + fname;
	def toBash: String = escapeForBash(WORKING_DIR + "/" + fname);
	def toDebug: String = "$WORKING_DIR/" + escapeForBash(fname);
}
case class ToolDirArgument(fname: String) extends CommandLineArgument {
	def toRaw: String = TOOL_DIR + "/" + fname;
	def toBash: String = escapeForBash(TOOL_DIR + "/" + fname);
	def toDebug: String = "$TOOL_DIR/" + escapeForBash(fname);
}

sealed trait CommandLine {
	def toBash: Option[String];
	def toDebug: String;
	def execute();
}

case class CommandLineImpl(args: List[CommandLineArgument],
	in: Option[CommandLineArgument], out: Option[CommandLineArgument],
	background: Boolean, debug: String) extends CommandLine {

	def toBash: Option[String] = {
		val raw = args.map(_.toBash).mkString(" ") +
			(in match {
				case Some(in) => " < " + in.toBash;
				case None => "";
			}) +
			(out match {
				case Some(out) => " > " + out.toBash;
				case None => "";
			}) +
			(if (background) " &" else "");
		Some(raw);
	}
	def toDebug: String = {
		if (args.isEmpty && debug.isEmpty) {
			"";
		} else {
			val c = args.map(_.toDebug).mkString(" ") +
				(in match {
					case Some(in) => " < " + in.toDebug;
					case None => "";
				}) +
				(out match {
					case Some(out) => " > " + out.toDebug;
					case None => "";
				}) +
				(if (background) " &" else "");
			val maxLen = 110;
			val sep = if (c.length < maxLen) {
				" " * (maxLen - c.length);
			} else {
				"    ";
			}
			c + sep + "# " + debug;
		}
	}

	def execute() {}
}

case class JvmCommandLine (executor: CommandExecutor,
	in: CommandLineArgument, out: CommandLineArgument,
	debug: String) extends CommandLine {

	def toBash: Option[String] = None;

	def toDebug: String = {
		val c = "#jvm: " + executor.toString +
			" < " + in.toDebug +
			" > " + out.toDebug +
			" &";
		val maxLen = 110;
		val sep = if (c.length < maxLen) {
			" " * (maxLen - c.length);
		} else {
			"    ";
		}
		c + sep + "# " + debug;
	}

	def execute() {
		(new Thread(new Runnable() {
			def run() {
				executor.exec(in.toRaw, out.toRaw);
			}
		})).start();
	}
}

//==================================================================================================

sealed trait InputFileFormat;
sealed trait OutputFileFormat;
sealed trait FileFormat extends InputFileFormat with OutputFileFormat;
case object TsvFileFormat extends FileFormat;
case object CsvFileFormat extends FileFormat;
case object LtsvFileFormat extends InputFileFormat;
case object TableFileFormat extends OutputFileFormat;
case object DiffableFileFormat extends OutputFileFormat;

sealed trait NewLineFormat;
case object UnixNewLineFormat extends NewLineFormat;
case object DosNewLineFormat extends NewLineFormat;
case object MacNewLineFormat extends NewLineFormat;

sealed trait CharEncoding;
case object UTF8CharEncoding extends CharEncoding;
case object SJISCharEncoding extends CharEncoding;

//==================================================================================================

sealed trait InputResource {
	def arg: CommandLineArgument;
	def numberForDebug: String;
}

sealed trait ExternalInputResource extends InputResource;

case class StdinResource() extends ExternalInputResource {
	def arg: CommandLineArgument = WorkingDirArgument("stdin");
	def numberForDebug: String = "-";
}

object StdinResource {
	var isInputTty: Boolean = false;
}

case class FileInputResource(path: String) extends ExternalInputResource {
	def arg: CommandLineArgument = NormalArgument(path);
	def numberForDebug: String = "x";
}

case class FifoInputResource(resource: FifoResource) extends InputResource {
	def arg: CommandLineArgument = resource.arg;
	def numberForDebug: String = resource.id.toString;
	def createMkfifoCommandLines(): List[CommandLine] = resource.createMkfifoCommandLines();
}

sealed trait OutputResource {
	def arg: CommandLineArgument;
	def numberForDebug: String;
}

sealed trait ExternalOutputResource extends OutputResource;

case class NullOutputResource() extends ExternalOutputResource {
	def arg: CommandLineArgument = NormalArgument("/dev/null");
	def numberForDebug: String = "n";
}

case class StdoutResource() extends ExternalOutputResource {
	def arg: CommandLineArgument = WorkingDirArgument("stdout");
	def numberForDebug: String = "-";
}

object StdoutResource {
	var isOutputTty: Boolean = false;
}

case class FileOutputResource(path: String) extends ExternalOutputResource {
	def arg: CommandLineArgument = NormalArgument(path);
	def numberForDebug: String = "x";
}

case class FifoOutputResource(resource: FifoResource) extends OutputResource {
	def arg: CommandLineArgument = resource.arg;
	def numberForDebug: String = resource.id.toString;
	def createMkfifoCommandLines(): List[CommandLine] = resource.createMkfifoCommandLines();
}

case class FifoResource(id: Int) {
	def path: String = WORKING_DIR + "/pipe_" + id;
	def arg: CommandLineArgument = WorkingDirArgument("pipe_" + id);

	val i = FifoInputResource(this);
	val o = FifoOutputResource(this);

	def createMkfifoCommandLines(): List[CommandLine] = {
		if (GlobalParser.createMkfifoCommandLines(id)) {
			CommandLineImpl(NormalArgument("mkfifo") :: arg :: Nil,
				None, None, false, "mkfifo " + id) :: Nil;
		} else {
			Nil;
		}
	}
}

//==================================================================================================

case class ExternalInputResourceFormat (
	input: ExternalInputResource,
	format: Option[InputFileFormat],
	inputHeader: Option[List[String]]);

case class ExternalOutputResourceFormat (
	output: ExternalOutputResource,
	format: Option[OutputFileFormat],
	outputHeader: Boolean);

//==================================================================================================

class InputFormatWrapper (
	private[this] val input: ExternalInputResourceFormat,
	private[this] val resultFifo: FifoResource,
	private[this] val streamFifo: FifoResource
) {

	def stdins: List[InputFormatWrapper] = {
		input.input match {
			case StdinResource() => this :: Nil;
			case _ => Nil;
		}
	}

	def toWrapperCommandLines: List[CommandLine] = {
		val formatOpt: List[CommandLineArgument] = input.format match {
			case Some(TsvFileFormat) => NormalArgument("--tsv") :: Nil;
			case Some(CsvFileFormat) => NormalArgument("--csv") :: Nil;
			case Some(LtsvFileFormat) =>
				if (input.inputHeader.isEmpty) {
					throw new AssertionError();
				}
				NormalArgument("--ltsv") :: Nil;
			case None => Nil;
		}
		val command = CommandLineImpl(NormalArgument("perl") :: ToolDirArgument("format-wrapper.pl") ::
			formatOpt ::: resultFifo.arg ::
			NormalArgument("-i") :: input.input.arg :: NormalArgument("-o") :: streamFifo.arg :: Nil,
			None, None, true, commandLineIOStringForDebug(input.input, streamFifo.o));

		resultFifo.createMkfifoCommandLines() :::
		streamFifo.createMkfifoCommandLines() :::
		command :: Nil;
	}

	def toCommands: (InputResource, List[Command]) = {
		val resultLine = readResultFile();
		val result = InputFormatWrapper.parseResultString(resultLine);
		toCommandsSub(result);
	}

	private[this] def readResultFile(): String = {
		val source = scala.io.Source.fromFile(resultFifo.path);
		val it = source.getLines;
		if (!it.hasNext) {
			throw new Exception("Cannot parse result of format-wrapper");
		}
		val line = it.next;
		source.close();
		line;
	}

	private[this] def toCommandsSub(result: InputFormatWrapperResult): (InputResource, List[Command]) = {
		if (result.isFileMode) {
			val cmds = InputFormatWrapper.toCommandsSub(
				result.fileFormat, result.charEncoding, result.utf8bom, result.newline, input.inputHeader);
			(input.input, cmds);
		} else {
			val cmds = InputFormatWrapper.toCommandsSub(
				result.fileFormat, result.charEncoding, result.utf8bom, result.newline, input.inputHeader);
			(streamFifo.i, cmds);
		}
	}

}

object InputFormatWrapper {

	private val ResultPattern = "format:([^ ]+) charencoding:([^ ]+) utf8bom:([^ ]+) newline:([^ ]+) mode:([^ ]+)".r;

	private def parseResultString(line: String): InputFormatWrapperResult = {
		line match {
			case ResultPattern(format, charencoding, utf8bom, newline, mode) =>
				val format2 = format match {
					case "tsv" => TsvFileFormat;
					case "csv" => CsvFileFormat;
					case "ltsv" => LtsvFileFormat;
					case _ => throw new Exception("Cannot parse result of format-wrapper");
				}
				val charencoding2 = charencoding match {
					case "UTF-8" => UTF8CharEncoding;
					case "SHIFT-JIS" => SJISCharEncoding;
					case _ => throw new Exception("Cannot parse result of format-wrapper");
				}
				val isUtf8bom = utf8bom match {
					case "0" => false;
					case "1" => true;
					case _ => throw new Exception("Cannot parse result of format-wrapper");
				}
				val newline2 = newline match {
					case "unix" => UnixNewLineFormat;
					case "dos" => DosNewLineFormat;
					case "mac" => MacNewLineFormat
					case _ => throw new Exception("Cannot parse result of format-wrapper");
				}
				val isFileMode = mode match {
					case "file" => true;
					case "pipe" => false;
					case _ => throw new Exception("Cannot parse result of format-wrapper");
				}
				val result = InputFormatWrapperResult(format2, charencoding2, isUtf8bom, newline2, isFileMode);
				result;
			case _ =>
				throw new Exception("Cannot parse result of format-wrapper");
		}
	}

	private def toCommandsSub(
		fileFormat: InputFileFormat,
		charEncoding: CharEncoding,
		utf8bom: Boolean,
		newline: NewLineFormat,
		inputHeader: Option[List[String]]
	): List[Command] = {
		val commands1 = toCommandsUTF8BOM(utf8bom);
		val commands2 = toCommandsCharEncoding(charEncoding);
		val commands3 = toCommandsNewLine(newline, fileFormat);
		val commands4 = toCommandsFileFormat(fileFormat, inputHeader);
		val commands5 = toCommandsHeader(inputHeader);
		commands1 ::: commands2 ::: commands3 ::: commands4 ::: commands5 ::: Nil;
	}

	private def toCommandsUTF8BOM(utf8bom: Boolean): List[Command] = {
		if (utf8bom) {
			UTF8BomTrimmerCommand() :: Nil;
		} else {
			Nil;
		}
	}

	private def toCommandsCharEncoding(charEncoding: CharEncoding): List[Command] = {
		if (charEncoding != UTF8CharEncoding) {
			CharEncodingInputConverterCommand( charEncoding) :: Nil;
		} else {
			Nil;
		}
	}

	private def toCommandsNewLine(newline: NewLineFormat, fileFormat: InputFileFormat): List[Command] = {
		if (newline == DosNewLineFormat && fileFormat == CsvFileFormat) {
			DosNewLineToUnixCommand() :: Nil;
		} else if (newline == MacNewLineFormat) {
			MacNewLineToUnixCommand() :: Nil;
		} else {
			Nil;
		}
	}

	private def toCommandsFileFormat(fileFormat: InputFileFormat, inputHeader: Option[List[String]]): List[Command] = {
		fileFormat match {
			case TsvFileFormat =>
				Nil;
			case CsvFileFormat =>
				CsvToTsvCommand() :: Nil;
			case LtsvFileFormat =>
				LtsvToTsvCommand(inputHeader.get) :: Nil;
		}
	}

	private def toCommandsHeader(inputHeader: Option[List[String]]): List[Command] = {
		inputHeader match {
			case Some(inputHeader) => AddHeaderCommand(inputHeader) :: Nil;
			case None => Nil;
		}
	}

}

case class InputFormatWrapperResult (
	fileFormat: InputFileFormat,
	charEncoding: CharEncoding,
	utf8bom: Boolean,
	newline: NewLineFormat,
	isFileMode: Boolean
);

case class CharEncodingInputConverterCommand (charEncoding: CharEncoding) extends Command {

	def createCommandLines(input: InputResource, output: OutputResource): List[CommandLine] = {
		charEncoding match {
			case UTF8CharEncoding =>
				CommandLineImpl(NormalArgument("cat") :: Nil,
					Some(input.arg), Some(output.arg), true, commandLineIOStringForDebug(input, output)) :: Nil;
			case SJISCharEncoding =>
				CommandLineImpl(("iconv" :: "-f" :: "SHIFT-JIS" :: "-t" :: "UTF-8//TRANSLIT" :: Nil).map(NormalArgument),
					Some(input.arg), Some(output.arg), true, commandLineIOStringForDebug(input, output)) :: Nil;
		}
	}

}

case class UTF8BomTrimmerCommand () extends Command {

	def createCommandLines(input: InputResource, output: OutputResource): List[CommandLine] = {
		CommandLineImpl(("tail" :: "-c+4" :: Nil).map(NormalArgument),
			Some(input.arg), Some(output.arg), true, commandLineIOStringForDebug(input, output)) :: Nil;
	}

}

case class DosNewLineToUnixCommand () extends Command {

	def createCommandLines(input: InputResource, output: OutputResource): List[CommandLine] = {
		CommandLineImpl(("sed" :: "s/\\r$//g" :: Nil).map(NormalArgument),
			Some(input.arg), Some(output.arg), true, commandLineIOStringForDebug(input, output)) :: Nil;
	}

}

case class MacNewLineToUnixCommand () extends Command {

	def createCommandLines(input: InputResource, output: OutputResource): List[CommandLine] = {
		CommandLineImpl(("sed" :: "s/\\r$/\\n/g" :: Nil).map(NormalArgument),
			Some(input.arg), Some(output.arg), true, commandLineIOStringForDebug(input, output)) :: Nil;
	}

}

case class CsvToTsvCommand () extends Command {

	def createCommandLines(input: InputResource, output: OutputResource): List[CommandLine] = {
		CommandLineImpl(ToolDirArgument("golang.bin") :: NormalArgument("csv2tsv") :: Nil,
			Some(input.arg), Some(output.arg), true, commandLineIOStringForDebug(input, output)) :: Nil;
	}

}

case class LtsvToTsvCommand (cols: List[String]) extends Command {

	def createCommandLines(input: InputResource, output: OutputResource): List[CommandLine] = {
		CommandLineImpl(NormalArgument("perl") :: ToolDirArgument("ltsv2tsv.pl") :: NormalArgument("--header") :: NormalArgument(cols.mkString(",")) :: Nil,
			Some(input.arg), Some(output.arg), true, commandLineIOStringForDebug(input, output)) :: Nil;
	}

}

case class AddHeaderCommand(cols: List[String]) extends Command {

	def createCommandLines(input: InputResource, output: OutputResource): List[CommandLine] = {
		CommandLineImpl(NormalArgument("bash") :: ToolDirArgument("add-header.sh") :: NormalArgument(cols.mkString("\\t")) :: Nil,
			Some(input.arg), Some(output.arg), true, commandLineIOStringForDebug(input, output)) :: Nil;
	}

}

//==================================================================================================

class OutputFormatWrapper (
	private[this] val output: ExternalOutputResourceFormat
) {

	def stdouts: List[OutputFormatWrapper] = {
		output.output match {
			case StdoutResource() => this :: Nil;
			case _ => Nil;
		}
	}

	def toCommands: (OutputResource, List[Command]) = (output.output, commandImpl._1);

	def isPager: Boolean = commandImpl._2;

	private[this] val commandImpl = toCommandImpl;

	private[this] def toCommandImpl: (List[Command], Boolean) = {
		output match {
			case ExternalOutputResourceFormat(StdoutResource(), _, _) if StdoutResource.isOutputTty =>
				//val commands1 = output.outputHeader match {
				//	case false => NoHeaderCommand() :: Nil;
				//	case true => Nil;
				//}
				val commands2 = output.format match {
					case Some(TsvFileFormat) => Nil;
					case Some(CsvFileFormat) => TsvToCsvCommand() :: Nil;
					case Some(TableFileFormat) => TsvToTableCommand(true) :: Nil;
					case Some(DiffableFileFormat) => TsvToDiffableCommand() :: Nil;
					case None => TsvToTableCommand(true) :: Nil;
				}
				val commands3 = LessCommand() :: Nil;
				(commands2 ::: commands3, true);
			case _ =>
				val commands1 = output.format match {
					case Some(TsvFileFormat) => Nil;
					case Some(CsvFileFormat) => TsvToCsvCommand() :: Nil;
					case Some(TableFileFormat) => TsvToTableCommand(false) :: Nil;
					case Some(DiffableFileFormat) => TsvToDiffableCommand() :: Nil;
					case None => Nil;
				}
				val commands2 = output.outputHeader match {
					case false => NoHeaderCommand() :: Nil;
					case true => Nil;
				}
				(commands1 ::: commands2, false);
		}
	}

}

case class TsvToCsvCommand() extends Command {

	def createCommandLines(input: InputResource, output: OutputResource): List[CommandLine] = {
		CommandLineImpl(NormalArgument("perl") :: ToolDirArgument("to-csv.pl") :: Nil,
			Some(input.arg), Some(output.arg), true, commandLineIOStringForDebug(input, output)) :: Nil;
	}

}

case class TsvToTableCommand(isColor: Boolean) extends Command {

	def createCommandLines(input: InputResource, output: OutputResource): List[CommandLine] = {
		val options = if (isColor) {
			"--color" :: Nil;
		} else {
			Nil;
		}
		CommandLineImpl(NormalArgument("perl") :: ToolDirArgument("table.pl") :: options.map(NormalArgument),
			Some(input.arg), Some(output.arg), true, commandLineIOStringForDebug(input, output)) :: Nil;
	}

}

case class TsvToDiffableCommand() extends Command {

	def createCommandLines(input: InputResource, output: OutputResource): List[CommandLine] = {
		CommandLineImpl(NormalArgument("perl") :: ToolDirArgument("to-diffable.pl") :: Nil,
			Some(input.arg), Some(output.arg), true, commandLineIOStringForDebug(input, output)) :: Nil;
	}

}

case class NoHeaderCommand() extends Command {

	def createCommandLines(input: InputResource, output: OutputResource): List[CommandLine] = {
		CommandLineImpl(NormalArgument("tail") :: NormalArgument("-n+2") :: Nil,
			Some(input.arg), Some(output.arg), true, commandLineIOStringForDebug(input, output)) :: Nil;
	}

}

case class LessCommand() extends Command {

	def createCommandLines(input: InputResource, output: OutputResource): List[CommandLine] = {
		CommandLineImpl(NormalArgument("less") :: NormalArgument("-SRX") :: Nil,
			Some(input.arg), None, false, commandLineIOStringForDebug(Some(input), None)) :: Nil;
	}

}

//==================================================================================================

case class CatCommand (
) extends Command {

	def createCommandLines(input: InputResource, output: OutputResource): List[CommandLine] = {
		CommandLineImpl(NormalArgument("cat") :: Nil,
			Some(input.arg), Some(output.arg), true, commandLineIOStringForDebug(input, output)) :: Nil;
	}

}

//==================================================================================================

object TeeCommand {
	def createCommandLines(input: InputResource, outputs: List[OutputResource]): List[CommandLine] = {
		outputs match {
			case Nil =>
				val output = NullOutputResource();
				CommandLineImpl(NormalArgument("cat") :: Nil,
					Some(input.arg), Some(output.arg), true, commandLineIOStringForDebug(input, output)) :: Nil;
			case head :: Nil =>
				CommandLineImpl(NormalArgument("cat") :: Nil,
					Some(input.arg), Some(head.arg), true, commandLineIOStringForDebug(input, head)) :: Nil;
			case head :: tail =>
				val debugs = (tail ::: head :: Nil).map(o => commandLineIOStringForDebug(input, o));
				val debug = debugs.head;
				val debugTail = debugs.tail.map(CommandLineImpl(Nil, None, None, false, _));

				val command = CommandLineImpl(NormalArgument("tee") :: tail.map(_.arg) ::: Nil,
					Some(input.arg), Some(head.arg), true, debug);

				command :: debugTail ::: Nil;
		}
	}

}

//==================================================================================================

case class PasteCommandParser (
	anotherInput: Option[Either[String, (QueryParser, Boolean)]]
) extends CommandParser {

	def eat(args: List[String]): Option[(CommandParser, List[String])] = {
		anotherInput match {
			case Some(Right((q, false))) =>
				val (subQuery2, tail, isClosed) = q.eat(args);
				Some((this.copy(anotherInput = Some(Right((subQuery2, isClosed)))), tail));
			case _ =>
				args match {
					case "[" :: tail =>
						anotherInput match {
							case None =>
								Some((this.copy(anotherInput = Some(Right((QueryParser(Some("paste"), true, false, true, true), false)))), tail));
							case _ =>
								throw new UserException("duplicated option: " + args.head);
						}
					case "--file" :: a :: tail =>
						anotherInput match {
							case None =>
								if (!(new java.io.File(a)).exists) {
									throw new UserException("File not found: " + a);
								}
								Some((this.copy(anotherInput = Some(Left(a))), tail));
							case _ =>
								throw new UserException("duplicated option: " + args.head);
						}
					case a :: tail if (!a.matches("-.*") && anotherInput.isEmpty && (new java.io.File(a)).exists) =>
						Some((this.copy(anotherInput = Some(Left(a))), tail));
					case _ =>
						None;
				}
		}
	}

	def createCommand(): Command = {
		val anotherInput2 = anotherInput match {
			case Some(Left(path)) =>
				QueryTree.create(
					input = Some(ExternalInputResourceFormat(FileInputResource(path), None, None)),
					output = None,
					existsDefaultInput = true, existsDefaultOutput = true, commands = Nil);
			case Some(Right((q, _))) =>
				q.createTree();
			case None =>
				throw new UserException("subcommand `paste` needs --file option");
		}
		PasteCommand(anotherInput2);
	}

	override def eatFilePathPriority: Boolean = true;

}

case class PasteCommand (
	anotherInput: QueryTree
) extends Command {

	override def externalInputFormatWrapper: List[InputFormatWrapper] = {
		anotherInput.externalInputFormatWrapper;
	}

	override def stdins: List[InputFormatWrapper] = {
		anotherInput.stdins;
	}

	def createCommandLines(input: InputResource, output: OutputResource): List[CommandLine] = {
		val empty = ParserMain.emptyCommandLine;

		anotherInput.inputFormatWrapper match {
			case Some(_) =>
				val fifo2 = GlobalParser.createFifo();
				val cmds1 = fifo2.createMkfifoCommandLines();

				val cmds2 = anotherInput.createCommandLines(None, Some(fifo2.o));

				val option = NormalArgument("--right") :: fifo2.i.arg :: Nil;
				val command = CommandLineImpl(NormalArgument("perl") :: ToolDirArgument("paste.pl") :: option ::: Nil,
					Some(input.arg), Some(output.arg), true, commandLineIOStringForDebug(input, output));

				empty :: cmds1 ::: empty :: cmds2 ::: empty ::
				command ::
				CommandLineImpl(Nil, None, None, false, commandLineIOStringForDebug(fifo2.i, output)) :: Nil;
			case None =>
				val fifo1 = GlobalParser.createFifo();
				val fifo2 = GlobalParser.createFifo();
				val fifo3 = GlobalParser.createFifo();
				val cmds1 = fifo1.createMkfifoCommandLines() ::: fifo2.createMkfifoCommandLines() ::: fifo3.createMkfifoCommandLines();

				val cmds2 = TeeCommand.createCommandLines(input, fifo3.o :: fifo1.o :: Nil);
				val cmds3 = anotherInput.createCommandLines(Some(fifo1.i), Some(fifo2.o));

				val option = NormalArgument("--right") :: fifo2.i.arg :: Nil;
				val command = CommandLineImpl(NormalArgument("perl") :: ToolDirArgument("paste.pl") :: option ::: Nil,
					Some(fifo3.i.arg), Some(output.arg), true, commandLineIOStringForDebug(fifo3.i, output));

				empty :: cmds1 ::: cmds2 ::: empty :: cmds3 ::: empty ::
				command ::
				CommandLineImpl(Nil, None, None, false, commandLineIOStringForDebug(fifo2.i, output)) :: Nil;
		}
	}

}

//==================================================================================================

case class CutCommandParser (
	columns: Option[List[String]]
) extends CommandParser {

	def eat(args: List[String]): Option[(CommandParser, List[String])] = {
		args match {
			case opt :: arg :: tail if (opt == "--col" || opt == "--cols" || opt == "columns") =>
				columns match {
					case Some(_) => throw new UserException("duplicated option: " + args.head);
					case None => Some((updateCols(arg), tail));
				}
			case opt :: Nil if (opt == "--col" || opt == "--cols" || opt == "columns") =>
				throw new UserException("option " + args.head + " needs an argument");
			case GlobalParser.OptionPattern() :: tail =>
				None;
			case arg :: tail if (columns.isEmpty) =>
				Some((updateCols(arg), tail));
			case _ =>
				None;
		}
	}

	private[this] def updateCols(arg: String): CutCommandParser = {
		val cols = arg.split(",", -1).toList;
		this.copy(columns = Some(cols));
	}

	def createCommand(): Command = {
		CutCommand(columns.getOrElse(Nil));
	}

}

case class CutCommand (
	columns: List[String]
) extends Command {

	def createCommandLines(input: InputResource, output: OutputResource): List[CommandLine] = {
		val option = NormalArgument("--col") :: NormalArgument(columns.mkString(",")) :: Nil;
		CommandLineImpl(NormalArgument("perl") :: ToolDirArgument("cut.pl") :: option,
			Some(input.arg), Some(output.arg), true, commandLineIOStringForDebug(input, output)) :: Nil;
	}

}

//==================================================================================================

case class CutidxCommandParser (
	column: Option[String]
) extends CommandParser {

	def eat(args: List[String]): Option[(CommandParser, List[String])] = {
		args match {
			case "--col" :: arg :: tail =>
				column match {
					case Some(_) => throw new UserException("duplicated option: " + args.head);
					case None => Some((this.copy(column = Some(arg)), tail));
				}
			case "--col" :: Nil =>
				throw new UserException("option " + args.head + " needs an argument");
			case GlobalParser.OptionPattern() :: tail =>
				None;
			case arg :: tail if (column.isEmpty) =>
				Some((this.copy(column = Some(arg)), tail));
			case _ =>
				None;
		}
	}

	def createCommand(): Command = {
		column match {
			case Some(column) =>
				CutidxCommand(column);
			case None =>
				throw new UserException("subcommand `cutidx` needs --col option");
		}
	}

}

case class CutidxCommand (
	column: String
) extends Command {

	def createCommandLines(input: InputResource, output: OutputResource): List[CommandLine] = {
		val option = NormalArgument("--col") :: NormalArgument(column) :: Nil;
		CommandLineImpl(NormalArgument("perl") :: ToolDirArgument("cutidx.pl") :: option,
			Some(input.arg), Some(output.arg), true, commandLineIOStringForDebug(input, output)) :: Nil;
	}

}

//==================================================================================================

case class UpdateCommandParser (
	index: Option[Int],
	col: Option[String],
	value: Option[String]
) extends CommandParser {

	def eat(args: List[String]): Option[(CommandParser, List[String])] = {
		args match {
			case "--index" :: arg :: tail =>
				index match {
					case Some(_) => throw new UserException("duplicated option: " + args.head);
					case None =>
						val a = try {
							arg.toInt;
						} catch { case e: NumberFormatException =>
							throw new UserException("Illegal argument of " + args.head + ": " + arg);
						}
						if (a < 0) {
							throw new UserException("Illegal argument of " + args.head + ": " + arg);
						}
						Some((this.copy(index = Some(a)), tail));
				}
			case "--index" :: Nil =>
				throw new UserException("option " + args.head + " needs an argument");
			case "--col" :: (arg @GlobalParser.ColumnNamePattern()) :: tail =>
				index match {
					case Some(_) => throw new UserException("duplicated option: " + args.head);
					case None => Some((this.copy(col = Some(arg)), tail));
				}
			case "--col" :: arg :: Nil =>
				throw new UserException("Illegal argument of " + args.head + ": " + arg);
			case "--col" :: Nil =>
				throw new UserException("option " + args.head + " needs an argument");
			case "--value" :: arg :: tail =>
				index match {
					case Some(_) => throw new UserException("duplicated option: " + args.head);
					case None => Some((this.copy(value = Some(arg)), tail));
				}
			case "--value" :: Nil =>
				throw new UserException("option " + args.head + " needs an argument");
			case GlobalParser.OptionPattern() :: tail =>
				None;
			case arg :: tail if (index.isEmpty) =>
				val a = try {
					arg.toInt;
				} catch { case e: NumberFormatException =>
					-1;
				}
				if (a < 0) {
					None;
				} else {
					Some((this.copy(index = Some(a)), tail));
				}
			case (arg @GlobalParser.ColumnNamePattern()) :: tail if (col.isEmpty) =>
				Some((this.copy(col = Some(arg)), tail));
			case arg :: tail if (col.isEmpty) =>
				None;
			case arg :: tail if (value.isEmpty) =>
				Some((this.copy(value = Some(arg)), tail));
			case _ =>
				None;
		}
	}

	def createCommand(): Command = {
		(index, col, value) match {
			case (None, _, _) => throw new UserException("subcommand `update` needs --index option");
			case (Some(_), None, _) => throw new UserException("subcommand `update` needs --col option");
			case (Some(_), Some(_), None) => throw new UserException("subcommand `update` needs --value option");
			case (Some(i), Some(c), Some(v)) => UpdateCommand(UpdateContent(i, c, v) :: Nil);
		}
	}

}

case class UpdateContent (index: Int, col: String, value: String);

case class UpdateCommand (content: List[UpdateContent]) extends Command {

	def createCommandLines(input: InputResource, output: OutputResource): List[CommandLine] = {
		val contents = content.map { content =>
			NormalArgument(content.index + ":" + content.col + "=" + content.value);
		}
		CommandLineImpl(NormalArgument("perl") :: ToolDirArgument("update.pl") :: contents,
			Some(input.arg), Some(output.arg), true, commandLineIOStringForDebug(input, output)) :: Nil;
	}

}

//==================================================================================================

case class WclCommandParser (
) extends CommandParser {

	def eat(args: List[String]): Option[(CommandParser, List[String])] = {
		None;
	}

	def createCommand(): Command = {
		WclCommand();
	}

}

case class WclCommand () extends Command {

	def createCommandLines(input: InputResource, output: OutputResource): List[CommandLine] = {
		CommandLineImpl(ToolDirArgument("golang.bin") :: NormalArgument("wcl") :: NormalArgument("--header") :: Nil,
			Some(input.arg), Some(output.arg), true, commandLineIOStringForDebug(input, output)) :: Nil;
	}

}

//==================================================================================================

class ParserMain (tree: GlobalTree) {

	def exec() {
		if (tree.stdin.isDefined) {
			putCommand("--stdin");
		}
		if (tree.stdout.isDefined) {
			putCommand("--stdout");
		}

		val inputs: List[InputFormatWrapper] = tree.query.externalInputFormatWrapper;

		inputs.foreach { i =>
			i.toWrapperCommandLines.foreach { commandLine =>
				putCommand(commandLine);
			}
			putCommand(emptyCommandLine);
		}

		tree.query.createCommandLines(None, None).foreach { commandLine =>
			putCommand(commandLine);
		}
		putCommand(emptyCommandLine);

		if (tree.stdout.map(_.isPager).getOrElse(false)) {
			// use less command
		} else {
			putCommand("wait");
		}
	}

	val reader = new java.io.BufferedReader(new java.io.InputStreamReader(System.in, "UTF-8"));

	private def putCommand(command: String) {
		putCommand(CommandLineImpl(NormalArgument(command) :: Nil, None, None, false, ""));
	}

	private def putCommand(line: CommandLine) {
		line.execute();

		val rawOpt = line.toBash;
		rawOpt match {
			case Some(raw) => println(raw);
			case None => ;
		}
		if (tree.explain) {
			System.err.println(line.toDebug);
		}

		rawOpt match {
			case Some("wait") => return;
			case None => return;
			case _ => ;
		}

		val result = reader.readLine();
		if (result == null) {
			throw new NullPointerException();
		}
	}

}

object ParserMain {

	def main(args: List[String]) {
		try {
			val parser: GlobalParser = GlobalParser.parse(args);
			val tree: GlobalTree = parser.createTree();
			val main = new ParserMain(tree);
			tree.checkStdin();
			tree.checkStdout();
			main.exec();
		} catch {
			case e: UserException =>
				System.err.println(e.getMessage);
				throw e;
		}
	}

	val TOOL_DIR: String = System.getenv("TOOL_DIR");
	val WORKING_DIR: String = System.getenv("WORKING_DIR");

	val emptyCommandLine = CommandLineImpl(Nil, None, None, false, "");

	def commandLineIOStringForDebug(input: InputResource, output: OutputResource): String = {
		input.numberForDebug + " -> " + output.numberForDebug;
	}

	def commandLineIOStringForDebug(input: Option[InputResource], output: Option[OutputResource]): String = {
		input.map(_.numberForDebug).getOrElse(" ") + " -> " + output.map(_.numberForDebug).getOrElse(" ");
	}

	def escapeForBash(s: String): String = {
		if (s.matches("[-_./a-zA-Z0-9]+")) {
			s;
		} else {
			"'" + s.replaceAll("'", "'\\''") + "'";
		}
	}

}

