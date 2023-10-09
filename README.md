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

## App-Of-App Helm Chart and Layers

This repository is based on kustomize, and as a result the _bootstrap_ folder consists of a _base_ and _overlays_. The _base_ is the configuration that is required on all clusters whereas the _overlays_ consist of groupings of
clusters as well as specific clusters.

A helm chart managed by kustomize is used to generate the list of Argo CD Applications using the [App of App](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/#app-of-apps-pattern) pattern as well as a cluster-config AppProject. I had originally used kustomize to manage the Argo CD Applications directly but this generated a lot of yaml and made overriding applications for specific clusters much more verbose then necessary. This is an example of where templating is a more optimum solution then patching.

In the bootstrap _base_ and cluster _overlays_ (`bootstrap/overlays/<cluster-name>`) there is a `kustomization.yaml` file along with a `values.yaml` file where we use kustomize to output the artifacts from a `helm template`.

This helm chart is run independently at each layer and is aggregated by higher levels. So for example my `local.home` cluster, which is one of my bare-metal servers in my homelab, has an application tree that aggregates as follows:

`base` > `local` > `local.home`

At each layer the helm chart is run for that layer and generates the Application manifests for that layer. With each layer, kustomize can be used to override a lower level Application and point it to a cluster specific version by using kustomize to change it's path and/or repo via a patch.

The `clusters/overlays/<cluster-name>/components` consists of components that are specific to this cluster or is cluster-specific overriden version of manifests from the _components_ folder. So at the bootstrap level, if the _base_ has an application pointing to manfiests in _components_, this can be overriden in the cluster specific bootstrap by patching it to point to the version in `clusters/overlays/<cluster-name>/components`.

I've opted to use a dot notation to separate groups, i.e `local`, from specific clusters, `local.home` however in the future it may be worth considering seperating this into distinct `groups` and `clusters` folders.

## Why not ApplicationSet instead of App-of-App Helm Chart?

Some folks may be wondering I don't use an ApplicationSet instead of this App-of-App Helm chart? The primary reason is that the Helm chart allows for easily post-processing the generated Applications to enable cluster overrides. While having an ApplicationSet with a list generator delivered by kustomize could enable this, the list generator is simply an array which is error-prone to patch correctly with JSON semantics (i.e. you can only reference items by ordinal rather then name so changing order causes issues with downstream patching).

Other generator types don't allow any post-processing meaning overriding for specific clusters needs to be packaged into the ApplicationSet which I felt was cumbersome.

Having said, the new feature supporting creating custom generator plugins may make it more amenable for this use case but I have not explored this as of yet.

# Usage

As detailed in the layers section, cluster specific configuration is stored in the bootstrap/overlays folder. To deploy a specific cluster configuration, simply create an application in Argo CD that points to the appropriate cluster folder, i.e. `bootstrap/overlays/{clustername}`.

Note that in order for kustomize to be able to generate manifests from a helm chart you do need to have Argo CD pass the `--enable-helm` flag to kustomize. You can do this via setting the `kustomizeBuildOptions` in the ArgoCD CR:

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


How this bootstrap application gets generated and managed can happen in a variety of different ways:

* Red Hat Advanced Cluster Manager can use a policy to deploy OpenShift GitOps plus a cluster specific bootstrap application across a fleet of clusters. This is my preferred approach and the [acm-bootstrap-hub](https://github.com/gnunn-gitops/acm-hub-bootstrap) is the repo where I have this policy along with other things I use to bootstrap the ACM Hub cluster.
* Ansible. If you use Ansible for cluster provisioning you can have it deploy the OpenShift GitOps operator plus the bootstrap application
* Other. If you use other automation tools to provision clusters they could do the same as Ansible.

# Secret Management

I am currently using the External Secrets Operator to manage secrets, I am using ACM to automatically bootstrap the token secret needed by ESO to interact with my secrets provider [Doppler](doppler.com) from the Hub cluster.

I have used Sealed Secrets in the past but as I have expanded my homelab into multiple clusters, plus the occasional ephemeral cloud cluster, I found external secrets easier to manage.

# Managing Promotion

A common requirement is for a cluster configuration to be promoted across one or more clusters, i.e a change starts in the lab cluster, gets promoted to non-production and then finally production.

I have only experimented with this a bit however it looks like commit pinning works well in this scenario, i.e. the lab cluster is pinned to HEAD and then other clusters are pinned to specific commits. When you want to promote you simply move the pin forward to the desired commit.

In cases where a configuration spans multiple repositories you may need to have different commit pins based on the repo. This could be accomplished by labelling the Application objects with the repo and then using a kustomize patch targetted by label. Some improvements to the helm chart would be needed so that labels can be merged between default and specific applications to make this easier to manage.

# Sequence

This repo uses Argo CD sync waves to configure the configuration in an ordered manner. The following waves are used:

1. External Secrets Operator
2. Storage (if needed)
3. cert-manager
11. Cluster Configuration (Authentication, AlertManager, etc)
21. Operators (Pipelines, CSO, Compliance, Namespace Operator, etc)
31. Common Apps (Developer Tools)
41. OpenShift Console plugins
51. Tenants
