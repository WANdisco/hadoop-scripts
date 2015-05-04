#!/bin/bash

for i in `ls -ld /usr/java/jdk1.7\*`; do 
  JDK_PATH=$i;
done

rm -f /usr/java/java-7-oracle-amd64
ln -s $JDK_PATH /usr/java/java-7-oracle-amd64

update-alternatives --install "/usr/bin/appletviewer" "appletviewer" "/usr/java/java-7-oracle-amd64/bin/appletviewer" 1
update-alternatives --install "/usr/bin/extcheck" "extcheck" "/usr/java/java-7-oracle-amd64/bin/extcheck" 1
update-alternatives --install "/usr/bin/idlj" "idlj" "/usr/java/java-7-oracle-amd64/bin/idlj" 1
update-alternatives --install "/usr/bin/jar" "jar" "/usr/java/java-7-oracle-amd64/bin/jar" 1
update-alternatives --install "/usr/bin/jarsigner" "jarsigner" "/usr/java/java-7-oracle-amd64/bin/jarsigner" 1
update-alternatives --install "/usr/bin/javac" "javac" "/usr/java/java-7-oracle-amd64/bin/javac" 1
update-alternatives --install "/usr/bin/javadoc" "javadoc" "/usr/java/java-7-oracle-amd64/bin/javadoc" 1
update-alternatives --install "/usr/bin/javah" "javah" "/usr/java/java-7-oracle-amd64/bin/javah" 1
update-alternatives --install "/usr/bin/javap" "javap" "/usr/java/java-7-oracle-amd64/bin/javap" 1
update-alternatives --install "/usr/bin/jconsole" "jconsole" "/usr/java/java-7-oracle-amd64/bin/jconsole" 1
update-alternatives --install "/usr/bin/jdb" "jdb" "/usr/java/java-7-oracle-amd64/bin/jdb" 1
update-alternatives --install "/usr/bin/jhat" "jhat" "/usr/java/java-7-oracle-amd64/bin/jhat" 1
update-alternatives --install "/usr/bin/jinfo" "jinfo" "/usr/java/java-7-oracle-amd64/bin/jinfo" 1
update-alternatives --install "/usr/bin/jmap" "jmap" "/usr/java/java-7-oracle-amd64/bin/jmap" 1
update-alternatives --install "/usr/bin/jps" "jps" "/usr/java/java-7-oracle-amd64/bin/jps" 1
update-alternatives --install "/usr/bin/jrunscript" "jrunscript" "/usr/java/java-7-oracle-amd64/bin/jrunscript" 1
update-alternatives --install "/usr/bin/jsadebugd" "jsadebugd" "/usr/java/java-7-oracle-amd64/bin/jsadebugd" 1
update-alternatives --install "/usr/bin/jstack" "jstack" "/usr/java/java-7-oracle-amd64/bin/jstack" 1
update-alternatives --install "/usr/bin/jstat" "jstat" "/usr/java/java-7-oracle-amd64/bin/jstat" 1
update-alternatives --install "/usr/bin/jstatd" "jstatd" "/usr/java/java-7-oracle-amd64/bin/jstatd" 1
update-alternatives --install "/usr/bin/native2ascii" "native2ascii" "/usr/java/java-7-oracle-amd64/bin/native2ascii" 1
update-alternatives --install "/usr/bin/rmic" "rmic" "/usr/java/java-7-oracle-amd64/bin/rmic" 1
update-alternatives --install "/usr/bin/schemagen" "schemagen" "/usr/java/java-7-oracle-amd64/bin/schemagen" 1
update-alternatives --install "/usr/bin/serialver" "serialver" "/usr/java/java-7-oracle-amd64/bin/serialver" 1
update-alternatives --install "/usr/bin/wsgen" "wsgen" "/usr/java/java-7-oracle-amd64/bin/wsgen" 1
update-alternatives --install "/usr/bin/wsimport" "wsimport" "/usr/java/java-7-oracle-amd64/bin/wsimport" 1
update-alternatives --install "/usr/bin/xjc" "xjc" "/usr/java/java-7-oracle-amd64/bin/xjc" 1
update-alternatives --install "/usr/bin/java" "java" "/usr/java/java-7-oracle-amd64/jre/bin/java" 1
update-alternatives --install "/usr/bin/keytool" "keytool" "/usr/java/java-7-oracle-amd64/jre/bin/keytool" 1
update-alternatives --install "/usr/bin/pack200" "pack200" "/usr/java/java-7-oracle-amd64/jre/bin/pack200" 1
update-alternatives --install "/usr/bin/rmid" "rmid" "/usr/java/java-7-oracle-amd64/jre/bin/rmid" 1
update-alternatives --install "/usr/bin/rmiregistry" "rmiregistry" "/usr/java/java-7-oracle-amd64/jre/bin/rmiregistry" 1
update-alternatives --install "/usr/bin/unpack200" "unpack200" "/usr/java/java-7-oracle-amd64/jre/bin/unpack200" 1
update-alternatives --install "/usr/bin/orbd" "orbd" "/usr/java/java-7-oracle-amd64/jre/bin/orbd" 1
update-alternatives --install "/usr/bin/servertool" "servertool" "/usr/java/java-7-oracle-amd64/jre/bin/servertool" 1
update-alternatives --install "/usr/bin/tnameserv" "tnameserv" "/usr/java/java-7-oracle-amd64/jre/bin/tnameserv" 1
update-alternatives --install "/usr/bin/policytool" "policytool" "/usr/java/java-7-oracle-amd64/jre/bin/policytool" 1
update-alternatives --install "/usr/bin/jexec" "jexec" "/usr/java/java-7-oracle-amd64/jre/lib/jexec" 1
