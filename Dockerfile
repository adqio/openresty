FROM        ubuntu:13.10
MAINTAINER  scott@switzer.org


# Set the env variable DEBIAN_FRONTEND to noninteractive
ENV DEBIAN_FRONTEND noninteractive

# Get latest version of all tools
RUN apt-get -y update
RUN apt-get -y upgrade

# Install GeoIP, Luarocks, and OpenResty development libraries
RUN apt-get -y install geoip-bin geoip-database libgeoip-dev luarocks curl make libreadline-dev libncurses5-dev libpcre3-dev libssl-dev perl supervisor cron

# Add GeoIP configuration

RUN cp /etc/GeoIP.conf.default /etc/GeoIP.conf

# Install Openresty
ENV OPENRESTY_VERSION 1.5.11.1
RUN curl http://openresty.org/download/ngx_openresty-$OPENRESTY_VERSION.tar.gz > /usr/src/ngx_openresty-$OPENRESTY_VERSION.tar.gz
RUN cd /usr/src && tar xzf ngx_openresty-$OPENRESTY_VERSION.tar.gz
RUN cd /usr/src/ngx_openresty-$OPENRESTY_VERSION;\
    ./configure --with-http_geoip_module --with-http_stub_status_module;\
    make;\
    make install

# Fix nginx issue with too many nginx variables because of GeoIP (see https://github.com/agentzh/srcache-nginx-module/issues/21)
RUN sed -i 's/mime.types;/mime.types;\n    variables_hash_max_size 1024;/' /usr/local/openresty/nginx/conf/nginx.conf

# Run Nginx in the foreground so supervisor can manage (the 'Docker Way')
RUN sed -i 's/nobody;/nobody;\ndaemon off;/' /usr/local/openresty/nginx/conf/nginx.conf

# Add GeoIP Cron configuration
ADD geoip_cron /var/spool/cron/crontabs/ root

# Add supervisor configuration to manage cron and nginx
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Open HTTP and SSL ports
EXPOSE 80 443

CMD ["/usr/bin/supervisord"]
