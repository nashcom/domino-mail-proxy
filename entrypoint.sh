#!/bin/sh

############################################################################
# Copyright Nash!Com, Daniel Nashed 2025 - APACHE 2.0 see LICENSE
############################################################################

# This script is the main entry point for the NGINX container.
# The entry point is invoked by the container run-time to start NGINX.


log_space()
{
  echo
  echo "$@"
  echo
}

log_error()
{
  echo
  echo "ERROR - $@"
  echo
}

delim()
{
  echo  "------------------------------------------------------------"
}


header()
{
  echo
  delim
  echo "$@"
  delim
  echo
}


remove_file()
{
  if [ -z "$1" ]; then
    return 1
  fi

  if [ ! -e "$1" ]; then
    return 2
  fi

  rm -f "$1"
  return 0
}


create_local_ca_cert()
{
  local SERVER_HOST="$1"  
  local PREFIX=
  local MAX_CA_DAYS=3650
  local MAX_CERT_DAYS=365
  local NGINX_CONFIG_DIR

  if [ -z "$1" ]; then
    echo "Cannot create certficate: No host specified"
    return 0
  fi

  if [ -n "$2" ]; then
    PREFIX="$2_"
  fi

  if [ -z "$CERT_ORG" ]; then
    local CERT_ORG=DominoMailProxyServer
  fi

  if [ -z "$CA_CN" ]; then
    local CA_CN=MicroCA
  fi

  local SERVER_CRT=$CERT_DIR/${PREFIX}cert.pem
  local SERVER_KEY=$CERT_DIR/${PREFIX}key.pem
  local SERVER_CSR=$CERT_DIR/${PREFIX}csr.pem

  local CA_KEY=$CERT_DIR/ca_key.pem
  local CA_CRT=$CERT_DIR/ca_cert.pem
  local CA_SEQ=$CERT_DIR/ca.seq

  if [ ! -e "$CERT_DIR" ]; then
     mk -p "$CERT_DIR"
  fi

  if [ ! -w "$CERT_DIR" ]; then
    echo "Cannot write to certificate directory: $CERT_DIR"
    exit 1
  fi

  if [ ! -e "$CA_KEY" ]; then
    echo "Creating CA key: $CA_KEY"
    openssl ecparam -name prime256v1 -genkey -noout -out $CA_KEY > /dev/null 2>&1 
  fi

  if [ ! -e "$CA_KEY" ]; then
    log_error "Cannot create CA key: $CA_KEY"
    exit 1
  fi

  if [ ! -e "$CA_CRT" ]; then
    echo "Create CA certificate: $CA_CRT"
    openssl req -new -x509 -days $MAX_CA_DAYS -key $CA_KEY -out $CA_CRT -subj "/O=$CERT_ORG/CN=$CA_CN" > /dev/null 2>&1
  fi

  if [ ! -e "$CA_CRT" ]; then
    log_error "Cannot create CA certificate: $CA_CRT"
    exit 1
  fi

  # Create server key
  if [ ! -e "$SERVER_KEY" ]; then
    echo "Create server key: $SERVER_KEY"
    openssl ecparam -name prime256v1 -genkey -noout -out $SERVER_KEY > /dev/null 2>&1
  fi

  if [ ! -e "$SERVER_KEY" ]; then
    log_error "Cannot create server key: $SERVER_KEY"
    exit 1
  fi

  openssl req -new -key $SERVER_KEY -out $SERVER_CSR -subj "/O=$CERT_ORG/CN=$SERVER_HOST" -addext "subjectAltName = DNS:$SERVER_HOST" -addext extendedKeyUsage=serverAuth > /dev/null 2>&1

  if [ ! -e "$SERVER_CSR" ]; then
    log_error "Cannot create server CSR: $SERVER_CSR"
    exit 1
  fi

  echo "Creating certificate: [$SERVER_HOST] -> [$SERVER_CRT]"

  # NOTE: Copying extensions can be dangerous! Requests should be checked
  openssl x509 -req -days $MAX_CERT_DAYS -in $SERVER_CSR -CA $CA_CRT -CAkey $CA_KEY -out $SERVER_CRT -CAcreateserial -CAserial $CA_SEQ -copy_extensions copy > /dev/null 2>&1

  # A missing certificate will fail NGINX
  if [ ! -e "$SERVER_CRT" ]; then
    log_error "Cannot create certificate for: $SERVER_CRT"
    exit 1
  fi

  remove_file "$SERVER_CSR"
}


show_cert()
{
  if [ -z "$1" ]; then
    return 0
  fi

  if [ ! -e "$1" ]; then
    return 0
  fi

  local SAN=$(openssl x509 -in "$1" -noout -ext subjectAltName | grep "DNS:" | xargs )
  local SUBJECT=$(openssl x509 -in "$1" -noout -subject | cut -d '=' -f 2- )
  local ISSUER=$(openssl x509 -in "$1" -noout -issuer | cut -d '=' -f 2- )
  local EXPIRATION=$(openssl x509 -in "$1" -noout -enddate | cut -d '=' -f 2- )
  local FINGERPRINT=$(openssl x509 -in "$1" -noout -fingerprint | cut -d '=' -f 2- )
  local SERIAL=$(openssl x509 -in "$1" -noout -serial | cut -d '=' -f 2- )

  echo "SAN         : $SAN"
  echo "Subject     : $SUBJECT"
  echo "Issuer      : $ISSUER"
  echo "Expiration  : $EXPIRATION"
  echo "Fingerprint : $FINGERPRINT"
  echo "Serial      : $SERIAL"
}


# --- Main ---

# Configure defaults

if [ -z "$NGINX_LOG_LEVEL" ]; then
  export NGINX_LOG_LEVEL=warn
fi

if [ -z "$DOMMAILPROXY_HOST" ]; then
  export DOMMAILPROXY_HOST=$(hostname)
fi

if [ -z "$MAIL_SERVER_NAME" ]; then
  export MAIL_SERVER_NAME=$DOMMAILPROXY_HOST
fi

if [ -z "$AUTH_SERVER_PORT" ]; then
  export AUTH_SERVER_PORT=443
fi

if [ -z "$SMTP_PORT" ]; then
  export SMTP_PORT=25 
fi

if [ -z "$SMTP_TLS_PORT" ]; then
  export SMTP_TLS_PORT=465
fi

if [ -z "$POP3_TLS_PORT" ]; then
  export POP3_TLS_PORT=995
fi

if [ -z "$IMAP_TLS_PORT" ]; then
  export IMAP_TLS_PORT=993
fi

if [ -z "$SMTP_AUTH" ]; then
  export SMTP_AUTH="login plain cram-md5"
fi

if [ -z "$SMTP_TLS_AUTH" ]; then
  export SMTP_TLS_AUTH="login plain cram-md5"
fi

if [ -z "$NGINX_LOG_LEVEL" ]; then
  export NGINX_LOG_LEVEL="plain apop cram-md5"
fi

if [ -z "$POP3_TLS_AUTH" ]; then
  export POP3_TLS_AUTH="login plain cram-md5"
fi

if [ -z "$IMAP_TLS_AUTH" ]; then
  export IMAP_TLS_AUTH=
fi

NGINX_CFG_DIR=/nginx-cfg
NGINX_LOG_DIR=/nginx-log
NGINX_CONF=$NGINX_CFG_DIR/nginx.conf

if [ -z "$CERT_DIR" ]; then
  CERT_DIR=$NGINX_CFG_DIR
fi

# Copy default configuration if no configruation is present
if [ ! -e "$NGINX_CONF" ]; then
  cp /nginx_template.conf "$NGINX_CONF"
fi

# Substistute variables and create configuration

# Names which need to stay untranslated

export name='$name'
export request_uri='$request_uri'

if [ ! -e "$NGINX_CONF" ]; then
  
  log_error "No configuration found: $NGINX_CONF"
  exit 1
fi


envsubst < "$NGINX_CONF" > "/tmp/nginx/nginx.conf"

export name=
export request_uri=

LINUX_PRETTY_NAME=$(cat /etc/os-release | grep "PRETTY_NAME="| cut -d= -f2 | xargs)

# Set more paranoid umask to ensure files can be only read by user
umask 0077

# Create default log dicrectory as specfied in NGINX build
mkdir -p /tmp/nginx/logs

header "Environment"
env
delim


echo
echo
echo NGINX Domino Mail Proxy Server
delim
echo $LINUX_PRETTY_NAME
echo
nginx -V
echo

if [ -z "$SERVER_HOSTNAME" ]; then
  SERVER_HOSTNAME=$(hostname)  
fi


# Use custom certificate or create one on via MicroCA at every start
if [ -e "$CERT_DIR/custom_key.pem" ] && [ -e "$CERT_DIR/custom_cert.pem" ]; then

  cp -f "$CERT_DIR/custom_cert.pem" "$CERT_DIR/cert.pem"
  cp -f "$CERT_DIR/custom_key.pem"  "$CERT_DIR/key.pem"

else
  create_local_ca_cert "$SERVER_HOSTNAME"
fi

if [ -e $CERT_DIR/ca_cert.pem ]; then
  header "MicroCA Root Certificate"
  openssl x509 -in $CERT_DIR/ca_cert.pem -noout -subject | cut -d '=' -f 2-
  echo
  cat "$CERT_DIR/ca_cert.pem"
  echo
fi

header "Server Certficiate"
show_cert "$CERT_DIR/cert.pem"
echo
delim
echo

echo
echo
echo NGINX Domino Mail Proxy Server
delim
echo $LINUX_PRETTY_NAME
nginx -v
echo
echo $SERVER_HOSTNAME
echo
echo
echo "Configuration"
delim
echo

echo "Mail Server :  $MAIL_SERVER_NAME"
echo "Auth Server :  $AUTH_SERVER_NAME"
echo "Auth Port   :  $AUTH_SERVER_PORT"
echo "Auth URL    :  $AUTH_URL"
echo "Log Level   :  $NGINX_LOG_LEVEL"
echo

nginx -g 'daemon off;'

# Dump configurations if start failed. Else we are killed before dumping

sleep 2

header "/tmp/nginx/nginx.conf"
cat -n "/tmp/nginx/nginx.conf"

exit 0

