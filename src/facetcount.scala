
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
			val outBody = out.head(Array("column", "value", "count", "ratio", "ratio2"));
			Body(multiValueFlag, weightFlag,
				colNames,
				0.0, IndexedSeq.fill(colNames.size)(PeriodColumnResult()),
				outBody);
		}

	}

	case class Body (multiValueFlag: Option[MultiValueFlag], weightFlag: Boolean,
		colNames: Seq[String],
		recordCount: Double, columnResults: Seq[PeriodColumnResult],
		out: PipeBody) extends PipeBody {

		def next(cols: Seq[String]): PipeBody = {
			val (weight: Double, offset: Int) = if (weightFlag) {
				(cols(0).toDouble, 1);
			} else {
				(1.0, 0);
			}
			val recordCount2 = recordCount + weight;
			val columnResults2 = (0 until colNames.size).map { i =>
				val col = cols(i + offset);
				columnResults(i).next(weight, col, multiValueFlag);
			}
			Body(multiValueFlag, weightFlag, colNames, recordCount2, columnResults2, out);
		}

		def close() {
			val outClose = (0 until colNames.size).foldLeft(out) { (out, i) =>
				val colName = colNames(i);
				val result = columnResults(i);
				val map = result.map;
				map.keySet.toSeq.sortBy(v => (- map(v), v)).foldLeft(out) { (out, value) =>
					val count = map(value);
					val countStr = Util.doubleToString(count);
					val ratio1Str = Util.percentToString(count / recordCount);
					val ratio2Str = Util.percentToString(count / result.sum);
					out.next(Array(colName, value, countStr, ratio1Str, ratio2Str));
				}
			}
			outClose.close();
		}

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

