#!/dis/sh
load std

home=/usr/app
if {~ $1 sh} {
	port=8080
	{cd $home; cd appl; limbo kek.b}
} { port=`{os sh -c 'echo $PORT'} }

#memfs
bind -b /usr/app/appl /dis/svc/httpd
bind -a /usr/app/dis /dis
bind -a /usr/app/httpd /services/httpd
ls /services/httpd/*

echo starting httpd on -$port-
svc/httpd/httpd -a tcp!*!$port
