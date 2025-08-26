# K000152816
Code for the project described in MyF5 KB article K000152816

This script should only be used when you want to upload a large BIG-IP ISO image file to a BIG-IQ system using iControl REST API. This script requires 2 parameters when invoked; the management IP address of BIG-IQ system and the filename of the BIG-IP ISO file. The assumption is the BIG-IP ISO file resides in the same directory as this script. You should have the following utilities installed on the Linux workstation you want to run this script:

* curl
* jq
* printf
* stat
* dd
* md5sum
