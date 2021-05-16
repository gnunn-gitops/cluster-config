Generates a secret that is then encrypted using sealed-secrets to manage the SSO configuration, i.e.

```
kustomize build . | kubeseal --format=yaml --controller-namespace=sealed-secrets
```

Please see my blog article here for more details on how SSO configuration is managed:

https://gexperts.com/wp/rh-sso-keycloak-and-gitops/

Note any file with the suffix `-private` is not stored in git.