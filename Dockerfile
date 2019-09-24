FROM mehlon/purgatorio

# docker run -p 8080:8080 -it mehlon/kek
ENV PORT=8080
EXPOSE 8080

# $INFERNO is defined by Inferno's Dockerfile to be /usr/inferno
COPY . $INFERNO/usr/app
WORKDIR $INFERNO/usr/app
RUN cd appl; limbo *.b

CMD ["emu", "/usr/app/init.sh"]

