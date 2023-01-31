#!/usr/bin/env bash

if [ -n "$DOMAIN" ]; then
    if [ "$CERT" = "none" ]; then
        mkdir -p /etc/haproxy/certs
    elif [ "$CERT" = "self" ]; then
     mkdir -p /etc/letsencrypt/live  && mkdir -p /etc/haproxy/certs && 
    openssl req -x509 -newkey rsa:4096 -sha256 -days 365 -nodes \
  -keyout /etc/letsencrypt/live/cert.key -out /etc/letsencrypt/live/cert.crt -extensions ext  -config \
  <(echo "[req]";
    echo distinguished_name=req;
    echo "[ext]";
    echo "keyUsage=critical,digitalSignature,keyEncipherment";
    echo "extendedKeyUsage=serverAuth";
    echo "basicConstraints=critical,CA:FALSE";
    echo "subjectAltName=DNS:$DOMAIN";
    ) -subj "/CN=$DOMAIN" && cat /etc/letsencrypt/live/cert.key \
              /etc/letsencrypt/live/cert.crt \
              | tee /etc/haproxy/certs/haproxy-"$DOMAIN".pem >/dev/null

        echo "Self-signed certificate generated and stored in /etc/haproxy/certs/"
        echo "Generated below is the TLSA DNS record - Use With Handshake Domains or DNSSEC | Record Name: _443._tcp.$DOMAIN"
        TLSA=$(openssl x509 -in /etc/letsencrypt/live/cert.crt -outform DER | openssl sha256 | sed 's/(stdin)=//' | awk '{print "3 0 1",$1}')
        echo $TLSA > /etc/letsencrypt/"$DOMAIN"_TLSA.txt
        echo $TLSA
    elif [ "$STAGING" = true ]; then
        if [ -n "$ACME" ]; then
            certbot certonly --no-self-upgrade -n --text --standalone \
            --preferred-challenges http-01 \
            --staging \
            -d "$DOMAIN" --server "$ACME" --keep --expand --agree-tos --email "$EMAIL" &&  mkdir -p /etc/haproxy/certs && cat /etc/letsencrypt/live/"$DOMAIN"/privkey.pem \
              /etc/letsencrypt/live/"$DOMAIN"/fullchain.pem \
              | tee /etc/haproxy/certs/haproxy-"$DOMAIN".pem >/dev/null
        else
            certbot certonly --no-self-upgrade -n --text --standalone \
            --preferred-challenges http-01 \
            --staging \
            -d "$DOMAIN" --keep --expand --agree-tos --email "$EMAIL" &&  mkdir -p /etc/haproxy/certs && cat /etc/letsencrypt/live/"$DOMAIN"/privkey.pem \
              /etc/letsencrypt/live/"$DOMAIN"/fullchain.pem \
              | tee /etc/haproxy/certs/haproxy-"$DOMAIN".pem >/dev/null
        fi
    else
        if [ -n "$ACME" ]; then
            certbot certonly --no-self-upgrade -n --text --standalone \
            --preferred-challenges http-01 \
            -d "$DOMAIN" --server "$ACME" --keep --expand --agree-tos --email "$EMAIL" &&  mkdir -p /etc/haproxy/certs && cat /etc/letsencrypt/live/"$DOMAIN"/privkey.pem \
              /etc/letsencrypt/live/"$DOMAIN"/fullchain.pem \
              | tee /etc/haproxy/certs/haproxy-"$DOMAIN".pem >/dev/null && echo "Generated below is the TLSA DNS record - Use With Handshake Domains or DNSSEC | Record Name: _443._tcp.$DOMAIN"
            
            TLSA=$(openssl x509 -in /etc/letsencrypt/live/"$DOMAIN"/fullchain.pem -outform DER | openssl sha256 | sed 's/(stdin)=//' | awk '{print "3 0 1",$1}')
           echo $TLSA > /etc/letsencrypt/"$DOMAIN"_TLSA.txt
           echo $TLSA 
        else
            certbot certonly --no-self-upgrade -n --text --standalone \
            --preferred-challenges http-01 \
            -d "$DOMAIN" --keep --expand --agree-tos --email "$EMAIL" &&  mkdir -p /etc/haproxy/certs && cat /etc/letsencrypt/live/"$DOMAIN"/privkey.pem \
              /etc/letsencrypt/live/"$DOMAIN"/fullchain.pem \
              | tee /etc/haproxy/certs/haproxy-"$DOMAIN".pem >/dev/null
        fi
    fi

    if [ "$CERT" != "none" ]; then
        mkdir -p /etc/haproxy/certs
    else
        for site in `ls -1 /etc/letsencrypt/live | grep -v ^README$`; do
            cat /etc/letsencrypt/live/$site/privkey.pem \
              /etc/letsencrypt/live/$site/fullchain.pem \
              | tee /etc/haproxy/certs/haproxy-"$site".pem >/dev/null
        done
    fi
fi

exit 0
