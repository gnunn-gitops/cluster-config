# GitOps Cluster Configuration

This repo contains the cluster configuration I use for my personal OpenShift clusters. Like my other GitOps repos it leverages ArgoCD heavily. This repo originally followed the folder structure defined in the [Standards](https://github.com/gnunn-gitops/standards) repository but there has been some tweaks that need to be reflected back in that document.

# Structure

Similar to my standards document, the repo consists of four high level folders:

* _bootstrap_  - the minimal yaml needed to bootstrap the cluster-config into argocd. It deploys a known sealed-secret private key along with an "app of app" `cluster-config-manager` that deploys the entirety of the cluster configuration.
* _components_ - a base set of kustomize manifests and yaml for applications, operators, configuration and ArgoCD app/project definitions. Everything is inherited from here
* _clusters_ - Cluster specific configuration, this inherits and kustomizes from the components folder and uses an identical structure.
* _tenants_ - Tenant specific artifacts required by different teams using the cluster. For example, a team will likely need a set of namespaces with quotas, there own gitops-operator installation, etc in order to deploy their work.

While this structure follows the basic principles in my standards document I am in the process of re-factoring the naming as well as attempting to simplify the level of nesting.

![alt text](https://raw.githubusercontent.com/gnunn-gitops/cluster-config/main/docs/img/argocd.png)

Finally note that I deliberately have everything in the same repository for demo purposes. Folks dealing with a lot of clusters and tenants will likely want to split things out into multiple repositories.

# Usage

Cluster specific configuration is stored in the bootstrap/overlays folder. To deploy the cluster configuration, simply do a ```oc apply -k bootstrap/overlays/{clustername}```. Under the hood this kustomize does the following:

* Creates a sealedsecrets project and deploys a known private key into the namespace. This is done so I can re-use an existing key since my clusters are ephemeral and constantly being deployed. Creating new keys would mean re-encrypting all my secrets which is out of scope for demos.
* Creates an ArgoCD AppProject called ```cluster-config```
* Deploys a single application, cluster-config-manager, using the app-of-app pattern to deploy everything else.

# Sequence

This repo uses Argo CD sync waves to configure the configuration in an ordered manner. The following waves are used:

1. Sealed Secrets
2. Lets Encrypt for wildcard routes
3. Storage (iscsi storageclass and PVs)
11. Cluster Configuration (Authentication, AlertManager, etc)
21. Operators (Pipelines, CSO, Compliance, Namespace Operator, etc)
31. Common Apps (Developer Tools)
51. Tenants

# ArgoCD App Generation

In my original version  of this repo I was storing individual ArgoCD applications in the components (then manifests) directory and then patching these as needed to support cluster specific variations. This proved to be a lot of a yaml to maintain so with ApplicationSets being available in the gitops-operator I was excited about simplfying things.

Unfortunately ApplicationSets does not currently support sync waves which I am relying on here to deploy things like sealed-secrets and certificates before everything else. Additionally the templating capability in ApplicationSet is currently not sophisticated enough for my needs. However as mentioned at it's core ApplicationSets is simply a templating pattern and I opted to just replicate this with a helm chart. In each cluster overlay you will see an Argo CD bootstrap folder (`clusters/<cluster-name>/argocd/bootstrap`) which uses kustomize to output the artifacts from a `helm template`.

Each cluster references the `clusters/default/argocd/bootstrap` to load the base configuration common to all of my clusters, each cluster then defines another iteration of the helm chart that includes things specific to this cluster.

Note to use this feature you do need to have Argo CD pass the `--enable-helm` flag to kustomize, you can do this via setting the `kustomizeBuildOptions` in the ArgoCD CR:

```
apiVersion: argoproj.io/v1alpha1
kind: ArgoCD
metadata:
  name: openshift-gitops
  namespace: openshift-gitops
spec:
  kustomizeBuildOptions: "--enable-helm"
  ...
```
