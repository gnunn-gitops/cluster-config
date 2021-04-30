# Define each array and then add it to the main one
# Sealed Secrets
sealed_secrets=(sealed-secrets "https://github.com/gnunn-gitops/cluster-config.git" applicationsets components/apps/sealed-secrets-operator/overlays/default "1")
# Lets Encrypt
lets_encrypt=(letsencrypt-certs "https://github.com/gnunn-gitops/cluster-config.git" applicationsets components/apps/letsencrypt-certs/overlays/default "2")
# ISCSI Storage
storage=(config-storage "https://github.com/gnunn-gitops/cluster-config.git" applicationsets components/configs/storage/base "3")
# Authentication
authentication=(config-authentication "https://github.com/gnunn-gitops/cluster-config.git" applicationsets components/configs/oauth/overlays/google-with-matrix "4")
# Groups and Membership
groups=(config-groups-and-membership "https://github.com/gnunn-gitops/cluster-config.git" applicationsets components/configs/groups-and-membership/overlays/default "11")
# Alert Manager
alertmanager=(config-alertmanager "https://github.com/gnunn-gitops/cluster-config.git" applicationsets components/configs/alertmanager/base "11" )
# Console Links
consolelinks=(config-console-links "https://github.com/gnunn-gitops/cluster-config.git" applicationsets components/configs/consolelinks/base "11")
# Helm Repos
helm_repos=(config-helm-repos "https://github.com/gnunn-gitops/cluster-config.git" applicationsets components/configs/helm-repos/base "11")
# Prometheus User Monitoring
prometheus_user_app=(config-prometheus-user-app "https://github.com/gnunn-gitops/cluster-config.git" applicationsets components/configs/prometheus-user-app/base "11")
# Container Security Operator
cso=(config-container-security "https://github.com/redhat-canada-gitops/catalog.git" master container-security-operator/base "21" )
# Cost Management
cost=(config-cost-management "https://github.com/gnunn-gitops/cluster-config.git" applicationsets clusters/home/apps/cost-management-operator/overlays/default "21")
# Namespace Config Operator
ns=(config-namespace-config-operator "https://github.com/gnunn-gitops/cluster-config.git" applicationsets components/apps/namespace-configuration-operator/overlays/default "21")
# RH-SSO Instances
sso=(config-sso "https://github.com/gnunn-gitops/cluster-config.git"  applicationsets clusters/home/apps/sso/overlays/default "21")
# Web Terminal
web_terminal=(config-web-terminal-operator "https://github.com/redhat-canada-gitops/catalog.git" master web-terminal-operator/overlays/aggregate "21")

apps=(
  sealed_secrets[@]
  lets_encrypt[@]
  storage[@]
  authentication[@]
  groups[@]
  alertmanager[@]
  consolelinks[@]
  helm_repos[@]
  prometheus_user_app[@]
  cso[@]
  cost[@]
  ns[@]
  sso[@]
  web_terminal[@]
)

namespace=openshift-gitops
dest_server="https://kubernetes.default.svc"
project=cluster-config

# Loop and print it.  Using offset and length to extract values
count=${#apps[@]}
for ((i=0; i<$count; i++))
do
  name=${!apps[i]:0:1}
  repo=${!apps[i]:1:1}
  revision=${!apps[i]:2:1}
  path=${!apps[i]:3:1}
  wave=${!apps[i]:4:1}
  echo "Generating $name"
  argocd-util app generate-spec ${name} --repo $repo --revision $revision --path $path --dest-namespace $namespace --dest-server $dest_server --project=$project --label "gitops.ownedBy=cluster-config" > temp.yaml
  yq --yaml-output '.metadata |= ({annotations: {"argocd.argoproj.io/compare-options": "IgnoreExtraneous","argocd.argoproj.io/sync-wave":"'${wave}'"}} + .)' < temp.yaml > ${name}-app.yaml
done
rm temp.yaml