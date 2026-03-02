#!/bin/bash
# Renew Let's Encrypt certificate for library.cwis.org
# This script should be run manually when certificate is near expiration

cd /root/isle-dc-production

# Renew certificate using DNS challenge (manual)
certbot renew --manual --preferred-challenges dns \
  --config-dir certs/letsencrypt \
  --work-dir certs/letsencrypt \
  --logs-dir certs/letsencrypt \
  --cert-name library.cwis.org

# Copy renewed certificates
cp certs/letsencrypt/live/library.cwis.org/fullchain.pem certs/library.cwis.org.crt
cp certs/letsencrypt/live/library.cwis.org/privkey.pem certs/library.cwis.org.key
chmod 600 certs/library.cwis.org.key

# Restart Traefik to pick up new certificates
docker compose restart traefik

echo "Certificate renewed and Traefik restarted"
