#!/dis/sh
load std

bind -c '#U*'/workspace/limbo-playground /usr/app
home=/usr/app
if {! ftest -f -s /env/port} {
	port=`{os sh -c 'echo -n $PORT'}
}
{cd $home/appl; limbo kek.b}

#memfs
bind -b /usr/app/appl /dis/svc/httpd
bind -a /usr/app/dis /dis
bind -a /usr/app/httpd /services/httpd
ls /services/httpd/*

echo starting httpd on -$port-
svc/httpd/httpd -a tcp!*!$port
