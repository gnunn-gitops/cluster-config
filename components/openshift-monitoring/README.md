This is used to configure a couple of things with openshift-monitoring:

1. Sets the cluster label so that it can be referenced in templates. This lets us include the cluster name in the received alerts
2. Sets up a service account that external monitoring tools can use to query thanos, the bearer token can be retrieved from the secret.
