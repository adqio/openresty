FROM        ubuntu:12.10
MAINTAINER  scott@switzer.org

# Get latest version of all tools
RUN apt-get -y update
RUN apt-get -y upgrade

# Install GeoIP
RUN apt-get -y install geoip-bin geoip-database libgeoip-dev
RUN cp /etc/GeoIP.conf.default /etc/GeoIP.conf

# Install Openresty
ENV OPENRESTY_VERSION 1.5.8.1
RUN apt-get -y install curl make
RUN apt-get -y install libreadline-dev libncurses5-dev libpcre3-dev libssl-dev perl
RUN curl http://openresty.org/download/ngx_openresty-$OPENRESTY_VERSION.tar.gz > /usr/src/ngx_openresty-$OPENRESTY_VERSION.tar.gz
RUN cd /usr/src && tar xzf ngx_openresty-$OPENRESTY_VERSION.tar.gz
RUN cd /usr/src/ngx_openresty-$OPENRESTY_VERSION;\
    ./configure --with-http_geoip_module --with-http_stub_status_module;\
    make;\
    make install

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

# Open HTTP and SSL ports
EXPOSE 80 443

# Add supervisor to manage cron and nginx
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf
CMD ["/usr/bin/supervisord"]

# Add cronjob for GeoIP
#ADD geoip_cron geoip_cron
#RUN cat geoip_cron > /var/spool/cron/root

