
case class FileRange(offset: Long, length: Long);

case class FileRangeList(ranges: List[FileRange]) {

	override def toString(): String = {
		ranges.map(r => r.offset + "," + r.length).mkString(";");
	}

	def toSkipAndReadList: List[FileSkipAndRead] = {
		val (_, srListReversed) = ranges.foldLeft[(Long, List[FileSkipAndRead])]((0, Nil)) { (t, range) =>
			val (o, srListReversed) = t;
			val skip = range.offset - o;
			val read = range.length;
			val newOffset = range.offset + range.length;
			(newOffset, FileSkipAndRead(skip, read) :: srListReversed);
		}
		srListReversed.reverse;
	}

}

object FileRangeList {

	def parse(s: String): FileRangeList = {
		val ss: Array[String] = s.split(";", -1);
		val ranges: List[FileRange] = ss.toList.map { s2 =>
			val s3 = s2.split(",", 2);
			if (s3.size < 2) {
				throw new IllegalArgumentException(s);
			}
			try {
				FileRange(s3(0).toLong, s3(1).toLong);
			} catch { case _: NumberFormatException =>
				throw new IllegalArgumentException(s);
			}
		}
		val ranges2 = ranges.sortBy(_.offset);
		var offset: Long = 0;
		ranges2.foreach { r =>
			if (offset > r.offset) {
				throw new IllegalArgumentException(s);
			}
			offset = r.offset + r.length;
		}
		FileRangeList(ranges2)
	}

}

case class FileSkipAndRead(skip: Long, read: Long);

