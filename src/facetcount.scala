
object FacetCount {

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

