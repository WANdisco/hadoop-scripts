#!/bin/bash

# be strict about permissions for logs and sentry query files.
umask 077

LOG_DIR="/tmp"
LOG_FILE="${LOG_DIR}/$(basename $0 .sh)_`date +"%Y_%m_%d_%H_%M_%S"`.log"
EXEC_FILE="${LOG_DIR}/$(basename $0 .sh)_`date +"%Y_%m_%d_%H_%M_%S"`.sentry"

HIVE_CMD="/usr/bin/beeline"
#HIVE_CMD=`type -p beeline`
HIVE_USER=hive
HIVE_PASSWORD=hive
HIVESERVER2=testserver
HIVESERVER_PORT=10000
HIVE_PRINCIPAL="hive/_HOST@TEST.COM"

HIVE_URL="jdbc:hive2://$HIVESERVER2:${HIVESERVER_PORT}/default;principal=$HIVE_PRINCIPAL"


HIVE_CMD="${HIVE_CMD} -n $HIVE_USER -p $HIVE_PASSWORD -u \"$HIVE_URL\""

# Default values. Do not change! 
VERBOSE=1
VERBOSE_HIVE=0
NOCHANGE=0
LOG_CURRENT=0
RETAIN_SQL=0


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
 --log_current
  Log current state of the file before applying the new permissions  
 -c 
  Do not log into the log file, just output to console.   
 -r 
  Retain .sentry file containing all grant statements
 -v --verbose
  Be verbose. For now just output the hadoop command before executing it.

Examples: 

testdb bill select
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
    ${HIVE_CMD} "$@" 2>&1 | tee -a $LOG_FILE
  fi
}


write_hive_command() {
  if [ "$VERBOSE_HIVE" = "1" ]; then
    echo "-----> $@" | tee -a $LOG_FILE
  fi
  echo "$@" >> $EXEC_FILE
}



update_sentry_permissions() {
  pattern=$1
  role=$2
  permissions=$3

  if [ x"$permissions" = "x" ]; then
    # This is a role pattern
    if [ "$LOG_CURRENT" = "1" ]; then
      write_hive_command "SHOW ROLE GRANT GROUP $role;"
    fi
    log_verbose "Granting role $pattern to group $role"
    write_hive_command "GRANT ROLE $pattern TO GROUP $role;"
    return
  fi

  if [[ "$pattern" =~ [.] ]]; then
    # This is a table pattern
    if [ -z $role ] || [ -z $permissions ]; then
      echo "Invalid pattern: $pattern $role $permissions"
      return
    fi
    set -- "$pattern"
    IFS="."; declare -a arr=($*)
    IFS=" "
    if [ "$LOG_CURRENT" = "1" ]; then
      write_hive_command "SHOW GRANT ROLE $role;"
    fi    
    log_verbose "Granting $permissions permissions on $pattern to $role"
    write_hive_command "USE ${arr[0]};"
    write_hive_command "GRANT $permissions ON TABLE ${arr[1]} TO ROLE $role;"
    return
  else
    if [[ $pattern =~ [/] ]]; then
      # This is a path pattern
      if [ -z $role ] || [ -z $permissions ]; then
        echo "Invalid pattern: $pattern $role $permissions"
        return
      fi
      if [ "$LOG_CURRENT" = "1" ]; then
        write_hive_command "SHOW GRANT ROLE $role;"
      fi          
      log_verbose "Granting $permissions permissions on $pattern to $role"
      write_hive_command "GRANT $permissions ON URI '$pattern' TO ROLE $role;"
      return
    else
      if [ -n $role ] && [ -n $permissions ]; then
        # This is a table.
        if [ "$LOG_CURRENT" = "1" ]; then
          write_hive_command "SHOW GRANT ROLE $role;"
        fi            
        log_verbose "Granting $permissions permissions on $pattern to $role"
        write_hive_command "GRANT $permissions ON DATABASE $pattern TO ROLE $role;"
        return
      else
          # Some parameter here... don't support it for now...
          echo "Unsupported combination"
      fi
    fi
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
    --log_current)
      shift
      LOG_CURRENT=1
      ;;      
    -c)
      shift
      LOG_FILE=/dev/null
      ;;
    -r)
      shift
      RETAIN_SQL=1
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
    if [[ "$pattern" =~ \'.* ]]; then 
      echo "${pattern//\'}" "${role//\'}" "${permission//\'}" "${parameters//\'}" ";" >> $EXEC_FILE
    else
      update_sentry_permissions $pattern $role $permission $parameters    
    fi
done < $FILE

if [ -s $EXEC_FILE ]; then
  exec_hive_command "-f" "$EXEC_FILE"
fi

if [ "$RETAIN_SQL" = "0" ]; then
  rm -f $EXEC_FILE
fi


