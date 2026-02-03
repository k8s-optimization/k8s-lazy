# k8s-lazy

Automated Kubernetes cluster deployment using Ansible. Provisions a production-ready cluster with CNI, ingress controller, load balancer, persistent storage, and RBAC.

## Quick Start

```bash
# Local development (Vagrant + VirtualBox)
make full-deploy

# Existing infrastructure
ansible-playbook -i inventory.ini site.yml --vault-password-file .vault_pass
```

## What Gets Deployed

| Component | Tool | Purpose |
|-----------|------|---------|
| Container Runtime | containerd | Container execution |
| CNI | Calico (Tigera Operator) | Pod networking with VXLAN |
| Ingress | Traefik | HTTP/HTTPS routing |
| Load Balancer | MetalLB | Bare-metal LoadBalancer IPs |
| Storage | Longhorn | Distributed block storage |
| Dashboard | Kubernetes Dashboard | Web UI |

## Requirements

- Ansible 2.15+
- Python kubernetes/openshift libraries
- For local dev: Vagrant 2.4+ and VirtualBox 7.0+

## Usage

```bash
make deploy      # Deploy cluster
make destroy     # Tear down cluster
make status      # Check cluster health
```

## Configuration

Edit `inventory.ini` to configure:
- Node IPs and hostnames
- Kubernetes version
- Network CIDRs
- MetalLB IP range

Secrets are stored in `group_vars/all/secrets.yml` (Ansible Vault encrypted).

## Examples

Example manifests are provided in the `examples/` directory to test your cluster.

| Example | Description |
|---------|-------------|
| [echo-server.yaml](examples/echo-server.yaml) | Echo server with Deployment, Service, and Traefik Ingress |

```bash
make example-deploy   # Deploy echo service
make example-destroy  # Remove echo service
```

Access the echo server at `http://echo.<METALLB_IP>.nip.io` after deployment.

## Documentation

- [Architecture](docs/architecture.md) - Cluster components and network topology
- [Configuration](docs/configuration.md) - All configurable settings
- [Playbooks](docs/playbooks.md) - Detailed playbook descriptions
- [Vagrant](docs/Vagrant.md) - Local VM management
