oc create secret generic --from-file config.yaml=./config-qnap-private.yaml config-bundle-secret --from-file=ssl.cert=fullchain.pem --from-file=ssl.key=key.pem -o yaml --dry-run=client -n quay > config-bundle-secret-qnap.yaml
kubeseal --format yaml --cert ~/.bitnami/publickey.pem < config-bundle-secret-qnap.yaml
