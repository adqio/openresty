FROM        ubuntu:14.04
MAINTAINER  scott@switzer.org

# Get latest version of all tools
RUN apt-get -y update
RUN apt-get -y upgrade

# Install GeoIP
RUN apt-get -y install make geoip-bin geoip-database libgeoip-dev lua5.2 luarocks zlib1g-dev
WORKDIR /tmp
RUN wget http://geolite.maxmind.com/download/geoip/api/c/GeoIP.tar.gz
RUN tar -zxvf GeoIP.tar.gz && cd GeoIP-1.4.8 7  && ./configure && make && make install


# Install Openresty
ENV OPENRESTY_VERSION 1.5.8.1
RUN apt-get -y install curl libreadline-dev libncurses5-dev libpcre3-dev libssl-dev perl
RUN curl http://openresty.org/download/ngx_openresty-$OPENRESTY_VERSION.tar.gz > /usr/src/ngx_openresty-$OPENRESTY_VERSION.tar.gz
RUN cd /usr/src && tar xzf ngx_openresty-$OPENRESTY_VERSION.tar.gz
RUN cd /usr/src/ngx_openresty-$OPENRESTY_VERSION;\
    ./configure --with-luajit --with-http_geoip_module --with-http_stub_status_module;\
    make;\
    make install

# Fix nginx issue with too many nginx variables because of GeoIP (see https://github.com/agentzh/srcache-nginx-module/issues/21)
RUN sed -i 's/mime.types;/mime.types;\n    variables_hash_max_size 1024;/' /usr/local/openresty/nginx/conf/nginx.conf

# Run Nginx in the foreground so supervisor can manage (the 'Docker Way')
RUN sed -i 's/nobody;/nobody;\ndaemon off;/' /usr/local/openresty/nginx/conf/nginx.conf

# Add GeoIP Cron
RUN apt-get -y install cron
ADD geoip_cron /var/spool/cron/crontabs/ root

# Add supervisor to manage cron and nginx

# Open HTTP and SSL ports
EXPOSE 80 443
