FROM i386/ubuntu:devel

RUN apt-get -y update && apt-get install -y
RUN apt-get install -y libx11-dev  libxext-dev libc6-dev

# if on i386 there's no need for multilib
#RUN apt-get install -y libc6-dev-i386
#RUN apt-get install -y libx11-6:i386, libxext-dev:i386

COPY . /usr/src/dockertest1
WORKDIR /usr/src/dockertest1

EXPOSE 8080

# run the command
CMD ["/bin/sh", "./run.sh"]
