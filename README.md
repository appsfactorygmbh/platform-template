# platform-template
A Platform Template with ArgoCD and Crossplane in a multi-cloud environment

## Architecture (for Multi-cloud)

The architecture for the Platform can be found below:

![Platform Infrastructure Architecture](architecture/platform_infrastructure_architecture.png)

## Tools used/Required

* `kubectl` CLI ([Linux](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/), [Windows](https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/), [MacOS](https://kubernetes.io/docs/tasks/tools/install-kubectl-macos/))
* `argocd` CLI (can be found [here](https://argo-cd.readthedocs.io/en/stable/cli_installation/))
* `kind` CLI (can be found [here](https://kind.sigs.k8s.io/docs/user/quick-start/#installation))

## GitOps

Before we dive into the installation steps and get our hands dirty, we need to understand what is the motivation
behind using ArgoCD? What actually is ArgoCD? What is Crossplane?

ArgoCD is a GitOps tool which manages infrastructure on committing changes to GitHub repository. It is
always connected to GitHub Repository and based on the branch that it is told to make changes to infrastructure,
it will only manage when committing changes to that branch.

But why GitOps? Why not use any other CI/CD tool like Azure DevOps, GitHub Actions or Gitlab CI/CD?
The motivation of GitOps is mostly for any infrastructure changes. Unlike the traditional CI/CD tool,
we rarely make changes to Infrastructure in any environment. Additionally, GitOps have a quicker update
than a traditional CI/CD tool.

Secondly, Crossplane is an IaC tool which utilizes a Kubernetes cluster to store the state instead of a container
(z. B. S3 for AWS, Azure Blob Storage for Azure). It is beneficial for cloud native environment because as a DevOps engineer,
when any changes to infrastructure is made unintentionally, it messes up the entire state unlike Pulumi and Terraform, which
are good tools as well.

Henceforth, Combining Crossplane and ArgoCD, you can make changes to infrastructure by using PRs to review changes and
merging changes to the branch you would want to manage infrastructure as you want.

## Initial Installation

*Note: This installation only covers installation of ArgoCD and Crossplane*

### Scripting

You can run the following script to install cluster with ArgoCD and Crossplane:

```shell
./scripts/initialize_argocd.sh
```

### Step-by-Step

If you would like to follow the traditional approach, you can follow [this page](STEPS_README.md)

### Configuring Provider

In this project, we are following the ArgoCD [App of App](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/) and [sync waves](https://argo-cd.readthedocs.io/en/stable/user-guide/sync-waves/) approach

**Note: Please replace `<cloudprovider>` with the cloud you use. z.B. if you use aws, you would use `provider-aws` in the following steps**

Steps:
1. Create a `provider-<cloudprovider>.yaml` file in `gitops/applications` directory
2. Copy the contents of `argo-config.yaml` file within the `gitops/applications` directory
3. Create a directory under `gitops/manifests` for the cloud provider (z.B. `provider-aws` for aws )
4. Replace the `path` from `gitops/manifests/argo-config` to the newly created path
5. Update the `metadata.name` to `provider-<cloudprovider>`
6. Change `argocd.argoproj.io/sync-wave: "-1"` to `argocd.argoproj.io/sync-wave: "2"`
7. Create a Provider yaml file in the newly created directory (you can find the provider from [here](https://marketplace.upbound.io/providers)) depending on which resource is expected
    ```shell
    apiVersion: pkg.crossplane.io/v1
    kind: Provider
    metadata:
      name: provider-aws
    spec:
      package: xpkg.upbound.io/crossplane-contrib/provider-aws:v0.44.2
    ```
8. Commit and push the changes
9. Check the changes in ArgoCD console (http://argocd.127.0.0.1.nip.io)
10. After the changes are synchronized and applied, create a credentials file in your local directory (reference: [aws credentials](https://docs.crossplane.io/v1.13/getting-started/provider-aws/#generate-an-aws-key-pair-file))
11. You can create the secret using the following command (**please change the name `aws-secret` and `aws-credentials.txt` based on the secret you want and the credentials fle you created**):
    ```shell
    kubectl create secret generic aws-secret \
        -n crossplane-system \
        --from-file=creds=./aws-credentials.txt
    ```
12. Create a `provider-config-<cloudprovider>` file in `gitops/applications` directory
13. Follow the steps 2-5
14. Change `argocd.argoproj.io/sync-wave: "-1"` to `argocd.argoproj.io/sync-wave: "3"`
15. Create the Provider config file in the newly created directory (a sample for AWS is found below, **Please remember to change the `<cloudprovider>`** ):
    ```shell
    apiVersion: aws.crossplane.io/v1beta1
    kind: ProviderConfig
    metadata:
      name: config-<cloudprovider>
    spec:
      credentials:
        source: Secret
        secretRef:
          namespace: crossplane-system
          name: aws-secret
          key: creds
    ```
16. Repeat steps 8-9
17. After it is synchronized, you are ready to create cloud resources.
18. Please follow the steps 1-9 for the cloud resource (remember to change the `argocd.argoproj.io/sync-wave` to 4 or more depending on the order)

Now you can see the changes in your cloud resources and Viola!