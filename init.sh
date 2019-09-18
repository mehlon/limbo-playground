#/dis/sh
port=$1

svc/httpd/httpd -a tcp!*!$port
