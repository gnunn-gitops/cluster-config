Installs the Tech Preview LokiStack for cluster logging using local QNAP NAS for object storage.

Example queries:

View raw application logs:
```
export LOKI_ADDR=http://lokistack-openshift-logging.apps.home.ocplab.com/api/logs/v1/application
logcli --bearer-token="$(oc whoami -t)" query '{kubernetes_namespace_name="product-catalog-dev"}'
```

View applicatons logs textually without JSON:
```
export LOKI_ADDR=http://lokistack-openshift-logging.apps.home.ocplab.com/api/logs/v1/application
logcli --bearer-token="$(oc whoami -t)" query '{kubernetes_namespace_name="product-catalog-dev", kubernetes_container_name="server"}' --output=raw | jq '."@timestamp",.kubernetes.pod_name,.level,.message' | paste - - - -
```

View infrastructure logs:
```
export LOKI_ADDR=http://lokistack-openshift-logging.apps.home.ocplab.com/api/logs/v1/infrastructure
logcli --bearer-token="$(oc whoami -t)" query '{kubernetes_namespace_name="openshift-logging"}'
```