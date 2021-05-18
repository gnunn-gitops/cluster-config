This folder is used to bootstrap the cluster config from the CLI as per the project root README.md. Typically this will bootstrap the following artifacts:

- sealed-secrets private key
- cluster-config AppProject for Argo CD
- cluster-config-manager Argo CD Application which acts as an app-of-app, this one is trypically cluster specific since different clusters will need cluster specific customizations or forgo some of the apps.