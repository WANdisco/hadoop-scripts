#!/bin/bash

for i in `ls -ld /usr/java/jdk1.7\*`; do 
  JDK_PATH=$i;
done

rm -f /usr/lib/jvm/java-7-oracle-amd64
ln -s $JDK_PATH /usr/lib/jvm/java-7-oracle-amd64

update-alternatives --install "/usr/bin/appletviewer" "appletviewer" "/usr/lib/jvm/java-7-oracle-amd64/bin/appletviewer" 1
update-alternatives --install "/usr/bin/extcheck" "extcheck" "/usr/lib/jvm/java-7-oracle-amd64/bin/extcheck" 1
update-alternatives --install "/usr/bin/idlj" "idlj" "/usr/lib/jvm/java-7-oracle-amd64/bin/idlj" 1
update-alternatives --install "/usr/bin/jar" "jar" "/usr/lib/jvm/java-7-oracle-amd64/bin/jar" 1
update-alternatives --install "/usr/bin/jarsigner" "jarsigner" "/usr/lib/jvm/java-7-oracle-amd64/bin/jarsigner" 1
update-alternatives --install "/usr/bin/javac" "javac" "/usr/lib/jvm/java-7-oracle-amd64/bin/javac" 1
update-alternatives --install "/usr/bin/javadoc" "javadoc" "/usr/lib/jvm/java-7-oracle-amd64/bin/javadoc" 1
update-alternatives --install "/usr/bin/javah" "javah" "/usr/lib/jvm/java-7-oracle-amd64/bin/javah" 1
update-alternatives --install "/usr/bin/javap" "javap" "/usr/lib/jvm/java-7-oracle-amd64/bin/javap" 1
update-alternatives --install "/usr/bin/jconsole" "jconsole" "/usr/lib/jvm/java-7-oracle-amd64/bin/jconsole" 1
update-alternatives --install "/usr/bin/jdb" "jdb" "/usr/lib/jvm/java-7-oracle-amd64/bin/jdb" 1
update-alternatives --install "/usr/bin/jhat" "jhat" "/usr/lib/jvm/java-7-oracle-amd64/bin/jhat" 1
update-alternatives --install "/usr/bin/jinfo" "jinfo" "/usr/lib/jvm/java-7-oracle-amd64/bin/jinfo" 1
update-alternatives --install "/usr/bin/jmap" "jmap" "/usr/lib/jvm/java-7-oracle-amd64/bin/jmap" 1
update-alternatives --install "/usr/bin/jps" "jps" "/usr/lib/jvm/java-7-oracle-amd64/bin/jps" 1
update-alternatives --install "/usr/bin/jrunscript" "jrunscript" "/usr/lib/jvm/java-7-oracle-amd64/bin/jrunscript" 1
update-alternatives --install "/usr/bin/jsadebugd" "jsadebugd" "/usr/lib/jvm/java-7-oracle-amd64/bin/jsadebugd" 1
update-alternatives --install "/usr/bin/jstack" "jstack" "/usr/lib/jvm/java-7-oracle-amd64/bin/jstack" 1
update-alternatives --install "/usr/bin/jstat" "jstat" "/usr/lib/jvm/java-7-oracle-amd64/bin/jstat" 1
update-alternatives --install "/usr/bin/jstatd" "jstatd" "/usr/lib/jvm/java-7-oracle-amd64/bin/jstatd" 1
update-alternatives --install "/usr/bin/native2ascii" "native2ascii" "/usr/lib/jvm/java-7-oracle-amd64/bin/native2ascii" 1
update-alternatives --install "/usr/bin/rmic" "rmic" "/usr/lib/jvm/java-7-oracle-amd64/bin/rmic" 1
update-alternatives --install "/usr/bin/schemagen" "schemagen" "/usr/lib/jvm/java-7-oracle-amd64/bin/schemagen" 1
update-alternatives --install "/usr/bin/serialver" "serialver" "/usr/lib/jvm/java-7-oracle-amd64/bin/serialver" 1
update-alternatives --install "/usr/bin/wsgen" "wsgen" "/usr/lib/jvm/java-7-oracle-amd64/bin/wsgen" 1
update-alternatives --install "/usr/bin/wsimport" "wsimport" "/usr/lib/jvm/java-7-oracle-amd64/bin/wsimport" 1
update-alternatives --install "/usr/bin/xjc" "xjc" "/usr/lib/jvm/java-7-oracle-amd64/bin/xjc" 1
update-alternatives --install "/usr/bin/java" "java" "/usr/lib/jvm/java-7-oracle-amd64/jre/bin/java" 1
update-alternatives --install "/usr/bin/keytool" "keytool" "/usr/lib/jvm/java-7-oracle-amd64/jre/bin/keytool" 1
update-alternatives --install "/usr/bin/pack200" "pack200" "/usr/lib/jvm/java-7-oracle-amd64/jre/bin/pack200" 1
update-alternatives --install "/usr/bin/rmid" "rmid" "/usr/lib/jvm/java-7-oracle-amd64/jre/bin/rmid" 1
update-alternatives --install "/usr/bin/rmiregistry" "rmiregistry" "/usr/lib/jvm/java-7-oracle-amd64/jre/bin/rmiregistry" 1
update-alternatives --install "/usr/bin/unpack200" "unpack200" "/usr/lib/jvm/java-7-oracle-amd64/jre/bin/unpack200" 1
update-alternatives --install "/usr/bin/orbd" "orbd" "/usr/lib/jvm/java-7-oracle-amd64/jre/bin/orbd" 1
update-alternatives --install "/usr/bin/servertool" "servertool" "/usr/lib/jvm/java-7-oracle-amd64/jre/bin/servertool" 1
update-alternatives --install "/usr/bin/tnameserv" "tnameserv" "/usr/lib/jvm/java-7-oracle-amd64/jre/bin/tnameserv" 1
update-alternatives --install "/usr/bin/policytool" "policytool" "/usr/lib/jvm/java-7-oracle-amd64/jre/bin/policytool" 1
update-alternatives --install "/usr/bin/jexec" "jexec" "/usr/lib/jvm/java-7-oracle-amd64/jre/lib/jexec" 1

cat << __EOF__ > /usr/lib/jvm/.java-7-oracle-amd64.info
name=java-7-oracle-amd64
alias=java-1.7.0-oracle
priority=1051
section=main

hl java /usr/lib/jvm/java-7-oracle-amd64/jre/bin/java
hl keytool /usr/lib/jvm/java-7-oracle-amd64/jre/bin/keytool
hl pack200 /usr/lib/jvm/java-7-oracle-amd64/jre/bin/pack200
hl rmid /usr/lib/jvm/java-7-oracle-amd64/jre/bin/rmid
hl rmiregistry /usr/lib/jvm/java-7-oracle-amd64/jre/bin/rmiregistry
hl unpack200 /usr/lib/jvm/java-7-oracle-amd64/jre/bin/unpack200
hl orbd /usr/lib/jvm/java-7-oracle-amd64/jre/bin/orbd
hl servertool /usr/lib/jvm/java-7-oracle-amd64/jre/bin/servertool
hl tnameserv /usr/lib/jvm/java-7-oracle-amd64/jre/bin/tnameserv
hl jexec /usr/lib/jvm/java-7-oracle-amd64/jre/lib/jexec
jre policytool /usr/lib/jvm/java-7-oracle-amd64/jre/bin/policytool
jdk appletviewer /usr/lib/jvm/java-7-oracle-amd64/bin/appletviewer
jdk extcheck /usr/lib/jvm/java-7-oracle-amd64/bin/extcheck
jdk idlj /usr/lib/jvm/java-7-oracle-amd64/bin/idlj
jdk jar /usr/lib/jvm/java-7-oracle-amd64/bin/jar
jdk jarsigner /usr/lib/jvm/java-7-oracle-amd64/bin/jarsigner
jdk javac /usr/lib/jvm/java-7-oracle-amd64/bin/javac
jdk javadoc /usr/lib/jvm/java-7-oracle-amd64/bin/javadoc
jdk javah /usr/lib/jvm/java-7-oracle-amd64/bin/javah
jdk javap /usr/lib/jvm/java-7-oracle-amd64/bin/javap
jdk jcmd /usr/lib/jvm/java-7-oracle-amd64/bin/jcmd
jdk jconsole /usr/lib/jvm/java-7-oracle-amd64/bin/jconsole
jdk jdb /usr/lib/jvm/java-7-oracle-amd64/bin/jdb
jdk jhat /usr/lib/jvm/java-7-oracle-amd64/bin/jhat
jdk jinfo /usr/lib/jvm/java-7-oracle-amd64/bin/jinfo
jdk jmap /usr/lib/jvm/java-7-oracle-amd64/bin/jmap
jdk jps /usr/lib/jvm/java-7-oracle-amd64/bin/jps
jdk jrunscript /usr/lib/jvm/java-7-oracle-amd64/bin/jrunscript
jdk jsadebugd /usr/lib/jvm/java-7-oracle-amd64/bin/jsadebugd
jdk jstack /usr/lib/jvm/java-7-oracle-amd64/bin/jstack
jdk jstat /usr/lib/jvm/java-7-oracle-amd64/bin/jstat
jdk jstatd /usr/lib/jvm/java-7-oracle-amd64/bin/jstatd
jdk native2ascii /usr/lib/jvm/java-7-oracle-amd64/bin/native2ascii
jdk rmic /usr/lib/jvm/java-7-oracle-amd64/bin/rmic
jdk schemagen /usr/lib/jvm/java-7-oracle-amd64/bin/schemagen
jdk serialver /usr/lib/jvm/java-7-oracle-amd64/bin/serialver
jdk wsgen /usr/lib/jvm/java-7-oracle-amd64/bin/wsgen
jdk wsimport /usr/lib/jvm/java-7-oracle-amd64/bin/wsimport
jdk xjc /usr/lib/jvm/java-7-oracle-amd64/bin/xjc
plugin mozilla-javaplugin.so /usr/lib/jvm/java-7-oracle-amd64/jre/lib/amd64/IcedTeaPlugin.so
__EOF__

