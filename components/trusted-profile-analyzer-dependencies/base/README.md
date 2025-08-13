Installs namespace, postgresql and some Noobaa support for the RHTPA. This
Application needs to be installed before RHTPA itself.

Unfortunately RHTPA added some Argo CD annotations to run jobs as PreSync hooksso it's
difficult to orchestrate things in a single application now.

For Noobaa (aka MCG), this deploys a Certificate + Route for Noobaa S3 storage since RHTPA uses <bucket-name>.<region>
virtual-host style bucket access instead of path based which is Noobaa's preferred way of working.
