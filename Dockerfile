FROM        ubuntu:12.04
MAINTAINER  scott@switzer.org

# Get latest version of all tools
RUN apt-get -y update
RUN apt-get -y upgrade

# Install GeoIP
RUN apt-get -y install geoip-bin geoip-database libgeoip-dev git-core dh-autoreconf
RUN cp /etc/GeoIP.conf.default /etc/GeoIP.conf

#Install GeoIP2

WORKDIR /usr/src
RUN git clone --recursive https://github.com/maxmind/libmaxminddb
RUN cd libmaxminddb && ./bootstrap && ./configure && make check && make install && ldconfig
RUN git clone https://github.com/leev/ngx_http_geoip2_module.git 

# Install Openresty
ENV OPENRESTY_VERSION 1.5.8.1
RUN apt-get -y install curl make automake autoconf libtool
RUN apt-get -y install libreadline-dev libncurses5-dev libpcre3-dev libssl-dev perl
RUN curl http://openresty.org/download/ngx_openresty-$OPENRESTY_VERSION.tar.gz > /usr/src/ngx_openresty-$OPENRESTY_VERSION.tar.gz
RUN cd /usr/src && tar xzf ngx_openresty-$OPENRESTY_VERSION.tar.gz
RUN cd /usr/src/ngx_openresty-$OPENRESTY_VERSION;\
    ./configure --with-http_geoip_module --add-module=/usr/src/ngx_http_geoip2_module --with-http_stub_status_module;\
    make;\
    make install

# Fix nginx issue with too many nginx variables because of GeoIP (see https://github.com/agentzh/srcache-nginx-module/issues/21)
RUN sed -i 's/mime.types;/mime.types;\n    variables_hash_max_size 1024;/' /usr/local/openresty/nginx/conf/nginx.conf

# Run Nginx in the foreground so supervisor can manage (the 'Docker Way')
RUN sed -i 's/nobody;/nobody;\ndaemon off;/' /usr/local/openresty/nginx/conf/nginx.conf

# Install Luarocks
ENV LUAROCKS_VERSION 2.0.13
RUN curl http://luarocks.org/releases/luarocks-$LUAROCKS_VERSION.tar.gz > /usr/src/luarocks-$LUAROCKS_VERSION.tar.gz
RUN cd /usr/src && tar xzvf luarocks-$LUAROCKS_VERSION.tar.gz
RUN cd /usr/src/luarocks-$LUAROCKS_VERSION ;\
    ./configure --prefix=/usr/local/openresty/luajit \
        --with-lua=/usr/local/openresty/luajit/ \
        --lua-suffix=jit-2.1.0-alpha \
        --with-lua-include=/usr/local/openresty/luajit/include/luajit-2.1 ;\
    make ;\
    make install

# Add GeoIP Cron
RUN apt-get -y install cron
ADD geoip_cron /var/spool/cron/crontabs/ root

# Add supervisor to manage cron and nginx

# Open HTTP and SSL ports
EXPOSE 80 443
