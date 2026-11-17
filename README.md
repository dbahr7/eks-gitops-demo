# eks-gitops-demo

A small yes/no voting app run the way a production service would be: built and pushed by GitHub Actions,
deployed to Amazon EKS, with infrastructure in Terraform.

It is the successor to [k8s-lab](https://github.com/dbahr7/k8s-lab), where the same app was first built
by hand on a local kind cluster and then on EKS.

## Status

Work in progress. Planned pieces:

- [ ] App: Python API (gunicorn, non-root) + nginx web tier
- [ ] Terraform remote state (S3)
- [ ] CI: ECR + GitHub OIDC (no stored AWS keys), images tagged with the git SHA
- [ ] Platform: VPC, EKS, DynamoDB, Pod Identity
- [ ] Ingress via AWS Load Balancer Controller, HTTPS
- [ ] CD, autoscaling (HPA), Container Insights
