#!/usr/bin/env bash

echo "Creating Kind cluster..."
kind create cluster --config cluster/kind-cluster.yaml
echo ""

echo "Deploy ArgoCD..."
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
echo ""

echo "Wait for ArgoCD to be ready..."
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=300s
echo ""

echo "Configure ArgoCD..."
kubectl apply -n argocd -f cluster/argocd-no-tls.yaml
echo ""

echo "Restart ArgoCD server..."
kubectl -n argocd rollout restart deploy/argocd-server
kubectl -n argocd rollout status deploy/argocd-server --timeout=300s
echo ""

echo "Wait for the restarted ArgoCD server to be ready..."
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=300s
echo ""

echo "Create ArgoCD App of Apps..."
kubectl -n argocd apply -f gitops/app-of-apps.yaml
echo ""

echo "ArgoCD Admin Password"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo ""
echo ""
echo "🎉 Installation Complete! 🎉"