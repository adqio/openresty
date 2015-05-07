FROM       debian:jessie
MAINTAINER  afsheen@authenticated.digital

ENV DEBIAN_FRONTEND noninteractive
# Get latest version of all tools
RUN apt-get -y update && apt-get -y upgrade

# Install GeoIP
RUN apt-get -y update && apt-get -y install geoip-database libgeoip-dev git-core dh-autoreconf wget zlib1g-dev libcurl4-openssl-dev curl make automake autoconf libtool libreadline-dev libncurses5-dev libpcre3-dev libssl-dev perl libpq-dev

#Install GeoIP2

WORKDIR /usr/src
RUN git clone --recursive https://github.com/maxmind/libmaxminddb
RUN cd libmaxminddb && ./bootstrap && ./configure && make check && make install && ldconfig
RUN git clone https://github.com/leev/ngx_http_geoip2_module.git 

RUN wget https://github.com/maxmind/geoipupdate/releases/download/v2.0.2/geoipupdate-2.0.2.tar.gz
RUN wget https://github.com/alanxz/rabbitmq-c/releases/download/v0.5.2/rabbitmq-c-0.5.2.tar.gz && tar zxvf rabbitmq-c-0.5.2.tar.gz && cd rabbitmq-c-0.5.2 && ./configure && make && make install

RUN tar xzvf geoipupdate-2.0.2.tar.gz && cd geoipupdate-2.0.2 && ./configure && make  && make install
# Install Openresty
ENV OPENRESTY_VERSION 1.7.10.1

RUN curl http://openresty.org/download/ngx_openresty-$OPENRESTY_VERSION.tar.gz > /usr/src/ngx_openresty-$OPENRESTY_VERSION.tar.gz
RUN cd /usr/src && tar xzf ngx_openresty-$OPENRESTY_VERSION.tar.gz
RUN cd /usr/src/ngx_openresty-$OPENRESTY_VERSION;\
    ./configure --with-http_geoip_module --add-module=/usr/src/ngx_http_geoip2_module --with-http_postgres_module --with-http_stub_status_module;\
    make;\
    make install

# Fix nginx issue with too many nginx variables because of GeoIP (see https://github.com/agentzh/srcache-nginx-module/issues/21)
RUN sed -i 's/mime.types;/mime.types;\n    variables_hash_max_size 1024;/' /usr/local/openresty/nginx/conf/nginx.conf

# Run Nginx in the foreground so supervisor can manage (the 'Docker Way')
RUN sed -i 's/nobody;/nobody;\ndaemon off;/' /usr/local/openresty/nginx/conf/nginx.conf

RUN wget https://github.com/alanxz/rabbitmq-c/releases/download/v0.5.2/rabbitmq-c-0.5.2.tar.gz && tar zxvf rabbitmq-c-0.5.2.tar.gz && cd rabbitmq-c-0.5.2 && ./configure && make && make install

# Open HTTP and SSL ports
EXPOSE 80 443
