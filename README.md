# Limbo Playground

This depends on [9front purgatorio](http://code.9front.org/hg/purgatorio/).
For a pre-built image: `docker pull mehlon/kek`.

Build it locally:
```
docker build -t mehlon/kek .
docker run -p 8080:8080 -it mehlon/kek
```

This works with Heroku:
```
APPNAME=buildpack-heroku # modify this 
heroku container:push web -a $APPNAME
heroku container:release web -a $APPNAME
```

