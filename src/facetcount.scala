
// このソースコードが実装している機能はいったん廃止されました。
// このソースコードはいまはビルドの対象にはなっていません。
// 将来機能を復活させる前提でソースは残しています。

object FacetCount {

	def main(args: List[String]) {
		val pipeHead = buildPipe(args);

		val lines = stdinLineIterator();
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
					sub(tail, FacetCount.Head(MultiValueFlag(multiValueFlag), WeightFlag(weightFlag), out));
				case _ =>
					throw new Error(args.reverse.mkString(" "));
			}
		}
		sub(args.reverse, StdoutPipeHead);
	}

	private def stdinLineIterator(): Iterator[String] = {

		var fp = new java.io.BufferedReader(new java.io.InputStreamReader(System.in, "UTF-8"));
		var nextLine: String = null;

		new Iterator[String] {

			def hasNext: Boolean = {
				if (fp == null) {
					false;
				} else {
					if (nextLine == null) {
						nextLine = fp.readLine;
					}
					if (nextLine == null) {
						fp.close();
						false;
					} else {
						true;
					}
				}
			}

			def next(): String = {
				if (!hasNext) {
					throw new java.util.NoSuchElementException();
				}
				val ret = nextLine;
				nextLine = null;
				ret;
			}

		}

	}

	case class Head (multiValueFlag: Option[MultiValueFlag], weightFlag: Boolean, out: PipeHead) extends PipeHead {

		def head(cols: Seq[String]): PipeBody = {
			if (weightFlag && cols.size == 0) {
				throw new Exception("Empty column, facetcount --weight");
			}
			val colNames = if (weightFlag) {
				cols.tail;
			} else {
				cols;
			}
			val outBody = out.head(Array("column", "number", "value", "count", "ratio1", "ratio2"));
			Body(multiValueFlag, weightFlag,
				colNames, PeriodResult(colNames.size),
				outBody);
		}

	}

	case class Body (multiValueFlag: Option[MultiValueFlag], weightFlag: Boolean,
		colNames: Seq[String], periodResult: PeriodResult,
		out: PipeBody) extends PipeBody {

		def next(cols: Seq[String]): PipeBody = {
			val (weight: Double, offset: Int) = if (weightFlag) {
				(cols(0).toDouble, 1);
			} else {
				(1.0, 0);
			}
			val result2 = periodResult.next(weight, cols, offset, multiValueFlag);
			Body(multiValueFlag, weightFlag, colNames, result2, out);
		}

		def close() {
			val outClose = (0 until colNames.size).foldLeft(out) { (out, i) =>
				val colName = colNames(i);
				val result = periodResult.columnResults(i);
				val map = result.map;
				map.keySet.toSeq.sortBy(v => (- map(v), v)).zipWithIndex.foldLeft(out) { (out, t) =>
					val (value, number) = t;
					val numberStr = (number + 1).toString;
					val count = map(value);
					val countStr = Util.doubleToString(count);
					val ratio1Str = Util.percentToString(count / periodResult.recordCount);
					val ratio2Str = Util.percentToString(count / result.sum);
					out.next(Array(colName, numberStr, value, countStr, ratio1Str, ratio2Str));
				}
			}
			outClose.close();
		}

	}

	case class PeriodResult (recordCount: Double, columnResults: Seq[PeriodColumnResult]) {
		def next(weight: Double, cols: Seq[String], offset: Int, multiValueFlag: Option[MultiValueFlag]): PeriodResult = {
			val recordCount2 = recordCount + weight;
			val columnResults2 = (0 until columnResults.size).map { i =>
				val col = cols(i + offset);
				columnResults(i).next(weight, col, multiValueFlag);
			}
			PeriodResult(recordCount2, columnResults2);
		}
	}

	object PeriodResult {
		def apply(colCount: Int): PeriodResult = PeriodResult(0.0, IndexedSeq.fill(colCount)(PeriodColumnResult()));
	}

	case class PeriodColumnResult (map: Map[String, Double], sum: Double) {
		def next(weight: Double, value: String, multiValueFlag: Option[MultiValueFlag]): PeriodColumnResult = {
			val map2: Map[String, Double] = {
				Util.valuesFromCol(value, multiValueFlag).foldLeft(map) { (map, value) =>
					map + (value -> (map.getOrElse(value, 0.0) + weight));
				}
			}
			val sum2: Double = {
				if (value.isEmpty) {
					sum;
				} else {
					sum + weight;
				}
			}
			PeriodColumnResult(map2, sum2);
		}
	}

	object PeriodColumnResult {
		def apply(): PeriodColumnResult = PeriodColumnResult(Map.empty, 0.0);
	}

}

