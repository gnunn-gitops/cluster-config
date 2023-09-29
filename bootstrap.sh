if [ $# -lt 1 ]; then
    echo "No overlay specified, please specify an overlay from bootstrap/overlays"
    exit 1
else
    OVERLAY=$1
    echo "Configuring cluster ${OVERLAY}"
fi

oc project openshift-gitops
kustomize build bootstrap/overlays/${OVERLAY} --enable-helm | oc apply -f -
