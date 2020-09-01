# GitOps Cluster Configuration

This repo contains the cluster configuration I use for my personal OpenShift clusters. Like my other GitOps repos it leverages ArgoCD heavily. This repo follows the folder structure defined in the [Standards](https://github.com/gnunn-gitops/standards) repository.

# Structure

As per the standards document, the repo consists of three high level folders:

* _manifests_ - a base set of kustomize manifests and yaml for applications, operators, configuration and ArgoCD app/project definitions. Everything is inherited from here
* _environments_ - environment specific aggregation here. Unlike app environments (prod/test/qa), this is meant as environments that will share the same configuration (product vs non-production, aws versus azure, etc). It aggregates the argocd applications you wish deployed with the next level in the heirarchy clusters, using an app of app pattern.
* _clusters_ - Cluster specific configuration, it does not directly aggregate the environments but instead employs an app-of-app pattern to define one or more applications that point to the environment set of applications. It also includes anything that needs to be directly bootstrapped, i.e. a specific sealed-secrets key as an example,

![alt text](https://raw.githubusercontent.com/gnunn-gitops/cluster-config/master/docs/img/argocd.png)

# Usage

Cluster specific configuration is stored in the clusters/overlays folder. To deploy the cluster configuration, simply do a ```oc apply -k clusters/overlays/{clustername}```. Under the hood this kustomize does the following:

* Creates a sealedsecrets project and deploys a known private key into the namespace. This is done so I can re-use an existing key since my clusters are ephemeral and constantly being deployed. Creating new keys would mean re-encrypting all my secrets which is out of scope for demos.
* Creates an ArgoCD AppProject called ```cluster-config```
* Deploys a single application, cluster-config-manager, using the app-of-app pattern.

The application cluster-config-manager simply points to the ```environments/overlays/default``` at this point in time. Additional environments could be created as needed to customize what is deployed. For example, I could a new environment that inherits from ```environments/overlays/default``` and adds the OpenShift Virtualization operator.

Note that the applications in ```environments/overlays/default``` leverage the ArgoCD sync wave feature to ensure that sealed-secrets gets deployed first since many other configurations depend on it.