#!/bin/bash

GENERATE_KRB5_CONF=0
DOMAIN_NAME=
MY_IPADDR=`hostname -i`

trap '' ERR

usage() {
  cat >&2<<!!
Usage: $(basename $0) [-f <hostnames file>] [-g] <kerberos realm name>

Initializes kerberos setup on a given master node.
This will initialize all necessary configuration files as well as generate keytabs for each of the nodes. 
There will be different keytabs generated for each of the services: 
hive, hadoop, hbase, spark, shark and zookeeper. 
If -f parameter is omitten the script will look for default hostnames.txt in the current folder.

Options: 

 -h --help
  Display this help message.
 -g <domain name>
  Generate krb5.conf based on the internal template, and domain name.
 -f <filename>
  File containing host names as in a same way as slaves file in hadoop configuration. These will be used to 
  generate specific host keytab entries. 

Examples: 

${basename $0} KRBTEST -f /etc/hadoop/slaves

!!
}


generate_krb5_cfg() {
  cat > /etc/krb5.conf<<!!
[logging]
 default = FILE:/var/log/krb5libs.log
 kdc = FILE:/var/log/krb5kdc.log
 admin_server = FILE:/var/log/kadmind.log

[libdefaults]
 default_realm = ${krb_realm}
 dns_lookup_realm = false
 dns_lookup_kdc = false
 ticket_lifetime = 24h
 renew_lifetime = 7d
 forwardable = true

default_tkt_enctypes = arcfour-hmac-md5 des-cbc-crc des-cbc-md5
default_tgs_enctypes = arcfour-hmac-md5 des-cbc-crc des-cbc-md5

[realms]
 ${krb_realm} = {
 kdc = ${MY_IPADDR}
 admin_server = ${MY_IPADDR}
 default_domain = ${DOMAIN_NAME}
 }

 [domain_realm]
 .${DOMAIN_NAME} = ${krb_realm}

[appdefaults]
 pam = {
 debug = false
 ticket_lifetime = 60d
 renew_lifetime = 60d
 forwardable = true
 krb4_convert = false
 validate = true
 }

[login]
 krb4_convert = true
 krb4_get_tickets = false
!!  
}

generate_kdc_conf() {
  cat > /var/kerberos/krb5kdc/kdc.conf<<!!
[kdcdefaults]
 kdc_ports = 88
 kdc_tcp_ports = 88

[realms]
 ${krb_realm} = {
  master_key_type = des3-hmac-sha1
  acl_file = /var/kerberos/krb5kdc/kadm5.acl
  dict_file = /usr/share/dict/words
  admin_keytab = /var/kerberos/krb5kdc/kadm5.keytab
  max_renewable_life = 7d 0h 0m 0s
  max_life = 2d 0h 0m 0s
  default_principal_flags = +renewable
  krbMaxTicketLife = 172800
  krbMaxRenewableAge = 604800
  supported_enctypes = aes256-cts:normal aes128-cts:normal des3-hmac-sha1:normal arcfour-hmac:normal des-hmac-sha1:normal des-cbc-md5:normal des-cbc-crc:normal
 }
!!  
}

generate_kadm5_acl() {
  cat > /var/kerberos/krb5kdc/kadm5.acl<<!!
  */admin@${krb_realm}     *
!!  
}



# Read command line parameters
while true; do
  case "$1" in
    -h | --help)
      shift
      usage
      exit 0
      ;;
    -f)
      shift
      HOSTS_FILE=$1
      shift
      ;;
    -f)
      shift
      HOSTS_FILE=$1
      shift
      ;;
    -g)
      shift
      GENERATE_KRB5_CONF=1
      DOMAIN_NAME=$1
      shift
      ;;      
    -*) echo "ERROR: Unknown option: $1" >&2
      exit 1
      ;;
    *)  break
      ;;
  esac
done

HOSTS_FILE=${HOSTS_FILE:-"hostnames.txt"}


[ -r "${HOSTS_FILE}" ] || {
  echo "File ${HOSTS_FILE} does not exist or is not readable"
  exit 1
}

krb_realm=$1

# check if krb5.conf exists and contains the given realm. 
krb5conf=`grep ${krb_realm} /etc/krb5.conf`

if [ "x${krb5conf}" = "x" ]; then
  echo "krb5 doesn't contain realm ${krb_realm}. "
  if [ "$GENERATE_KRB5_CONF" = "0" ]; then
    echo "Please manually edit krb5.conf and re-run this script."
    echo " Alternatively you may pass -g <domain> parameter to automatically generate krb5.conf"
    exit 1
  else
    echo "Generating /etc/krb5.cfg using internal template. Please edit and distribute among nodes in your cluster"
    generate_krb5_cfg
  fi
fi

kdcconf=`grep ${krb_realm} /var/kerberos/krb5kdc/kdc.conf`
if [ "x${kdcconf}" = "x" ]; then
  echo "Generating /var/kerberos/krb5kdc/kdc.conf using internal template. Please edit if necessary"
  generate_kdc_conf
  generate_kadm5_acl
fi

echo "Generating kdc files with krb5_util"
krb5_util create -r ${krb_realm} -s

echo "Now adding root principal"
kadmin.local<<!!
addprinc root/admin
ktadd -k /var/kerberos/krb5kdc/kadm5.keytab kadmin/admin
ktadd -k /var/kerberos/krb5kdc/kadm5.keytab kadmin/changepw
!!

echo "Now starting kerberos..."
/etc/init.d/krb5kdc start
/etc/init.d/kadmin start
chkconfig krb5kdc on
chkconfig kadmin on


echo "Generating keytabs for hadoop services..."


for name in $(cat ${HOSTS_FILE}); do
  install -o root -g root -m 0700 -d ${name}

kadmin.local <<EOF
addprinc -randkey host/${name}@${krb_realm}
addprinc -randkey http/${name}@${krb_realm}
addprinc -randkey hdfs/${name}@${krb_realm}
addprinc -randkey mapred/${name}@${krb_realm}
addprinc -randkey hadoop/${name}@${krb_realm}
addprinc -randkey hive/${name}@${krb_realm}
addprinc -randkey spark/${name}@${krb_realm}
addprinc -randkey shark/${name}@${krb_realm}
addprinc -randkey hbase/${name}@${krb_realm}
addprinc -randkey zookeeper/${name}@${krb_realm}
ktadd -k ${name}/hadoop.keytab -norandkey \
  hdfs/${name}@${krb_realm} http/${name}@${krb_realm} mapred/${name}@${krb_realm} host/${name}@${krb_realm} hadoop/${name}@${krb_realm}
ktadd -k ${name}/hive.keytab -norandkey \
  hive/${name}@${krb_realm} 
ktadd -k ${name}/spark.keytab -norandkey \ 
  spark/${name}@${krb_realm} shark/${name}@${krb_realm} 
ktadd -k ${name}/hbase.keytab -norandkey \
  hbase/${name}@${krb_realm}
ktadd -k ${name}/zookeeper.keytab -norandkey \
  zookeeper/${name}@${krb_realm}
EOF

done

echo "All Done. Please distribute keytabs among the nodes in your cluster"

