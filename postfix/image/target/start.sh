#!/bin/bash

if [ "${MYHOSTNAME}x" == "x" ]; then
	echo "MYHOSTNAME is missing"
	exit 1
fi

if [ "${INET_PROTOCOLS}x" == "x" ]; then
        echo "INET_PROTOCOLS is missing"
        exit 1
fi

if [ "${MYSQL_PASSWORD}x" == "x" ]; then
	echo "MYSQL_PASSWORD is missing"
	exit 1
fi

/usr/sbin/update-ca-certificates

sed -i "s/^myhostname =.*/myhostname = ${MYHOSTNAME}/" /etc/postfix/main.cf
sed -i "s/^inet_protocols =.*/inet_protocols = ${INET_PROTOCOLS}/" /etc/postfix/main.cf
sed -i "s/smtpd_tls_cert_file =.*/smtpd_tls_cert_file = \/certs\/live\/${MYHOSTNAME}\/fullchain.pem/" /etc/postfix/main.cf
sed -i "s/smtpd_tls_key_file =.*/smtpd_tls_key_file = \/certs\/live\/${MYHOSTNAME}\/privkey.pem/" /etc/postfix/main.cf

sed -i "s/^password =.*/password = ${MYSQL_PASSWORD//\//\\/}/" /etc/postfix/sql/*.cf

for i in access canonical helo_access relay_ccerts relay relocated sasl_passwd sender_canonical transport virtual without_ptr postscreen_access header_checks; do
	postmap /etc/postfix/${i}
done

/usr/bin/newaliases

test -d /var/run/supervisord || mkdir -p /var/run/supervisord

while ! [[ -f /certs/live/${MYHOSTNAME}/fullchain.pem ]] || ! [[ -f /certs/live/${MYHOSTNAME}/privkey.pem ]]; do echo "waiting for SSL certificate data"; sleep 1; done

supervisord -n -c /etc/supervisord.conf

