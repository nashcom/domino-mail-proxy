#!/bin/bash
############################################################################
# Copyright Nash!Com, Daniel Nashed 2023-2025 - APACHE 2.0 see LICENSE
############################################################################

if [ "$1" = "alpine" ]; then
  BASE_IMAGE=alpine
elif [ "$1" = "ubi" ]; then
  BASE_IMAGE=registry.access.redhat.com/ubi9/ubi-minimal
fi

if [ -z "$BASE_IMAGE" ]; then
  BASE_IMAGE=alpine
fi

if [ -z "$NGINX_VER" ]; then
  NGINX_VER=1.27.4
fi

if [ -z "$IMAGE_NAME" ]; then
  IMAGE_NAME=nashcom/domino-mail-proxy
fi


BASE_IMAGE=nashcom/domino-mail-proxy:latest

# --------------------

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

print_runtime()
{
  hours=$((SECONDS / 3600))
  seconds=$((SECONDS % 3600))
  minutes=$((seconds / 60))
  seconds=$((seconds % 60))
  h=""; m=""; s=""
  if [ ! $hours = "1" ] ; then h="s"; fi
  if [ ! $minutes = "1" ] ; then m="s"; fi
  if [ ! $seconds = "1" ] ; then s="s"; fi
  if [ ! $hours = 0 ] ; then echo "Completed in $hours hour$h, $minutes minute$m and $seconds second$s"
  elif [ ! $minutes = 0 ] ; then echo "Completed in $minutes minute$m and $seconds second$s"
  else echo "Completed in $seconds second$s"; fi
  echo
}

header "Building NGINX $NGINX_VER on $BASE_IMAGE ..."

export BUILDKIT_PROGRESS=plain

docker build --no-cache -t $IMAGE_NAME --build-arg BASE_IMAGE=$BASE_IMAGE --build-arg NGINX_VER=$NGINX_VER .

echo
print_runtime

