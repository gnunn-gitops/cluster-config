oc project openshift-gitops
kustomize build clusters/overlays/home/argocd/manager | oc apply -f -
