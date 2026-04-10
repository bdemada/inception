FROM alpine:3.22.3

RUN apk update && apk upgrade && \
        apk add --no-cache \
        nginx \
        openssl


COPY nginx-setup.sh          /usr/local/bin/nginx-setup.sh
RUN  chmod +x                /usr/local/bin/nginx-setup.sh
RUN ./usr/local/bin/nginx-setup.sh

COPY nginx.conf  /etc/nginx/nginx.conf

EXPOSE 443

ENTRYPOINT ["/usr/local/bin/nginx-setup.sh"]
CMD ["nginx", "-g", "daemon off;"]