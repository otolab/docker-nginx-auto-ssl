FROM openresty/openresty:alpine-fat

# allowed domains should be lua match pattern
ENV DIFFIE_HELLMAN='' ALLOWED_DOMAINS='.*' AUTO_SSL_VERSION='0.12.0' FORCE_HTTPS='true' SITES='' LETSENCRYPT_URL='https://acme-v01.api.letsencrypt.org/directory'

# Here we install open resty and generate dhparam.pem file.
# You can specify DIFFIE_HELLMAN=true to force regeneration of that file on first run
# also we create fallback ssl keys
RUN apk --no-cache add bash openssl \
    && /usr/local/openresty/luajit/bin/luarocks install lua-resty-auto-ssl $AUTO_SSL_VERSION \
    && openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 \
    -subj '/CN=sni-support-required-for-valid-ssl' \
    -keyout /etc/ssl/resty-auto-ssl-fallback.key \
    -out /etc/ssl/resty-auto-ssl-fallback.crt \
    && openssl dhparam -out /usr/local/openresty/nginx/conf/dhparam.pem 2048 \
    # let's remove default open resty configuration, we'll conditionally add modified version in entrypoint.sh
    && rm /etc/nginx/conf.d/default.conf

RUN cat /usr/local/openresty/luajit/bin/resty-auto-ssl/dehydrated | sed "s/grep Location/grep -i Location/g" | sed "s/grep Replay/grep -i Replay/g" > /usr/local/openresty/luajit/bin/resty-auto-ssl/dehydrated

COPY nginx.conf snippets /usr/local/openresty/nginx/conf/
COPY entrypoint.sh /entrypoint.sh

VOLUME /etc/resty-auto-ssl

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"]
