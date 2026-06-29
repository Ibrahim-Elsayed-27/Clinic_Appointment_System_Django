# Clinic Appointment Platform

This project is a cloud-native clinic appointment system built to support appointment scheduling, medical record handling, user accounts, analytics, and deployment automation on AWS and Kubernetes.

The platform combines a Django web application with containerized services, infrastructure-as-code, CI/CD pipelines, and observability tooling so it can be deployed and maintained in a modern DevOps workflow.

## What this project includes

The repository contains a full end-to-end example of a production-style application stack:

- A Django-based web application for clinic operations, including account management, appointment workflows, dashboards, analytics, and medical-record functionality
- Dockerized application services for the web app and nginx frontend
- Kubernetes deployment manifests and Helm charts for the application and monitoring stack
- Terraform automation for provisioning AWS resources such as EKS, ECR, EFS, ALB, and supporting infrastructure
- Ansible automation for configuring the Jenkins host and preparing the environment for deployment
- Jenkins pipelines for building images, deploying to development, and promoting to production
- Monitoring and visualization with Prometheus and Grafana for operational insight

## Architecture at a glance

The system is organized around a web application running in containers, backed by AWS infrastructure and deployed to Kubernetes. The repository is split into the main application code, infrastructure automation, deployment automation, and monitoring configuration.

In practice, the workflow looks like this:

1. Developers work on the Django application in `app/`.
2. The application is containerized with Docker and published to Amazon ECR.
3. Jenkins pipelines build and push new images and trigger deployment jobs.
4. Helm charts deploy the application and monitoring stack into Kubernetes.
5. Terraform provisions and manages the AWS infrastructure required by the platform.
6. Prometheus and Grafana provide monitoring and dashboards for the running services.

## Project structure

- `app/` — Django application source, Dockerfiles, and container entrypoints
- `ansible/` — Ansible playbooks and roles for provisioning the Jenkins host
- `helm/` — Helm charts for the application and monitoring stack
- `jenkins/` — Jenkins CI/CD pipeline definitions
- `terraform/aws/` — Terraform modules and configuration for AWS resources

## Documentation

For more detailed information, see the README files in the relevant folders:

- `ansible/README.md` — Ansible setup and Jenkins host automation
- `helm/README.md` — Helm charts for the application and monitoring stack
- `jenkins/README.md` — Jenkins CI/CD pipelines
- `terraform/aws/README.md` — AWS infrastructure overview
- `app/README.md` — application-specific setup and usage

## Screenshots

The following sections are reserved for images that you can add later:

### Application UI

![Application UI](#)

### Prometheus UI

![Prometheus UI](#)

### Grafana Dashboard

![Grafana Dashboard](#)

## Goals

The project aims to provide a practical example of:

- web application development with Django
- building and deploying containerized applications
- Kubernetes-based orchestration and release management
- infrastructure automation with Terraform and Ansible
- CI/CD automation with Jenkins
- observability and monitoring with Prometheus and Grafana
