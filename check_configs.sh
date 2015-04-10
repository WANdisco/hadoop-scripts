#!/bin/bash

# be strict about permissions for logs and sentry query files.
umask 077

LOG_DIR="/tmp"
DIFF_DIR="/tmp/$(basename $0 .sh)"

TIME_SPEC=`date +"%Y_%m_%d_%H_%M_%S"`

LOG_FILE="${LOG_DIR}/$(basename $0 .sh)_${TIME_SPEC}.log"
LOG_FILE="${LOG_DIR}/$(basename $0 .sh)_${TIME_SPEC}.msg"

USER=admin
PASSWORD=admin


trap '' ERR

usage() {
  cat >&2<<!!
Usage: $(basename $0) <cm host1> <cm host2>

Compares configuration files of two clusters. 

Options: 

 -h --help
  Display this help message.
 -r
  Retain temp files created during operation (diffs, messages, etc)
 -s
  Store current diff as known-good difference between clusters
 -u <username>
  Username to access Cloudera Manager service
 -p <password>
  Password to access Cloudera Manager service

Examples: 

${basename $0} cdhmaster1 chdmaster2

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


get_cluster_config() {
  cdh_host=$1
  url="http://${cdh_host}:7180/api/v1/clusters"

  FILE_NAME="${DIFF_DIR}/${cdh_host}_${TIME_SPEC}.cfg"
  echo > $FILE_NAME

  cluster=`curl -s -u "${USER}:${PASSWORD}" $url | grep name | awk -F: '{print $2}' | tr -d '",' | sed -e 's/^ //' -e "s/ /\%20/g" `

  for service in `curl -s -u "${USER}:${PASSWORD}" $url/$cluster/services | grep name| awk -F: '{print $2}' | tr -d '", ' | sed 's/[A-Z_0-9]*//g' | sort `
  do
    echo "----- $service ------" >> $FILE_NAME
    curl -s -u "$USER:$PASSWORD" "$url/$cluster/services/$service/config?view=summary" >> $FILE_NAME
  done
}


# Default values. Do not change! 

VERBOSE=1
STORE_DIFF=0
RETAIN_DIFF=0


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
    -u)
      shift
      USER=$1
      shift
      ;;
    -p)
      shift
      USER=$1
      shift
      ;;
    -c)
      shift
      LOG_FILE=/dev/null
      ;;
    -s)
      shift
      STORE_DIFF=1
      ;;      
    -r)
      shift
      RETAIN_DIFF=1
      ;;      
    -*) echo "ERROR: Unknown option: $1" >&2
      exit 1
      ;;
    *)  break
      ;;
  esac
done


if [ ! -d $DIFF_DIR ]; then 
  mkdir -p $DIFF_DIR
fi

host=$1
host1=$2

DIFF_FILE=$DIFF_DIR/${host}${host1}_${TIME_SPEC}.diff
CUR_DIFF=$DIFF_DIR/${host}${host1}_${TIME_SPEC}_diff.diff
KNOWN_DIFF=$DIFF_DIR/${host}${host1}_known.diff

get_cluster_config $host

log_verbose "Got cluster configuration for ${host} into $FILE_NAME"

host_file=$FILE_NAME

get_cluster_config $host1

log_verbose "Got cluster configuration for ${host1} into $FILE_NAME"

host1_file=$FILE_NAME

log_verbose "Generating diffs..."

diff --label $host --label $host1 -u $host_file $host1_file > $DIFF_FILE

if [ -f $KNOWN_DIFF ]; then
  diff --label new --label old --suppress-common-lines -U 0 $DIFF_FILE $KNOWN_DIFF > $CUR_DIFF
  if [ "$STORE_DIFF" = "1" ];  then
    cp $DIFF_FILE $KNOWN_DIFF
  fi
  cat $CUR_DIFF
else
  cp $DIFF_FILE $KNOWN_DIFF
  cat $DIFF_FILE
fi

if [ "$RETAIN_DIFF" = "0" ]; then
  rm -f $host_file $host1_file $DIFF_FILE
  if [ ! -s $CUR_DIFF ]; then 
    rm -f $CUR_DIFF
  fi
fi


