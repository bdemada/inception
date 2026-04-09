FROM alpine:3.22.3

RUN apk update && apk upgrade && \
        apk add --no-cache \
        nginx \
        openssl \
        gettext
    # gettext provides envsubst — used to inject DOMAIN_NAME at runtime
RUN mkdir -p /var/www/html /run/nginx \
 && rm -f /etc/nginx/http.d/default.conf

# Copy as a template — envsubst resolves ${DOMAIN_NAME} at container start
COPY nginx.conf.template /etc/nginx/http.d/wordpress.conf.template
COPY nginx-setup.sh           /usr/local/bin/nginx-setup.sh
RUN  chmod +x                /usr/local/bin/nginx-setup.sh

EXPOSE 443

ENTRYPOINT ["/usr/local/bin/nginx-setup.sh"]
CMD ["nginx", "-g", "daemon off;"]