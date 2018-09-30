
case class FilterCommandParser (
	column: Option[String],
	operator: Option[String],
	value: Option[String]
) extends CommandParser {

	def eat(args: List[String]): Option[(CommandParser, List[String])] = {
		import GlobalParser.ColumnNamePattern;
		import FilterCommandParser._;

		args match {
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

	def createCommand(): Command = {
		(column, operator, value) match {
			case (Some(column), Some(operator), Some(value)) =>
				FilterCommand(column, operator, value);
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

