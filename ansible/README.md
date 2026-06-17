# Ansible Configuration

This Ansible folder configures the EC2 host that runs Jenkins for the clinic appointment infrastructure. The playbook installs the required CI/CD tools, connects the host to the EKS cluster, installs Jenkins, and configures Jenkins to launch Kubernetes build agents inside EKS.

## Directory Layout

```text
ansible/
├── ansible.cfg
├── playbook.yml
├── group_vars/
│   └── all.yml
├── inventory/
│   └── hosts.yml
└── roles/
    ├── awscli/
    ├── docker/
    ├── handlers/
    ├── helm/
    ├── java/
    ├── jenkins/
    └── kubectl/
```

## Ansible Configuration

`ansible.cfg` sets the default Ansible behavior for this project:

- `inventory = inventory/hosts.yml` makes the project inventory file the default inventory.
- `host_key_checking = False` disables SSH host key prompts, which is useful for newly created cloud hosts.
- `retry_files_enabled = False` prevents `.retry` files from being created after failed runs.
- `roles_path = roles` tells Ansible to load roles from the local `roles/` directory.

## Inventory

`inventory/hosts.yml` defines one managed host named `jenkins`.

The host connection uses:

- `ansible_host: "{{ jenkins_private_ip }}"` to connect to the Jenkins EC2 private IP.
- `ansible_user: ec2-user`, which matches Amazon Linux based EC2 instances.
- `ansible_ssh_private_key_file: ~/.ssh/bastion-key.pem` for SSH authentication.
- `ansible_ssh_common_args` with a `ProxyCommand` so Ansible reaches the private Jenkins host through a bastion host.

The inventory expects `bastion_public_ip` to be available as a variable, usually through an extra variable, exported variable, or another vars file.

Example:

```bash
ansible-playbook playbook.yml -e "bastion_public_ip=<BASTION_PUBLIC_IP>"
```

## Shared Variables

`group_vars/all.yml` defines values shared by all hosts:

- `aws_region`: AWS region used by EKS and AWS CLI commands. Default is `us-east-1`.
- `eks_cluster_name`: loaded from the `EKS_CLUSTER_NAME` environment variable.
- `eks_endpoint`: loaded from the `EKS_ENDPOINT` environment variable and used by Jenkins Kubernetes cloud configuration.
- `jenkins_private_ip`: loaded from the `JENKINS_IP` environment variable and used by the inventory and Jenkins URL.

Before running the playbook, export the required values:

```bash
export EKS_CLUSTER_NAME=<EKS_CLUSTER_NAME>
export EKS_ENDPOINT=<EKS_API_SERVER_ENDPOINT>
export JENKINS_IP=<JENKINS_PRIVATE_IP>
```

## Main Playbook

`playbook.yml` runs against all hosts in the inventory with privilege escalation enabled:

```yaml
- name: Configure clinic appointment infrastructure host
  hosts: all
  become: true
  roles:
    - java
    - docker
    - kubectl
    - helm
    - awscli
    - jenkins
    - handlers
```

The role order matters:

1. `java` installs Java 21, which Jenkins requires.
2. `docker` installs and starts Docker, then adds the `jenkins` user to the Docker group.
3. `kubectl` installs the latest stable kubectl and prepares Jenkins kubeconfig access.
4. `helm` installs Helm 3.
5. `awscli` installs AWS CLI v2.
6. `jenkins` installs Jenkins, plugins, JCasC configuration, and EKS service account resources.
7. `handlers` provides the handler used to reload systemd and restart Jenkins after service configuration changes.

## Roles

### java

Installs Amazon Corretto Java 21 using `dnf`.

### docker

Installs Docker, enables and starts the Docker service, and appends the `jenkins` user to the `docker` group so Jenkins jobs can use Docker commands.

### kubectl

Downloads the latest stable kubectl binary from Kubernetes releases and installs it to `/usr/local/bin/kubectl`.

It also creates `/var/lib/jenkins/.kube`, then runs:

```bash
aws eks update-kubeconfig --name <cluster> --region <region> --kubeconfig /var/lib/jenkins/.kube/config
```

The kubeconfig is owned by the `jenkins` user with `0600` permissions.

Note: this role calls `aws eks update-kubeconfig`, so the target host must have AWS permissions to describe and access the EKS cluster. In the current playbook order, AWS CLI installation runs after this role, so the base image must already have `aws` available or the role order should be adjusted.

### helm

Downloads the official Helm 3 install script to `/tmp/get-helm.sh` and runs it if `/usr/local/bin/helm` does not already exist.

### awscli

Installs `unzip`, downloads AWS CLI v2, extracts it under `/tmp`, and runs the installer. The install task is skipped if `/usr/local/bin/aws` already exists.

### jenkins

Installs and configures Jenkins:

- Adds the Jenkins stable RPM repository.
- Imports the Jenkins GPG key.
- Installs Jenkins with `dnf`.
- Starts and enables the Jenkins service.
- Waits for Jenkins to listen on port `8080`.
- Reads and prints the initial admin password.
- Installs plugins from `roles/jenkins/files/plugins.txt`.
- Creates `/var/lib/jenkins/casc_configs`.
- Renders Jenkins Configuration as Code from `templates/kubernetes-cloud.yaml.j2`.
- Updates the Jenkins systemd service to load JCasC from `/var/lib/jenkins/casc_configs`.
- Creates a `jenkins` namespace in EKS.
- Creates a `jenkins-agent` service account and binds it to the `cluster-admin` ClusterRole.

Installed plugins:

- `configuration-as-code`
- `kubernetes`
- `aws-credentials`
- `aws-secrets-manager-credentials-provider`
- `git`
- `workflow-aggregator`
- `blueocean`
- `docker-workflow`
- `pipeline-stage-view`

### handlers

Provides the `daemon-reload and restart jenkins` handler. The Jenkins role notifies this handler after changing `/usr/lib/systemd/system/jenkins.service`.

## Jenkins Kubernetes Cloud

`roles/jenkins/templates/kubernetes-cloud.yaml.j2` configures Jenkins Configuration as Code with one Kubernetes cloud:

- Cloud name: `eks-cloud`
- Kubernetes API URL: `{{ eks_endpoint }}`
- Namespace: `jenkins`
- Jenkins URL: `http://{{ jenkins_private_ip }}:8080`
- Agent service account: `jenkins-agent`
- Agent image: `jenkins/inbound-agent:latest`
- CPU request/limit: `500m` / `1`
- Memory request/limit: `512Mi` / `1Gi`
- Container cap: `10`

The template leaves `credentialsId` empty, so Jenkins relies on the node IAM role and kubeconfig instead of a Jenkins-stored Kubernetes credential.

## Running The Playbook

From the `ansible/` directory:

```bash
export EKS_CLUSTER_NAME=<EKS_CLUSTER_NAME>
export EKS_ENDPOINT=<EKS_API_SERVER_ENDPOINT>
export JENKINS_IP=<JENKINS_PRIVATE_IP>

ansible-playbook playbook.yml -e "bastion_public_ip=<BASTION_PUBLIC_IP>"
```

The SSH key path is currently hardcoded as `~/.ssh/bastion-key.pem` in the inventory. Update `inventory/hosts.yml` if your key path or bastion user is different.

## Expected Result

After a successful run:

- The Jenkins host has Java, Docker, kubectl, Helm, AWS CLI, and Jenkins installed.
- Jenkins is running on port `8080`.
- Jenkins plugins required for pipelines, Docker, AWS credentials, and Kubernetes agents are installed.
- Jenkins has JCasC configuration for launching agents in the EKS `jenkins` namespace.
- The EKS cluster has a `jenkins` namespace and `jenkins-agent` service account.
