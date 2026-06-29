# Jenkins Pipelines

This folder contains the Jenkins pipeline definitions used to build and deploy the clinic appointment application.

## Structure

```text
jenkins/
├── dev/
│   ├── Jenkinsfile.ci
│   └── Jenkinsfile.cd
└── prod/
    └── Jenkinsfile.cd
```

## Pipelines

### Dev CI pipeline

File: `jenkins/dev/Jenkinsfile.ci`

This pipeline:

- checks out the repository
- logs into Amazon ECR
- builds and pushes the web image
- builds and pushes the nginx image
- triggers the dev CD pipeline with the new image tag

### Dev CD pipeline

File: `jenkins/dev/Jenkinsfile.cd`

This pipeline:

- reads Kubernetes configuration from `/var/lib/jenkins/.kube/config`
- retrieves Grafana and database secrets from AWS Secrets Manager
- deploys the monitoring stack with Helm
- deploys the clinic application with Helm into the `dev` namespace

### Prod CD pipeline

File: `jenkins/prod/Jenkinsfile.cd`

This pipeline:

- requires an image tag that has already been validated in dev
- prompts for confirmation before deployment
- retrieves production secrets and infrastructure values from AWS
- deploys the monitoring stack and clinic application into the `prod` namespace
- uses the ingress controller DNS information when configuring production host values

## Notes

- The pipelines assume Jenkins has access to AWS CLI, kubectl, Helm, and the required kubeconfig.
- Secrets are pulled from AWS Secrets Manager rather than being stored directly in the Jenkinsfiles.
- The deployment pipelines rely on the Helm charts in `helm/clinic` and `helm/monitoring`.
- Ensure the referenced AWS secrets, EFS filesystem, and database identifiers exist in the target environment before running these jobs.
