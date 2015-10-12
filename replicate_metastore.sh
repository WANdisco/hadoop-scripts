#!/bin/bash

# Be strict about the file permissions for logs
umask 077

LOG_DIR="/var/log/$(basename $0 .sh)"
mkdir -p $LOG_DIR
LOG_FILE="${LOG_DIR}/$(basename $0 .sh)_`date +"%Y_%m_%d_%H_%M_%S"`.log"

HIVE_CMD=`type -p beeline`

# Default values. Do not change! 
NOCHANGE=0
VERBOSE=1
LOG_CURRENT=0
RETAIN_SQL=0

trap '' ERR

usage() {
  cat >&2<<!!
Usage: $(basename $0) [-h] <Config File> 
Migrated hive metastore from one cluster to another using beeline. 
Config file should contain the following information: 

#---------
WORK_DIRECTORY="/var/run/hivemetastore"
DCS_COUNT=2
HIVESERVER_URI[0]="jdbc:hive2://cdhmaster:10000"
PRINCIPAL[0]="hive/cdhmaster.wandisco.com@WANDISCO.COM"
HIVESERVER_URI[1]="jdbc:hive2://hdpmaster:10000"
PRINCIPAL[1]="hive/hdpmaster@WANDISCO.COM"
HDFS[0]="hdfs://cdhmaster.wandisco.com:8020"
HDFS[1]="hdfs://hdpmaster.wandisco.com:8020"
USER[0]="hive"
PASSWORD[1]=""
USER[1]="hive"
PASSWORD[1]=""
DATABASES="db1_ez;db2_ez;db3"
#---------


Options: 

 -h --help
  Display this help message.

!!
}


syntax_error() {
  echo -e "$*" >&2
  usage
  exit 1
}



log_message() {
  echo "`date +"%D %H:%M --"` $@"
  echo "`date +"%D %H:%M --"` $@" >> $LOG_FILE
}


log_verbose() {
  if [ "$VERBOSE" = "1" ]; then
    log_message $@
  fi
}


log_error() {
  echo "`date +"%D %H:%M --"` $@" >&2
  echo "`date +"%D %H:%M --"` $@" >> $LOG_FILE  
}

exec_hive() {  
  DC=$1
  CMD=$2
  ${HIVE_CMD} -u "${HIVESERVER_URI[$DC]}/$i;principal=${PRINCIPAL[$DC]}" -n USER1 -p "$PASSWORD[$DC]" -e $CMD  2>>${LOG_FILE}
}





dump_metastore() {
  CURRENT_DC="$CURRENT_FOLDER/DC$1"
  mkdir -p $CURRENT_DC || exit "Can not create dump folder: $CURRENT_DC"

  log_verbose "Dumping metastore from $1 into $CURRENT_DC:"
  for i in `echo $DATABASES | tr -s ';' ' '` 
  do
    log_verbose "Dumping $i..."
    exec_hive $1 "describe database extended $i" > "${CURRENT_DC}/$i.extended" || rm -f "${CURRENT_DC}/$i.extended"

    log_verbose "Dumping $i tables..."
    exec_hive $1 "show tables"  > "${CURRENT_DC}/$i.tables" || rm -f "${CURRENT_DC}/$i.tables"

    # Now read tables from the file...
    while read sym table remaining; do
      [ -z "$table" ] && continue
      [[ "$table" = "tab_name" ]] && continue
      printf "Found table: $table.\n\tDumping create info...\n"
      exec_hive "show create table $table"  > "${CURRENT_DC}/$i.$table.create" || rm -f "${CURRENT_DC}/$i.$table.create"
      printf "\tDumping partitions...\n"
      exec_hive "show partitions $table"  > "${CURRENT_DC}/$i.$table.partitions" || rm -f "${CURRENT_DC}/$i.$table.partitions"
    done < "${CURRENT_DC}/$i.tables"
  done
}


#compare_table() {
#
#}

create_database() {
  DC=$1
  DB=$2
  exec_hive $DC "create database $DB"
}


#alter_database() {
#
#}


create_table() {
  DC=$1
  DB=
}


compare_database() {
  DC=$1
  DB=$2  
  DC_FOLDER="$CURRENT_FOLDER/DC${DC}"

  [-f "${DC_FOLDER}/${DB}.extended"] || create_database ${DC} ${DB}


  "${CURRENT_DC}/$i.extended"

}


compare_metastores() {
  DC0="$CURRENT_FOLDER/DC0"
  DC1="$CURRENT_FOLDER/DC1"



}



# Read command line parameters
while true; do
  case "$1" in
    -h | --help)
      shift
      usage
      exit 0
      ;;
    -q | --quiet)
      shift
      VERBOSE=0     
      ;;
    -v | --verbose)
      shift
      VERBOSE=1     
      ;;      
    -n | --nochange)
      shift
      NOCHANGE=1
      ;;
    -l | --log_current)
      shift
      LOG_CURRENT=1
      ;;
    -c)
      shift
      LOG_FILE=/dev/null
      ;;
    -x | --notranslate)
      shift
      NO_EXEC=1
      ;;
    -*) echo "ERROR: Unknown option: $1" >&2
      exit 1
      ;;
    *)  break
      ;;
  esac
done

FILE=$1

if [ x"$FILE" = "x" ]; then
  echo "No config file parameter found. Please run me with -h for usage"
  exit 1
fi

# Read in config parameters. 
source $FILE

CURRENT_FOLDER="${WORK_DIRECTORY}/`date +"%Y_%m_%d_%H_%M_%S"`"

cnt=0
for dci in "${HIVESERVER_URI[@]}"
do
  cnt=${cnt+1}
  dump_metastore $cnt
done

exit 0;

log_verbose "Comparing metastores..."

compare_metastores 


