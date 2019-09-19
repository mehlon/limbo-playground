FROM mehlon/inferno

# docker run -p 8080:8080 -it inferno
ENV PORT=8080
EXPOSE 8080

COPY . $INFERNO/usr/app
RUN mkdir $INFERNO/tmp
WORKDIR $INFERNO/usr/app
RUN cd appl; limbo *.b
CMD ["emu", "-c1", "sh", "/usr/app/init.sh"]
