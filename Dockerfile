FROM debian:wheezy
MAINTAINER Romain GOUYET "docker@gouyet.com"
ENV REFRESHED_AT 2015-05-22
RUN echo "deb http://www.promixis.com/repo/debian/wheezy wheezy main" >> /etc/apt/sources.list
RUN apt-get -y -q update
RUN apt-get -y -q install wget
RUN wget -O - http://www.promixis.com/repo/debian/wheezy/sales.key | apt-key add -
RUN apt-get -y -q upgrade
RUN apt-get --force-yes -y -q install girder

RUN apt-get -y -q install libgl1-mesa-glx
RUN apt-get -y -q install libpng12-0
RUN apt-get -y -q install libegl1-mesa
RUN apt-get -y -q install libglib2.0-0
RUN apt-get -y -q install libpulse0
RUN rm /opt/girder/libpirlib.so.1
RUN rm /opt/girder/libpirlib.so.1.0
RUN rm /opt/girder/libprb16lib.so.1
RUN rm /opt/girder/libprb16lib.so.1.0
RUN rm /opt/girder/libprb16lib.so.1.0.0 
RUN rm /opt/girder/libprb16lib.so
RUN mkdir /opt/girder/qt/etc/xdg/Promixis
EXPOSE 20000
EXPOSE 80
#RUN mkdir /opt/girder/luaext
#VOLUME /opt/girder/luaext
VOLUME /opt/girder/qt/etc/xdg/Promixis
VOLUME /opt/girder/httpd
CMD /opt/girder/Girder6Service && tail -F /var/log/girder
