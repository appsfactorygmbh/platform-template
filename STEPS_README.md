# GitOps for ArgoCD

## Preparation

1. Install the [ArgoCD CLI for your platform (you may need to update the version number for newer releases)](https://github.com/argoproj/argo-cd/releases/tag/v2.7.7)
1. Add argocd to your `PATH`
1. Install kind by [following these instructions for your platform](https://kind.sigs.k8s.io/docs/user/quick-start#installation)
1. Install kubectl by [following these instructions for your platform](https://kubernetes.io/docs/tasks/tools/#kubectl)
1. Clone this repository

```
git clone https://github.com/af-bgo/platform-demo
cd platform-demo
```

## Create a fresh cluster

```
kind create cluster --config cluster/kind-cluster.yaml
```

## Install ArgoCD

```
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Wait for all deployments to be ready. This is important because otherwise the initial password may not be available yet:

```
kubectl wait --for=condition=Available=True deploy -n argocd --all --timeout=90s
```

## Apply the "App of Apps"

```
kubectl -n argocd apply -f gitops/app-of-apps.yaml
```

The App of Apps will create all other apps which are included in the `applications` folder from within GitHub Repository.

## Get ArgoCD Password

```
argocd admin initial-password -n argocd
```

## Access ArgoCD

It may take a few moments, but Argo will be available at: http://argocd.127.0.0.1.nip.io

You can also port forward to access:

```
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

# App of Apps and Sync Waves Explained

Sync waves allow you to ensure that certain resources are healthy before others are rolled out. In short, it's a way of saying "install A before B".

### Sync Wave -1
Applies custom argocd-cm for Application Health Status

### Sync Wave 0
- NGINX Ingress

### Sync Wave 1
- Crossplane

### Sync Wave 2
- Providers for Cloud native environment (AWS, Azure, GCP, IONOS or others)

### Sync Wave 3
- Provider Configs with secrets for the above mentioned environment

**Note: Please make sure to create a `credential.txt` or `credential.json` file and then run the following command before applying this change:**

Please replace the `credential.txt` with the credential file that you created in your local directory and make sure to add this file to `.gitignore`
```shell
kubectl create secret generic aws-secret -n crossplane-system --from-file=creds=./credentials.txt
```

## Open ArgoCD and Wait
Open ArgoCD by going to `http://localhost:8080`

As a reminder, you can retrieve the password with: `argocd admin initial-password -n argocd`

The app-of-apps will installs things in waves and until that time, expect the applications list to grow as things are rolled out.

Once the `platform-template` application is green, you can proceed (it should take about 15 minutes).

## Argo Ingress
An ingress has been added for argocd during deployment.

When the `platform-template` application is healthy, you can stop the `port-forward` and instead:L

- Navigate to `http://argocd.127.0.0.1.nip.io`
