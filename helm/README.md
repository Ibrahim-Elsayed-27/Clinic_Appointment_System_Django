# Helm Charts

This folder contains the Helm charts used to deploy the clinic appointment platform and its monitoring stack to Kubernetes.

## Structure

```text
helm/
├── clinic/
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── values-dev.yaml
│   ├── values-prod.yaml
│   └── templates/
└── monitoring/
    ├── Chart.yaml
    ├── values.yaml
    ├── values-dev.yaml
    ├── values-prod.yaml
    └── templates/
```

## Charts

### clinic

The `clinic` chart deploys the main application stack for the clinic appointment system.

It includes resources for:

- Web and nginx application deployments
- PostgreSQL statefulset and service
- Persistent volume claims and storage classes
- Ingress configuration
- Horizontal Pod Autoscaling
- Prometheus ServiceMonitor integration

Common values are defined in `helm/clinic/values.yaml`, with environment-specific overrides in:

- `helm/clinic/values-dev.yaml`
- `helm/clinic/values-prod.yaml`

### monitoring

The `monitoring` chart deploys the kube-prometheus-stack for Prometheus and Grafana.

It provides:

- Prometheus server
- Grafana dashboard UI
- Alertmanager (disabled by default)
- Node exporter
- kube-state-metrics

Common values are defined in `helm/monitoring/values.yaml`, with environment-specific overrides in:

- `helm/monitoring/values-dev.yaml`
- `helm/monitoring/values-prod.yaml`

## Example Usage

### Deploy the application chart

```bash
helm upgrade --install clinic ./helm/clinic -f ./helm/clinic/values-dev.yaml
```

### Deploy the monitoring chart

```bash
helm upgrade --install monitoring ./helm/monitoring -f ./helm/monitoring/values-dev.yaml
```

### Deploy to production

```bash
helm upgrade --install clinic ./helm/clinic -f ./helm/clinic/values-prod.yaml
helm upgrade --install monitoring ./helm/monitoring -f ./helm/monitoring/values-prod.yaml
```

## Notes

- Review and update secrets such as database passwords and Django secret keys before deploying to production.
- The production values files should be customized for your cluster domain and infrastructure-specific settings.
- The charts assume the target Kubernetes cluster already has the required storage classes and ingress controller available.
