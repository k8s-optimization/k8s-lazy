# Configuration Reference

## Inventory File (inventory.ini)

The main configuration file defining cluster nodes and settings.

### Node Definitions

```ini
[masters]
k8s-master ansible_host=10.32.11.52 node_ip=10.32.11.52 ansible_ssh_common_args='...'

[workers]
k8s-worker1 ansible_host=10.32.11.53 node_ip=10.32.11.53 ansible_ssh_common_args='...'
k8s-worker2 ansible_host=10.32.11.54 node_ip=10.32.11.54 ansible_ssh_common_args='...'
```

| Variable | Description |
|----------|-------------|
| `ansible_host` | SSH target IP address |
| `node_ip` | IP used for Kubernetes node registration and API server |
| `ansible_ssh_common_args` | SSH options (disable host key checking for automation) |

### Cluster Variables

```ini
[k8s_cluster:vars]
k8s_version=1.28.2
pod_network_cidr=10.244.0.0/16
service_subnet=10.96.0.0/12
metallb_ip_range="10.32.11.60-10.32.11.75"
web_entrypoint_ip="10.32.11.60"
```

| Variable | Default | Description |
|----------|---------|-------------|
| `k8s_version` | 1.28.2 | Kubernetes version (matches apt package) |
| `pod_network_cidr` | 10.244.0.0/16 | CIDR for pod network (Calico) |
| `service_subnet` | 10.96.0.0/12 | CIDR for Kubernetes services |
| `metallb_ip_range` | 10.32.11.60-10.32.11.75 | IP pool for LoadBalancer services |
| `web_entrypoint_ip` | 10.32.11.60 | Primary ingress IP (Traefik LoadBalancer) |

## Secrets (group_vars/all/secrets.yml)

Encrypted with Ansible Vault. Create `.vault_pass` file with your password.

```yaml
# Example structure (create from secrets.yml.example)
longhorn_password: "your-secure-password"
ansible_user: "vagrant"
home: "home"
```

| Secret | Description |
|--------|-------------|
| `longhorn_password` | Basic auth password for Longhorn UI |
| `ansible_user` | SSH user for Ansible connections |
| `home` | Home directory prefix (usually "home") |

### Managing Secrets

```bash
# Create vault password file
echo "your-vault-password" > .vault_pass
chmod 600 .vault_pass

# Create secrets file
cp secrets.yml.example group_vars/all/secrets.yml
ansible-vault encrypt group_vars/all/secrets.yml --vault-password-file .vault_pass

# Edit secrets
ansible-vault edit group_vars/all/secrets.yml --vault-password-file .vault_pass
```

## Vagrantfile (Local Development)

Defines VMs for local testing with VirtualBox.

### VM Specifications

| VM | Hostname | IP | Memory | CPUs |
|----|----------|-----|--------|------|
| master | k8s-master | 10.32.11.52 | 2048 MB | 2 |
| worker1 | k8s-worker1 | 10.32.11.53 | 2048 MB | 1 |
| worker2 | k8s-worker2 | 10.32.11.54 | 2048 MB | 1 |

### SSH Port Forwarding

| VM | Host Port |
|----|-----------|
| master | localhost:2210 |
| worker1 | localhost:2211 |
| worker2 | localhost:2212 |

### Customizing VMs

```ruby
# Increase memory
vb.memory = 4096

# Add CPUs
vb.cpus = 2

# Change IP (update inventory.ini to match)
master.vm.network "private_network", ip: "192.168.56.10"
```

## Component-Specific Configuration

### Traefik (playbooks/install-ingress.yaml)

```yaml
values:
  deployment:
    replicas: 1
  resources:
    requests:
      cpu: 200m
      memory: 256Mi
    limits:
      cpu: 500m
      memory: 512Mi
  service:
    type: LoadBalancer
    spec:
      loadBalancerIP: "{{ web_entrypoint_ip }}"
```

Key settings:
- Single replica (increase for HA)
- LoadBalancer service type (uses MetalLB)
- Dashboard enabled at `traefik.{IP}.nip.io`

### Calico (playbooks/install-cni.yml)

```yaml
spec:
  calicoNetwork:
    bgp: Disabled
    ipPools:
      - cidr: "{{ pod_network_cidr }}"
        encapsulation: VXLANCrossSubnet
        natOutgoing: Enabled
        nodeSelector: all()
```

Key settings:
- VXLAN encapsulation (works without BGP infrastructure)
- NAT for outgoing pod traffic
- BGP disabled (enable if you have BGP routers)

### MetalLB (playbooks/install-metallb.yaml)

```yaml
spec:
  addresses:
    - "{{ metallb_ip_range }}"
```

L2Advertisement mode - announces IPs via ARP on the local network.

### Longhorn (playbooks/install-longhorn.yaml)

- Default Helm values (modify for custom replica count)
- Basic auth enabled via Traefik middleware
- UI at `longhorn.{IP}.nip.io`

## Web UI Access Points

After deployment, access these URLs (replace IP with your `web_entrypoint_ip`):

| Service | URL | Auth |
|---------|-----|------|
| Traefik Dashboard | http://traefik.10.32.11.60.nip.io | None |
| Kubernetes Dashboard | http://dashboard.10.32.11.60.nip.io | Token |
| Longhorn UI | http://longhorn.10.32.11.60.nip.io | Basic (admin/password) |

### Getting Dashboard Token

```bash
kubectl -n kubernetes-dashboard create token dashboard-admin
```
