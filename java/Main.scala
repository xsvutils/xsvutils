
import scala.io.Source;

object Main {

	def main(args: Array[String]) {
		val pipeHead = buildPipe(args.toList);

		val lines = Source.fromInputStream(System.in).getLines;
		if (!lines.hasNext) {
			throw new Exception("Empty file");
		}

		val (pipeBody, colCount) = {
			val line = lines.next();
			val cols: Array[String] = line.split("\t", -1);
			(pipeHead.head(cols), cols.size);
		}

		val pipeClose = lines.foldLeft(pipeBody) { (pipeBody, line) =>
			val cols: Array[String] = {
				val cols: Array[String] = line.split("\t", -1);
				val size = cols.size;
				if (colCount == size) {
					cols;
				} else if (colCount < size) {
					cols.slice(0, colCount);
				} else {
					val cols2 = new Array[String](colCount);
					System.arraycopy(cols, 0, cols2, 0, size);
					(size until colCount).foreach { i =>
						cols2(i) = "";
					}
					cols2;
				}
			}
			pipeBody.next(cols);
		}

		pipeClose.close();
	}

	private def buildPipe(args: List[String]): PipeHead = {
		@scala.annotation.tailrec
		def sub(args: List[String], out: PipeHead): PipeHead = {
			args match {
				case Nil =>
					out;
				case weightFlag :: multiValueFlag :: "facetcount" :: tail =>
					sub(tail, FacetCountHead(MultiValueFlag(multiValueFlag), WeightFlag(weightFlag), out));
				case _ =>
					throw new Error(args.reverse.mkString(" "));
			}
		}
		sub(args.reverse, StdoutPipeHead);
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

	def doubleToString(x: Double): String = {
		"%f".format(x).replaceAll("(\\.[0-9]*?)0+\\z", "$1").replaceAll("\\.0*\\z", "");
	}

	def percentToString(x: Double): String = {
		"%6.2f%%".format(x * 100);
	}

}

