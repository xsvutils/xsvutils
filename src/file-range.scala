
case class FileRange(offset: Long, length: Long);

case class FileRangeList(records: List[FileRange]) {

	override def toString(): String = {
		records.map(r => r.offset + "," + r.length).mkString(";");
	}

}

