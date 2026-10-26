#!/bin/bash
# Start script for pulp-web. Points nginx at Podman's DNS so it re-resolves
# pulp_api and pulp_content every 10s (containers can change IP on restart).

set -e

if [ "$container" == "podman" ]; then
  export NAMESERVER=`cat /etc/resolv.conf | grep "nameserver" | awk '{print $2}' | head -n1`
else
  export NAMESERVER=`cat /etc/resolv.conf | grep "nameserver" | awk '{print $2}' | tr '\n' ' '`
fi

echo "Nameserver is: $NAMESERVER"

echo "Generating nginx config"
envsubst '$NAMESERVER' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

for file in /etc/nginx/pulp/*.conf ; do
  echo "Modifying $file"
  sed -i 's/pulp-api/$pulp_api:24817/' $file
  sed -i 's/pulp-content/$pulp_content:24816/' $file
done

echo "Starting nginx"
exec nginx  -g "daemon off;"
