
case class FacetCountHead (multiValueFlag: Option[MultiValueFlag], weightFlag: Boolean, out: PipeHead) extends PipeHead {

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
		FacetCountBody(multiValueFlag, weightFlag,
			colNames,
			0.0, IndexedSeq.fill(colNames.size)(Map.empty), IndexedSeq.fill(colNames.size)(0.0),
			outBody);
	}

}

case class FacetCountBody (multiValueFlag: Option[MultiValueFlag], weightFlag: Boolean,
	colNames: Seq[String],
	recordCount: Double, totalMap: Seq[Map[String, Double]], totalSum: Seq[Double],
	out: PipeBody) extends PipeBody {

	def next(cols: Seq[String]): PipeBody = {
		val (weight: Double, offset: Int) = if (weightFlag) {
			(cols(0).toDouble, 1);
		} else {
			(1.0, 0);
		}
		val totalMap2: Seq[Map[String, Double]] = (0 until colNames.size).map { i =>
			val map = totalMap(i);
			val value = cols(i + offset);
			multiValueFlag match {
				case Some(MultiValueA) =>
					val values = value.split(";", -1).toSet.filter(!_.isEmpty);
					values.foldLeft(map) { (map, value) =>
						map.get(value) match {
							case Some(c) => map + (value -> (c + weight));
							case None => map + (value -> weight);
						}
					}
				case Some(MultiValueB) =>
					throw new Error();
				case None =>
					map.get(value) match {
						case Some(c) => map + (value -> (c + weight));
						case None => map + (value -> weight);
					}
			}
		}
		val totalSum2: Seq[Double] = (0 until colNames.size).map { i =>
			val value = cols(i + offset);
			if (value.isEmpty) {
				totalSum(i);
			} else {
				totalSum(i) + weight;
			}
		}
		FacetCountBody(multiValueFlag, weightFlag, colNames, recordCount + weight, totalMap2, totalSum2, out);
	}

	def close() {
		val outClose = (0 until colNames.size).foldLeft(out) { (out, i) =>
			val colName = colNames(i);
			val map = totalMap(i);
			val sum = totalSum(i);
			map.keySet.toSeq.sortBy(v => (- map(v), v)).foldLeft(out) { (out, value) =>
				val count = map(value);
				val countStr = Util.doubleToString(count);
				val ratio1Str = Util.percentToString(count / recordCount);
				val ratio2Str = Util.percentToString(count / sum);
				out.next(Array(colName, value, countStr, ratio1Str, ratio2Str));
			}
		}
		outClose.close();
	}

}

