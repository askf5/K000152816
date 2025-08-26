#!/usr/bin/bash
#
# This script should only be used when you want to upload a large BIG-IP ISO image file to a BIG-IQ system.
# This script is adapted using the script from https://my.f5.com/manage/s/article/K41763344
# Specifically, the blocknumber needed to be reduced for the chunk size to be accepted by BIG-IQ.
# Additionally both curl and jq utilities must be installed on your workstation for this script to work properly. 
# This script requires 2 parameters when invoked; the management IP address of BIG-IQ and the filename of the BIG-IP ISO file.
# The assumption is the BIG-IP ISO file resides in the same directory as this script. 

if [ $# -eq 0 ]
  then
    echo "$0 <BIQ IP> <ISO FILE NAME>"
    exit 1
fi

# Setting the variables.
IP=$1
BIQPATH=$(echo $PWD)
UPLOADFILE=$BIQPATH/$2

# Read the admin password from command line so as to obtain the login token from BIG-IQ.
read -s -p "Enter the BIG-IQ admin password: " PASSWORD

# Get the login token from BIG-IQ.
response=$(curl -ks -X POST -d "{\"username\":\"admin\", \"password\":"$PASSWORD", \"loginProviderName\":\"local\"}" https://$IP/mgmt/shared/authn/login)

F5TOKEN=$(echo $response | jq .token.token)

# Length of file in bytes
filelength=$(stat -c%s $UPLOADFILE)

# Location/name of temporary file to hold the chunk
tempfile=/tmp/tempfile

# Initialize at Offset 0 so read starts at the 1st byte
offset=0

# Initialize end to -1 for single POST case
end=-1

# Initialize Connection type at Keep-Alive
connection="Keep-Alive"

# dd has a default block size of 512. It is specified manually here to allow tuning.
blocksize=512
# blocknumber * blocksize = total size of file segment
# Number of blocks to read at a time.
blocknumber=15360

printf "\nUploading $2 to $1.\n"

# Begin loop to iterate through the file and upload in chunks
while true
do

	# Copy portion of file into tempfile as a chunk
	/bin/dd status=none if=$UPLOADFILE of=$tempfile count=$blocknumber skip=$offset bs=$blocksize     2> /dev/null

	# Determine length of segment
	chunklength=$(stat -c%s $tempfile)

	# Determine if this segment completes the filelength
	if [ $(( $end + $chunklength + 1 )) -eq $filelength ]; then
		# This is last segment, set connection to Close
		connection=Close
	fi

	# Set start and end for this segment
	start=$(( $offset * $blocksize ))

	# end -1 to adjust to zero-based
	end=$(( $start + $chunklength - 1 ))

	# Make the POST request, uploading the content chunk
	uploadresponse=$(/usr/bin/curl -ks -X POST -H "Content-Type: application/octet-stream" -H "X-F5-Auth-Token: "$F5TOKEN"" -H "Content-Range: $start-$end/$filelength" -H "Connection: $connection" https://$IP/mgmt/cm/autodeploy/software-image-uploads/$2 --data-binary @$tempfile)
	uploadremain=$(echo $uploadresponse | jq '.remainingByteCount / .totalByteCount * 100')
	formatted_uploadremain=$(printf "%.1f" "$uploadremain")
	printf "\r$formatted_uploadremain percent remaining..."

	# If this was final segment, end loop
	if [ $connection = "Close" ]; then
		# Print complete
		printf "done.\n"
		break
	fi

	# Increment the offset by the number of blocks read at a time
	offset=$(( $offset + $blocknumber ))
done

# Delete the tempfile
rm -f /tmp/tempfile

# Display md5sum for the local file to compare to remote file
printf "Calculating md5sum for $2 to compare to uploaded file:\n"
md5sum $2
