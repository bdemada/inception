FROM alpine:3.22.3

RUN apk update && apk upgrade --no-cache && \
      apk add --no-cache mariadb mariadb-client
    # Create runtime directories with correct ownership
RUN mkdir -p /var/lib/mysql /run/mysqld \
 && chown -R mysql:mysql /var/lib/mysql /run/mysqld \
    # Minimal my.cnf — disable the test DB and bind only to the container network
 && echo -e '[mysqld]\nskip-name-resolve\nskip-host-cache\nbind-address=0.0.0.0' \
      > /etc/my.cnf.d/docker.cnf

COPY mariadb-setup.sh /usr/local/bin/mariadb-setup.sh
RUN chmod +x /usr/local/bin/mariadb-setup.sh

EXPOSE 3306
VOLUME ["/var/lib/mysql"]

ENTRYPOINT ["/usr/local/bin/mariadb-setup.sh"]
CMD ["mysqld", "--user=mysql"]