#!/bin/bash

LOG_DIR="/tmp"
LOG_FILE="${LOG_DIR}/$(basename $0 .sh)_`date +"%Y_%m_%d_%H_%M_%S"`.log"

HIVE_CMD="/usr/bin/hive"
#HIVE_CMD=`type -p hive`

# Default values. Do not change! 
VERBOSE=1
VERBOSE_HIVE=0
NOCHANGE=0
LOG_CURRENT=0


trap '' ERR

usage() {
  cat >&2<<!!
Usage: $(basename $0) [-h] <file>

Grants sentry permissions based on the line supplied in the <file> 
Each line should represent one of the following patterns: 

<database> <role> <permissions>
<database>.<table name> <role> <permissions> 

<role> <group> 

</hdfs path> <role> <permissions> 

Options: 

 -h --help
  Display this help message.
 -n --nochange
  Do not actually change anything, just print the intent.
 -q --quiet
  Turn off verbosity. Do not write any log messages, etc.
 -v --verbose
  Be verbose. For now just output the hadoop command before executing it.

Examples: 

testdb bill read
testdb.table1 bill all
bill admins
/testdb bill all

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



exec_hive_command() {
  if [ "$NOCHANGE" = "1" ] || [ "$VERBOSE_HIVE" = "1" ]; then
    echo "**** $HIVE_CMD $@" | tee -a $LOG_FILE
  fi

  if [ "$NOCHANGE" = "0" ]; then
    ${HIVE_CMD} $@ 2>&1 | tee -a $LOG_FILE
  fi
}


update_sentry_permissions() {
  pattern=$1
  GRANT_TYPE=

if [ x"$3" = "x" ]; then
  # This is a role pattern
  log_verbose "Granting role $pattern to group $2"
  exec_hive_command "-e" "\"GRANT ROLE $pattern TO GROUP $2\""
  return
fi


  if [[ "$pattern" =~ [.] ]]; then
    # This is a table pattern
    if [ -z $2 ] || [ -z $3 ]; then
      echo "Invalid pattern: $1 $2 $3"
      return
    fi
    GRANT_TYPE="TABLE"
  else
    if [[ $pattern =~ [/] ]]; then
      # This is a path pattern
      if [ -z $2 ] || [ -z $3 ]; then
        echo "Invalid pattern: $1 $2 $3"
        return
      fi
      GRANT_TYPE="URI"
    else
      if [ -n $2 ] && [ -n $3 ]; then
        # This is a table.
        GRANT_TYPE="DATABASE"
      else
          # Some parameter here... don't support it for now...
          echo "Unsupported combination"
      fi
    fi
  fi

  if [ -n $GRANT_TYPE ]; then
    log_verbose "Granting $3 permissions on $pattern to $2"
    exec_hive_command "-e" "\"GRANT $3 ON $GRANT_TYPE '$pattern' TO ROLE $2\""
  fi
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
      VERBOSE_HIVE=1     
      ;;      
    -n | --nochange)
      shift
      NOCHANGE=1
      ;;
    --l)
      shift
      LOG_FILE=/dev/null
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
  echo "No file parameter found. Please run me with -h for usage"
  exit 1
fi

log_verbose "Reading patterns list from file: $FILE"

while read pattern role permission parameters; do
    # Skip comments
    [[ "$pattern" =~ \#.* ]] && continue
    # Skip empty lines
    [ -z "$pattern" ] && continue
    update_sentry_permissions $pattern $role $permission $parameters
done < $FILE

