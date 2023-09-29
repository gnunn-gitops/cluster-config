cp -R ../../../kyverno/overlays/policies policies
kustomize --enable-helm --enable-alpha-plugins build . > ../kyverno-acm-policies.yaml
rm -rf policies
