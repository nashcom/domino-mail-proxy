

#!/bin/sh
############################################################################
# Copyright Nash!Com, Daniel Nashed 2023 - APACHE 2.0 see LICENSE
############################################################################

# --- Begin Helper functions ---

print_delim()
{
  echo "--------------------------------------------------------------------------------"
}

header()
{
  echo
  print_delim
  echo "$1"
  print_delim
  echo
}

install_package()
{
  if [ -x /usr/bin/zypper ]; then
    /usr/bin/zypper install -y "$@"

  elif [ -x /usr/bin/dnf ]; then
    /usr/bin/dnf install -y "$@"

  elif [ -x /usr/bin/tdnf ]; then
    /usr/bin/tdnf install -y "$@"

  elif [ -x /usr/bin/microdnf ]; then
    /usr/bin/microdnf install -y "$@"

  elif [ -x /usr/bin/yum ]; then
    /usr/bin/yum install -y "$@"

  elif [ -x /usr/bin/apt-get ]; then
    /usr/bin/apt-get install -y "$@"

   elif [ -x /sbin/apk ]; then
    /sbin/apk add "$@"

  else
    echo "No package manager found!"
    exit 1

  fi
}

install_packages()
{
  local PACKAGE=
  for PACKAGE in $*; do
    install_package $PACKAGE
  done
}

remove_package()
{
  if [ -x /usr/bin/zypper ]; then
    /usr/bin/zypper rm -y "$@"

  elif [ -x /usr/bin/dnf ]; then
    /usr/bin/dnf remove -y "$@"

  elif [ -x /usr/bin/tdnf ]; then
    /usr/bin/tdnf remove -y "$@"

  elif [ -x /usr/bin/microdnf ]; then
    /usr/bin/microdnf remove -y "$@"

  elif [ -x /usr/bin/yum ]; then
    /usr/bin/yum remove -y "$@"

  elif [ -x /usr/bin/apt-get ]; then
    /usr/bin/apt-get remove -y "$@"

  elif [ -x /sbin/apk ]; then
    /sbin/apk del "$@"

 fi
}

remove_packages()
{
  local PACKAGE=
  for PACKAGE in $*; do
    remove_package $PACKAGE
  done
}

check_linux_update()
{
  if [ -x /usr/bin/zypper ]; then

    header "Updating Linux via zypper"
    /usr/bin/zypper refresh
    /usr/bin/zypper update -y

  elif [ -x /usr/bin/dnf ]; then

    header "Updating Linux via dnf"
    /usr/bin/dnf update -y

  elif [ -x /usr/bin/tdnf ]; then

    header "Updating Linux via tdnf"
    /usr/bin/tdnf update -y

  elif [ -x /usr/bin/microdnf ]; then

    header "Updating Linux via microdnf"
    /usr/bin/microdnf update -y

  elif [ -x /usr/bin/yum ]; then

    header "Updating Linux via yum"
    /usr/bin/yum update -y

  elif [ -x /sbin/apk ]; then

    header "Updating Linux via apk"
    /sbin/apk update

  elif [ -x /usr/bin/apt-get ]; then

    header "Updating Linux via apt"

    echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

    /usr/bin/apt-get update -y

    # Needed by Astra Linux, Ubuntu and Debian. Should be installed before updating Linux but after updating the repo!
    if [ -x /usr/bin/apt-get ]; then
      install_package apt-utils
    fi

    /usr/bin/apt-get upgrade -y

  fi
}

clean_linux_repo_cache()
{
  if [ -x /usr/bin/zypper ]; then

    header "Cleaning zypper cache"
    /usr/bin/zypper clean --all >/dev/null
    rm -fr /var/cache

  elif [ -x /usr/bin/dnf ]; then

    header "Cleaning dnf cache"
    /usr/bin/dnf clean all >/dev/null

  elif [ -x /usr/bin/tdnf ]; then

    header "Cleaning tdnf cache"
    /usr/bin/tdnf clean all >/dev/null

  elif [ -x /usr/bin/microdnf ]; then

    header "Cleaning microdnf cache"
    /usr/bin/microdnf clean all >/dev/null

  elif [ -x /usr/bin/yum ]; then

    header "Cleaning yum cache"
    /usr/bin/yum clean all >/dev/null
    rm -fr /var/cache/yum

  elif [ -x /usr/bin/apt-get ]; then

    header "Cleaning apt cache"
    /usr/bin/apt-get clean

  elif [ -x /sbin/apk ]; then

    header "Cleaning apt cache"
    /sbin/apk cache clean
  fi
}

# --- End Helper functions ---


check_linux_update

if [ -x /sbin/apk ]; then
  # Alpine package names are different
  install_packages gettext findutils shadow pcre openssl libcap bash
else
  install_packages hostname gettext bind-utils findutils shadow-utils openssl
fi


# Add NGINX user

useradd nginx -U

# Create cfg and log directory

NGINX_CFG=/nginx-cfg
NGINX_LOG=/nginx-log
NGINX_CONF=$NGINX_CFG/nginx.conf

mkdir -p "$NGINX_CFG"
mkdir -p "$NGINX_LOG"
mkdir -p "/tmp/nginx"

mv /nginx.conf "$NGINX_CONF"

chown root:nginx /entrypoint.sh
chown root:nginx /usr/bin/nginx

chown -R nginx:nginx /tmp/nginx 
chown -R nginx:nginx "$NGINX_CFG"
chown -R nginx:nginx "$NGINX_LOG"

chmod 550 /entrypoint.sh
chmod 550 /usr/bin/nginx
chmod 440 "$NGINX_CONF" 

# Set capabilities to bind to ports below 1024
setcap 'cap_net_bind_service=+ep' /usr/bin/nginx
apk del libcap

check_linux_update
clean_linux_repo_cache


