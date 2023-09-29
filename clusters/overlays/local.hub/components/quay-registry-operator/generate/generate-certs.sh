# Using Route53 with DNS challenge, source AWS creds (not in git repo but just sets access and secret key as env variables)
. aws-creds
mkdir -p qnap-tls
acme.sh --force --issue --dns dns_aws --cert-file "./qnap-tls/cert.pem" --key-file "./qnap-tls/key.pem" --fullchain-file "./qnap-tls/fullchain.pem" --ca-file "./qnap-tls/ca.cer" -d registry.apps.home.ocplab.com

# Convert CA to crt
openssl x509 -inform PEM -in ./qnap-tls/ca.cer -out ./qnap-tls/letsencrypt_ca.crt
