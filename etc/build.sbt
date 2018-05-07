
name := "xsvutils-java"
//
//version := "1.0-SNAPSHOT"
//
//organization := "jp.kotohaco"

//scalaVersion := "2.11.8"
scalaVersion := "2.10.4"
enablePlugins(JavaAppPackaging)
//enablePlugins(UniversalPlugin)

resolvers += "Restlet Repository" at "http://maven.restlet.org"

libraryDependencies ++= Seq(
//  "org.apache.lucene" % "lucene-core" % "6.0.1",
//  "commons-beanutils" % "commons-beanutils" % "1.8.3",
//  "net.sf.ezmorph" % "ezmorph" % "1.0.6",
//  "net.sf.json-lib" % "json-lib" % "2.4" classifier "jdk15",
//  "org.apache.lucene" % "lucene-core" % "4.2.1",
//  "org.apache.lucene" % "lucene-analyzers-common" % "6.0.1",
//  "org.apache.lucene" % "lucene-analyzers-icu" % "6.0.1",
//  "org.apache.solr" % "solr-dataimporthandler" % "6.0.1",
//  "com.googlecode.jmockit" % "jmockit" % "1.5",
//  "net.sf.trove4j" % "trove4j" % "3.0.3"
)


//// increase the time between polling for file changes when using continuous execution
//pollInterval := 1000

// append several options to the list of options passed to the Java compiler
//javacOptions ++= Seq("-source", "1.8", "-target", "1.8", "-Xlint:unchecked", "-Xlint:deprecation")
//javacOptions ++= Seq("-source", "1.7", "-target", "1.7", "-Xlint:unchecked", "-Xlint:deprecation")

// append -deprecation to the options passed to the Scala compiler
scalacOptions += "-deprecation"

//// set the main class for packaging the main jar
//// 'run' will still auto-detect and prompt
//// change Compile to Test to set it for the test jar
//mainClass in (Compile, packageBin) := Some("jp.kotohaco.ec2.mojimoji.Main")
//
//// set the main class for the main 'run' task
//// change Compile to Test to set it for 'test:run'
//mainClass in (Compile, run) := Some("jp.kotohaco.ec2.mojimoji.Main")
//
//// disable using the Scala version in output paths and artifacts
//crossPaths := false
//
//// fork a new JVM for 'run' and 'test:run'
//fork := true
//
//// add a JVM option to use when forking a JVM for 'run'
//javaOptions += "-Xmx1536m"
//
//javaOptions in run += "-agentlib:hprof=cpu=samples,depth=20"
//
////assemblySettings
//
////jarName in assembly := "kotohaco.jar"

