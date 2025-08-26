#!/usr/bin/bash
#
# This script lists the existing BIG-IP images residing on the BIG-IQ system in a JSON format.
# You can view these images on the BIG-IQ webUI under the Devices > SOFTWARE MANAGEMENT > Software Images page.
# You will need the curl and jq utilities to be installed on your workstation for this script to work properly.

if [ $# -eq 0 ]
  then
    echo "$0 <BIQ IP>"
    exit 1
fi

# Setting the variables.
IP=$1

# Read the admin password from command line so as to obtain the login token from BIG-IQ.
read -s -e -p "Enter the BIG-IQ admin password:" PASSWORD

# Get the login token from BIG-IQ.
response=$(curl -ks -X POST -d "{\"username\":\"admin\", \"password\":"$PASSWORD", \"loginProviderName\":\"local\"}" https://$IP/mgmt/shared/authn/login)

F5TOKEN=$(echo $response | jq .token.token)

/usr/bin/curl -ks -H "X-F5-Auth-Token: "$F5TOKEN"" https://$IP/mgmt/cm/autodeploy/software-images | /usr/bin/jq .
