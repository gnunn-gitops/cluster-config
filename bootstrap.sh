if [ $# -lt 1 ]; then
    OVERLAY=$1
    echo "No overlay specified, please specify an overlay from bootstrap/overlays"
    exit 1
fi

oc project openshift-gitops
kustomize build bootstrap/overlays/home | oc apply -f -
