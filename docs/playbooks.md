# Playbooks Reference

Playbooks are executed in order via `site.yml`. Each playbook is idempotent and can be run independently.

## Execution Order

```
site.yml
├── prepare-nodes.yml      # System prerequisites
├── install-containerd.yml # Container runtime
├── install-k8s.yml        # kubeadm, kubelet, kubectl
├── init-master.yml        # Initialize control plane
├── join-workers.yml       # Join worker nodes
├── install-helm.yml       # Helm package manager
├── install-cni.yml        # Calico networking
├── install-ingress.yaml   # Traefik ingress
├── install-metallb.yaml   # Load balancer
├── install-longhorn.yaml  # Persistent storage
├── install-dashboard.yml  # Kubernetes Dashboard
├── create-roles.yml       # RBAC roles
└── create-groups.yml      # RBAC group bindings
```

## Playbook Details

### prepare-nodes.yml

**Hosts:** k8s_cluster (all nodes)

Prepares nodes for Kubernetes installation:
- Updates system packages
- Installs dependencies (apt-transport-https, curl, etc.)
- Installs `nfs-common` (required for Longhorn)
- Disables swap (Kubernetes requirement)
- Loads kernel modules: `overlay`, `br_netfilter`
- Configures sysctl for networking:
  - `net.bridge.bridge-nf-call-iptables=1`
  - `net.bridge.bridge-nf-call-ip6tables=1`
  - `net.ipv4.ip_forward=1`
- Adds `/etc/hosts` entries for all cluster nodes
- Installs Python `kubernetes` and `openshift` libraries

### install-containerd.yml

**Hosts:** k8s_cluster (all nodes)

Installs containerd container runtime:
- Adds Docker GPG key and repository
- Installs `containerd.io` package
- Generates default configuration
- Configures systemd cgroup driver
- Enables and starts containerd service

### install-k8s.yml

**Hosts:** k8s_cluster (all nodes)

Installs Kubernetes components:
- Adds Kubernetes apt repository (v1.28)
- Installs packages:
  - `kubelet={{ k8s_version }}-1.1`
  - `kubeadm={{ k8s_version }}-1.1`
  - `kubectl={{ k8s_version }}-1.1`
- Holds packages to prevent auto-upgrade
- Configures kubelet with systemd cgroup driver
- Enables kubelet service

### init-master.yml

**Hosts:** masters

Initializes the Kubernetes control plane:
- Checks if already initialized (idempotent)
- Runs `kubeadm init` with:
  - `--apiserver-advertise-address={{ node_ip }}`
  - `--pod-network-cidr={{ pod_network_cidr }}`
  - `--service-cidr={{ service_subnet }}`
- Creates `.kube/config` for ansible user and root
- Generates join command for workers
- Saves join command to `kubeadm_join_cmd.sh`
- Creates namespaces: `dev`, `cicd`, `prod`

### join-workers.yml

**Hosts:** workers

Joins worker nodes to the cluster:
- Checks if already joined (idempotent)
- Copies join script from master
- Executes join command
- Waits for node to be Ready

### install-helm.yml

**Hosts:** masters

Installs Helm package manager:
- Downloads Helm install script
- Installs latest Helm version
- Verifies installation

### install-cni.yml

**Hosts:** masters

Deploys Calico CNI via Tigera Operator:
- Installs tigera-operator Helm chart
- Creates Calico Installation CR:
  - VXLAN encapsulation (cross-subnet)
  - BGP disabled
  - NAT for outgoing traffic
  - Pod CIDR from `pod_network_cidr`

### install-ingress.yaml

**Hosts:** masters

Deploys Traefik ingress controller:
- Installs Traefik Helm chart to `traefik-system`
- Configures:
  - LoadBalancer service with `web_entrypoint_ip`
  - HTTP (80) and HTTPS (443) ports
  - Dashboard at `traefik.{IP}.nip.io`
  - Kubernetes CRD and Ingress providers
  - Resource limits (200m-500m CPU, 256Mi-512Mi memory)
- Waits for Traefik pods to be Running
- Displays dashboard URL

### install-metallb.yaml

**Hosts:** masters

Deploys MetalLB load balancer:
- Installs MetalLB Helm chart to `metallb-system`
- Waits for controller to be ready
- Creates IPAddressPool from `metallb_ip_range`
- Creates L2Advertisement for the pool

### install-longhorn.yaml

**Hosts:** masters

Deploys Longhorn distributed storage:
- Validates `longhorn_password` is defined
- Installs Longhorn Helm chart to `longhorn-system`
- Creates basic auth secret for Traefik
- Creates BasicAuth middleware
- Creates IngressRoute at `longhorn.{IP}.nip.io`

### install-dashboard.yml

**Hosts:** masters

Deploys Kubernetes Dashboard:
- Downloads and applies Dashboard v2.7.0 manifest
- Waits for dashboard pods to be Running
- Creates IP allowlist middleware (10.0.0.0/8, 192.168.0.0/16)
- Creates ServersTransport for HTTPS backend
- Creates IngressRoute at `dashboard.{IP}.nip.io`
- Creates `dashboard-admin` ServiceAccount
- Binds to `cluster-admin` ClusterRole
- Generates and displays access token

### create-roles.yml

**Hosts:** masters

Creates RBAC roles:
- `longhorn-admin` (ClusterRole) - Full Longhorn access
- `developer` (Role in dev) - Pod/deployment management, read-only secrets
- `cicd-operator` (Role in cicd) - Full deployment access including secrets
- `prod-operator` (Role in prod) - Read-only + pod exec
- `prod-admin` (Role in prod) - Full access

### create-groups.yml

**Hosts:** masters

Creates RBAC group bindings:
- `developers` group → `developer` role
- `cicd` group → `cicd-operator` role
- `prod-operators` group → `prod-operator` role
- `prod-admins` group → `prod-admin` role
- `longhorn-admins` group → `longhorn-admin` ClusterRole

### create-user.yml (Manual)

**Not in site.yml** - Run separately to create users.

Creates X.509 certificate-based users:
- Generates private key and CSR
- Creates Kubernetes CertificateSigningRequest
- Approves CSR and retrieves certificate
- Generates kubeconfig for user

## Running Individual Playbooks

```bash
# Run specific playbook
ansible-playbook -i inventory.ini playbooks/install-cni.yml --vault-password-file .vault_pass

# Run with tags (if defined)
ansible-playbook -i inventory.ini playbooks/install-dashboard.yml --tags frontend --vault-password-file .vault_pass

# Dry run (check mode)
ansible-playbook -i inventory.ini playbooks/prepare-nodes.yml --check --vault-password-file .vault_pass
```

## Makefile Targets

| Target | Description |
|--------|-------------|
| `make deploy` | Run full site.yml |
| `make destroy` | Reset kubeadm on all nodes, clean up |
| `make status` | Show nodes and pods |
| `make full-deploy` | Vagrant up + deploy |
| `make full-cleanup` | Destroy cluster + VMs |
| `make full-reload` | Full cleanup + full deploy |
