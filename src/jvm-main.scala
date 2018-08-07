
import scala.io.Source;

object Main {

	def main(args: Array[String]) {
		args.toList match {
			case Nil =>
				throw new IllegalArgumentException();
			case "--facetcount" :: tail =>
				FacetCount.main(tail);
			case _ =>
				throw new IllegalArgumentException(args.reverse.mkString(" "));
		}
	}

}



trait PipeHead {

	def head(cols: Seq[String]): PipeBody;

}

trait PipeBody {

	def next(cols: Seq[String]): PipeBody;

	def close();

}

object StdoutPipeHead extends PipeHead {

	def head(cols: Seq[String]): PipeBody = {
		System.out.print(cols.mkString("\t") + "\n");
		StdoutPipeBody;
	}

}

object StdoutPipeBody extends PipeBody {

	def next(cols: Seq[String]): PipeBody = {
		System.out.println(cols.mkString("\t"));
		this;
	}

	def close() {
		System.out.close();
	}

}

sealed trait MultiValueFlag;
object MultiValueFlag {
	def apply(flag: String): Option[MultiValueFlag] = {
		flag match {
			case "a" => Some(MultiValueA);
			case "b" => Some(MultiValueB);
			case "" => None;
			case _ => throw new Error("flag: '" + flag + "'");
		}
	}
}
object MultiValueA extends MultiValueFlag;
object MultiValueB extends MultiValueFlag;

object WeightFlag {
	def apply(flag: String): Boolean = {
		flag match {
			case "weight" => true;
			case "no-weight" => false;
			case _ => throw new Error("flag: '" + flag + "'");
		}
	}
}

object Util {

	def valuesFromCol(col: String, multiValueFlag: Option[MultiValueFlag]): Iterable[String] = {
		multiValueFlag match {
			case Some(MultiValueA) =>
				col.split(";", -1).toSet.filter(!_.isEmpty);
			case Some(MultiValueB) =>
				throw new Error();
			case None =>
				Some(col);
		}
	}

	def doubleToString(x: Double): String = {
		"%f".format(x).replaceAll("(\\.[0-9]*?)0+\\z", "$1").replaceAll("\\.0*\\z", "");
	}

	def percentToString(x: Double): String = {
		"%6.2f%%".format(x * 100);
	}

}

