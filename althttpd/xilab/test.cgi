#!/bin/sh
echo "Content-Type: text/plain"
echo ""
echo "Hello CGI world!"
echo ""
echo "GATEWAY_INTERFACE=$GATEWAY_INTERFACE"
echo "REQUEST_URI=$REQUEST_URI"
echo "SCRIPT_NAME=$SCRIPT_NAME"
echo "PATH_INFO=$PATH_INFO"
echo "QUERY_STRING=$QUERY_STRING"
echo ""
/bin/date
echo -n "Identity: " && /usr/bin/id
