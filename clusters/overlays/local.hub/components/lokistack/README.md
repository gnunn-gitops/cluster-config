

### Introduction

Installs the Tech Preview LokiStack for cluster logging using local QNAP NAS for object storage.

Installation is based on docs here:

https://github.com/grafana/loki/blob/main/operator/docs/forwarding_logs_to_gateway.md#openshift-logging

# Accessing logs

You can access the logs using the logcli tool from grafana:

https://github.com/grafana/loki/releases/tag/v2.5.0

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

### Storage Secret

You will need a storage secret for your S3 bucket for Loki to use, format of secret is as follows:

```
apiVersion: v1
data:
  access_key_id: XXXXXX
  access_key_secret: XXXXXX
  bucketnames: XXXXXX
  endpoint: XXXXXXXXXXXX
kind: Secret
metadata:
  name: loki-storage
  namespace: openshift-logging
```

The sealed secret here is referencing Minio running on my QNAP NAS so non AWS S3 buckets do work fine.
