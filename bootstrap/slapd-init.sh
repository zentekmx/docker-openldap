#!/bin/sh
set -eu

readonly DATA_DIR="/bootstrap/data"
readonly CONFIG_DIR="/bootstrap/config"

readonly LDAP_SSL_KEY="/etc/ldap/ssl/ldap.key"
readonly LDAP_SSL_CERT="/etc/ldap/ssl/ldap.crt"

reconfigure_slapd() {
    echo "Reconfigure slapd..."
    cat <<EOL | debconf-set-selections
slapd slapd/internal/generated_adminpw password ${LDAP_SECRET}
slapd slapd/internal/adminpw password ${LDAP_SECRET}
slapd slapd/password2 password ${LDAP_SECRET}
slapd slapd/password1 password ${LDAP_SECRET}
slapd slapd/dump_database_destdir string /var/backups/slapd-VERSION
slapd slapd/domain string ${LDAP_DOMAIN}
slapd shared/organization string ${LDAP_ORGANIZATION}
slapd slapd/backend string HDB
slapd slapd/purge_database boolean true
slapd slapd/move_old_database boolean true
slapd slapd/allow_ldap_v2 boolean false
slapd slapd/no_configuration boolean false
slapd slapd/dump_database select when needed
EOL

    DEBIAN_FRONTEND=noninteractive dpkg-reconfigure slapd
}


make_snakeoil_certificate() {
    echo "Make snakeoil certificate for ${LDAP_DOMAIN}..."
    openssl req -subj "/CN=${LDAP_DOMAIN}" \
                -new \
                -newkey rsa:2048 \
                -days 365 \
                -nodes \
                -x509 \
                -keyout ${LDAP_SSL_KEY} \
                -out ${LDAP_SSL_CERT}

    chmod 600 ${LDAP_SSL_KEY}
}


configure_tls() {
    echo "Configure TLS..."
    ldapmodify -Y EXTERNAL -H ldapi:/// -f ${CONFIG_DIR}/tls.ldif -Q
}


configure_logging() {
    echo "Configure logging..."
    ldapmodify -Y EXTERNAL -H ldapi:/// -f ${CONFIG_DIR}/logging.ldif -Q
}

configure_msad_features(){
  echo "Configure MS-AD Extensions"
  ldapmodify -Y EXTERNAL -H ldapi:/// -f ${CONFIG_DIR}/msad.ldif -Q
}

replace_domain() {
  NEWDN=$(echo ${LDAP_DOMAIN} | awk -F. '{for (i=1; i<=NF; i++) printf ",dc="$i}')
  sed -i "s/,dc=zentek,dc=com,dc=mx/${NEWDN}/s;s/zentek.com.mx/${LDAP_DOMAIN}" ${DATA_DIR}/*.ldif
}

load_initial_data() {
  echo "Load data..."
  for ldif in $(ls ${DATA_DIR}/*.ldif | sort -n); do
    echo "Processing file ${ldif}..."
    ldapadd -x -H ldapi:/// \
          -D ${LDAP_BINDDN} \
          -w ${LDAP_SECRET} \
          -f ${ldif}
  done
}


## Main program ##

echo "LDAP_DOMAIN: ${LDAP_DOMAIN}"
echo "LDAP_ORGANIZATION: ${LDAP_ORGANIZATION}"
echo "LDAP_BINDDN: ${LDAP_BINDDN}"
echo "LDAP_SECRET: ${LDAP_SECRET}"

reconfigure_slapd
make_snakeoil_certificate
chown -R openldap:openldap /etc/ldap
slapd -h "ldapi:///" -u openldap -g openldap

configure_msad_features
configure_tls
configure_logging
[ ${LDAP_DOMAIN} != "zentek.com.mx" ] && replace_domain
load_initial_data

kill -INT `cat /run/slapd/slapd.pid`

exit 0

