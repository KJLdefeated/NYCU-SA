#!/usr/local/bin/bash
DOMAIN="89.cs.nycu"
CA_SERVER="https://ca.nasa.nycu:9000/acme/acme/directory"
export SSL_CERT_FILE=/etc/ssl/certs/rootca.pem
#sudo acme.sh --issue --server https://ca.nasa.nycu:9000/acme/acme/directory -d $DOMAIN --standalone --force
#sudo acme.sh --install-cert -d $DOMAIN \
#    --key-file         \
#    --fullchain-file \
#    --force
acme.sh \
  --server 'https://ca.nasa.nycu:9000/acme/acme/directory' \
  --ca-path '/etc/ssl/certs/rootca.pem' \
  --force \
  --issue -d "$DOMAIN" \
  --standalone \
  --cert-file /usr/local/etc/nginx/certs/cert.pem \
  --key-file /usr/local/etc/nginx/certs/key.pem \
