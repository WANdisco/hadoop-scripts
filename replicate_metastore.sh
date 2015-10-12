#!/bin/bash

# Be strict about the file permissions for logs
umask 077

LOG_DIR="/var/log/hivemetastore"
mkdir -p $LOG_DIR
LOG_FILE="${LOG_DIR}/$(basename $0 .sh)_`date +"%Y_%m_%d_%H_%M_%S"`.log"

HIVE_CMD=`type -p beeline`

# Default values. Do not change! 
NOCHANGE=0
VERBOSE=1
LOG_CURRENT=0
RETAIN_SQL=0
MERGE=0
OVERWRITE=0
CLEANUP=0

trap '' ERR

usage() {
  cat >&2<<!!
Usage: $(basename $0) [-hqcnol] <Config File>

This scripts attempts to copy hive metastore from the source cluster to one 
or more consuming clusters. Only uni-directional migration is supported. 
No attempt is made to resolve conflicts or merge changes on the other end. 
If a table already exists on the target cluster and differs from the source 
no attempt to alter table will be made at this point, however
if -o parameter is supplied a table will be dropped and re-created on target 
cluster. 

Config file should contain at least the following information: 

[0] should point to the source cluster.

#---------
WORK_DIRECTORY="/var/run/hivemetastore"
DCS_COUNT=2
HIVESERVER_URI[0]="jdbc:hive2://cdhmaster.wandisco.com:10000"
PRINCIPAL[0]="hive/cdhmaster.wandisco.com@WANDISCO.COM"
HIVESERVER_URI[1]="jdbc:hive2://hdpmaster.wandisco.com:10000"
PRINCIPAL[1]="hive/hdpmaster@WANDISCO.COM"
HDFS[0]="hdfs://cdhmaster.wandisco.com:8020"
HDFS[1]="hdfs://hdpmaster.wandisco.com:8020"
USER[0]="hive"
PASSWORD[0]=""
USER[1]="hive"
PASSWORD[1]=""
DATABASE[0]="test1"
DATABASE[1]="test2"
DATABASE[2]="test3"
#---------


Options: 

 -h --help
  Display this help message.
 -q --quiet
  Do not output verbose messages
 -n --nochange
  Do not deploy changes to the target clusters. Just output the .sql file
 -l --logfile <log file location>
  Set a different log file location
 -c --cleanup
  Cleanup temporary files (logs retained).


!!
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
  shift
  CMD=$@
  HIVE_URI="${HIVESERVER_URI[$DC]}/$i"
  [ "x${PRINCIPAL[$DC]}" = "x" ] || HIVE_URI="${HIVE_URI};principal=${PRINCIPAL[$DC]}"
  ${HIVE_CMD} -u "${HIVE_URI}" -n "${USER[$DC]}" -p "${PASSWORD[$DC]}" -e "$CMD"  2>>${LOG_FILE}
}


deploy_changes() {
  DC=$1

  log_verbose "Deploying changes for DC${DC}"  
  HIVE_URI="${HIVESERVER_URI[$DC]}/$i"
  [ "x${PRINCIPAL[$DC]}" = "x" ] || HIVE_URI="${HIVE_URI};principal=${PRINCIPAL[$DC]}"
  ${HIVE_CMD} -u "${HIVE_URI}" -n "${USER[$DC]}" -p "${PASSWORD[$DC]}" -f "${SYNC_FILE[$DC]}"  2>>${LOG_FILE}
}


issue_cmd() {
  DC=$1
  shift
  CMD=$@

  log_verbose "Issuing command into ${SYNC_FILE[$DC]}"

  echo "$CMD" >> "${SYNC_FILE[$DC]}"
}


dump_metastore() {
  DC=$1
  CURRENT_DC="$CURRENT_FOLDER/DC$DC"
  mkdir -p $CURRENT_DC || exit "Can not create dump folder: $CURRENT_DC"

  log_verbose "Dumping metastore from $DC into $CURRENT_DC:"

  for i in "${DATABASE[@]}"
  do
    log_verbose "Dumping $i..."
    exec_hive $1 "describe database extended $i" > "${CURRENT_DC}/$i.extended" || rm -f "${CURRENT_DC}/$i.extended"

    log_verbose "Dumping $i tables..."
    exec_hive $1 "show tables"  > "${CURRENT_DC}/$i.tables" || rm -f "${CURRENT_DC}/$i.tables"

    # Now read tables from the file...
    if [ -f "${CURRENT_DC}/$i.tables" ]; then
      while read sym table remaining; do
        [ -z "$table" ] && continue
        [[ "$table" = "tab_name" ]] && continue
        printf "Found table: $table.\n\tDumping create info...\n"
        exec_hive $DC "show create table $table"  > "${CURRENT_DC}/$i.$table.create" || rm -f "${CURRENT_DC}/$i.$table.create"
        printf "\tDumping partitions...\n"
        exec_hive $DC "show partitions $table" | tail -n +3 | head -n -1 > "${CURRENT_DC}/$i.$table.partitions" || rm -f "${CURRENT_DC}/$i.$table.partitions"
      done < "${CURRENT_DC}/$i.tables"
    else
      log_verbose "${DB} has no tables."
    fi
  done
}


create_database() {
  DC=$1
  DB=$2
  issue_cmd $DC "create database $DB;"
}


create_table() {
  DC=$1
  DB=$2
  TABLE=$3

  if [ ! -f "${SOURCE_DC}/${DB}.${TABLE}.create" ]; then
    log_verbose "create_table: ${DB}.${TABLE} has no definition. Skipping..."
    return 1
  fi

  create_cmd="$(tail -n +4 ${SOURCE_DC}/${DB}.${TABLE}.create | head -n -1 | sed 's/|//g' | tr '\n' ' ' | sed "s#${HDFS[0]}#${HDFS[$DC]}#g");"

  issue_cmd $DC "use $DB; $create_cmd"
}


generate_alter() {
  DC=$1
  DB=$2
  TABLE=$3

  if [ "${OVERWRITE}" = "1" ]; then
    issue_cmd $DC "use $DB; alter table ${TABLE} SET TBLPROPERTIES('EXTERNAL'='TRUE'); drop table ${TABLE};"
    create_table ${DC} ${DB} ${TABLE}
  fi
}



compare_database() {
  DC=$1
  DC1_FOLDER="${CURRENT_FOLDER}/DC${DC}"
  DB=$2

  log_verbose "Comparing database $DB in DC$DC..."

  if [ ! -f "${SOURCE_DC}/${DB}.extended" ]; then 
    log_verbose "Database ${DB} not present in source cluster. Skipping..."
    return 0
  fi

    # at this point we just create database with default location...
  if [ ! -f "${DC1_FOLDER}/${DB}.extended" ]; then 
    log_verbose "Database ${DB} doesn't exist in DC${DC}. Creating..." 
    create_database ${DC} ${DB}
  fi

  # Comparing tables.

  if [ ! -f "${SOURCE_DC}/${DB}.tables" ]; then
    log_verbose "No tables defined for ${DB}. Skipping..." 
    return 0
  fi

  while read sym table remaining; do
    [ -z "$table" ] && continue
    [[ "$table" = "tab_name" ]] && continue
    if [ -f "${DC1_FOLDER}/${DB}.${table}.create" ]; then
      log_verbose "Table $table exists. Comparing definitions..."
      sed "s#${HDFS[${DC}]}#${HDFS[0]}#g" "${DC1_FOLDER}/${DB}.${table}.create" | tail -n +4 | head -n -2 > "${SOURCE_DC}/${DB}.${table}.create.$DC"
      tail -n +4 "${SOURCE_DC}/${DB}.${table}.create" | head -n -2 > "${SOURCE_DC}/${DB}.${table}.create.0"
      diff -wu "$SOURCE_DC/${DB}.${table}.create.0" "${SOURCE_DC}/${DB}.${table}.create.$DC" >/dev/null 2>&1
      if [ $? -ne 0 ]; then
        if [ "${OVERWRITE}" = "1" ]; then
          log_verbose "Table definitions differ in source and target cluster. Re-create a table."
          generate_alter $DC $DB $table
        else
          log_verbose "Tables definitions differ. -o is not set, so skipping..."
        fi
      fi
    else
      log_verbose "Table $table does not exist. Creating..."; 
      create_table ${DC} ${DB} ${table}
    fi


    if [ -f "${SOURCE_DC}/${DB}.${table}.partitions" ]; then
      log_verbose "Checking partitions for ${table}..."
      if [ -f "${DC1_FOLDER}/${DB}.${table}.partitions" ]; then
        # TODO: might want to sort the partitions before comparing. The order is not guaranteed. 
        diff -wu "${SOURCE_DC}/${DB}.${table}.partitions" "${DC1_FOLDER}/${DB}.${table}.partitions" >/dev/null 2>&1 
        if [ $? -ne 0 ]; then
          log_verbose "Partitions differ. Issue msck to rescan..."
          issue_cmd $DC "USE ${DB}; MSCK REPAIR TABLE ${table};"
        fi
      else
        log_verbose "No partitions present. Issue msck to rescan..."
        issue_cmd $DC "USE ${DB}; MSCK REPAIR TABLE ${table};"
      fi
    fi
  done < "${SOURCE_DC}/${DB}.tables"

}


compare_metastores() {
  log_verbose "Comparing databases for DC$1"
  for di in "${DATABASE[@]}"
  do
    compare_database $1 $di
  done
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
    -n | --nochange)
      shift
      NOCHANGE=1
      ;;
    -o | --overwrite)
      shift
      OVERWRITE=1
      ;;
    -l | --logfile)
      shift
      LOG_FILE=/dev/null
      ;;
    -c | --cleanup)
      shift;
      CLEANUP=1
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
  log_verbose "No config file parameter found. Please run me with -h for usage"
  exit 1
fi

# Read in config parameters. 
source $FILE

CURRENT_FOLDER="${WORK_DIRECTORY}/`date +"%Y_%m_%d_%H_%M_%S"`"
#CURRENT_FOLDER="${WORK_DIRECTORY}"
SOURCE_DC="${CURRENT_FOLDER}/DC0"

cnt=0
for dci in "${HIVESERVER_URI[@]}"
do
  log_verbose "Dumping DB - $cnt"
  dump_metastore $cnt
  cnt=$((cnt+1))
done

log_verbose "Comparing metastores..."
cnt=$((cnt-1))

[ "$cnt" -lt "1" ] && (log_verbose "You have only a single DC. Nothing to do..."; exit)

#
# URI[0] is always the source. 
# Replication is always uni-directional from DC0->DC1,DC2,....
#
for i in `seq 1 $cnt`
do
  SYNC_FILE[$cnt]="${CURRENT_FOLDER}/DC${cnt}/merge_query.sql"
  # Cleanup the file just in case...
  echo > "${SYNC_FILE[$cnt]}"
  compare_metastores $i 
  if [ "$NOCHANGE" = "0" ]; then  
    deploy_changes $i
  else
    log_verbose "No changes made. Check ${SYNC_FILE[$i]} for proposed changes..."
  fi
done

if [ "${CLEANUP}" = "1" ]; then
  rm -rf ${CURRENT_FOLDER}
fi

