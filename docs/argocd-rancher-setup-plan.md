# ArgoCD + Rancher Setup Plan

Target architecture for running many apps across many clusters: a hub-and-spoke model.

- **Hub cluster** — a small dedicated cluster running only the control planes: **Rancher** (multi-cluster management/RBAC) and **ArgoCD** (GitOps delivery). One ArgoCD instance serves the whole fleet, not one per workload cluster.
- **Downstream/workload clusters** — where apps actually run. Rancher imports/provisions them; ArgoCD is registered against each and deploys to them.

This scales cleanly: adding a cluster later is "import into Rancher + `argocd cluster add`," and adding an app later is a new ArgoCD Application/ApplicationSet entry, not new infrastructure.

## Install order

1. **Hub cluster** — stand up a small cluster (k3s or RKE2 is typical) dedicated to control planes, separate from where apps run.
2. **cert-manager** — required by Rancher's Helm chart for TLS.
3. **Rancher** (Helm chart) on the hub cluster — gives you the multi-cluster management UI/API.
4. **Import or provision downstream clusters in Rancher** — each existing cluster gets imported; new ones can be provisioned directly through Rancher (RKE2/EKS/etc.).
5. **ArgoCD** (Helm chart) on the hub cluster — single instance for the whole fleet.
6. **Register each downstream cluster with ArgoCD** (`argocd cluster add <context>`), using the kubeconfig contexts Rancher gives you for each cluster.
7. **GitOps repo layout** — app-of-apps or, better at this scale, **ApplicationSets with a cluster generator**, so new clusters/apps are config changes, not manual wiring.
8. **First app** — wire this repo (`c-hashtag`) as the first ArgoCD Application to validate the whole pipeline end-to-end (image already builds/publishes to Docker Hub via `.github/workflows/release.yml`, so this is just the deploy half).
9. **Per-cluster add-ons** — ingress-nginx + cert-manager + external-dns on each downstream cluster (can themselves be ArgoCD-managed apps).
10. **Secrets** — External Secrets Operator or Sealed Secrets, since plain Git manifests can't hold real app secrets.
11. **SSO/RBAC** — shared OIDC provider for Rancher and ArgoCD so access control is consistent across the fleet, not per-tool.

## Open questions before proceeding

- Do any clusters or a Rancher instance already exist, or is this greenfield?
- Where should Kubernetes manifests for this app live: a `k8s/` directory in this repo, or a separate GitOps repo?
- How many environments (dev/staging/prod) and what ingress domain(s)?
