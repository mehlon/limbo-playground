#/dis/sh
port=`{os sh -c 'echo $PORT'}

home=/usr/app
mkdir /tmp

memfs
bind -b /usr/app/appl /dis/svc/httpd
bind -a /usr/app/dis /dis
bind -a /usr/app/httpd /services/httpd
ls /services/httpd/*

echo starting httpd on -$port-
svc/httpd/httpd -a tcp!*!$port
