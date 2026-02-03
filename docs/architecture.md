# Cluster Architecture

## Node Topology

The cluster uses a single master, multi-worker architecture:

```
┌─────────────────────────────────────────────────────────────┐
│                     Control Plane                            │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  k8s-master                                          │    │
│  │  - API Server, Controller Manager, Scheduler         │    │
│  │  - etcd (single node)                                │    │
│  │  - Helm, kubectl                                     │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
                              │
         ┌────────────────────┼────────────────────┐
         │                    │                    │
         ▼                    ▼                    ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│  k8s-worker1    │  │  k8s-worker2    │  │  k8s-worker3+   │
│  - kubelet      │  │  - kubelet      │  │  - kubelet      │
│  - containerd   │  │  - containerd   │  │  - containerd   │
│  - Calico       │  │  - Calico       │  │  - Calico       │
│  - Longhorn     │  │  - Longhorn     │  │  - Longhorn     │
└─────────────────┘  └─────────────────┘  └─────────────────┘
```

## Network Architecture

### IP Addressing (Default Configuration)

| Network | CIDR | Purpose |
|---------|------|---------|
| Node Network | 10.32.11.0/24 | Physical/VM node IPs |
| Pod Network | 10.244.0.0/16 | Calico pod overlay |
| Service Network | 10.96.0.0/12 | ClusterIP services |
| LoadBalancer Pool | 10.32.11.60-75 | MetalLB external IPs |

### Traffic Flow

```
External Traffic
       │
       ▼
┌──────────────────┐
│  MetalLB L2      │  Announces LoadBalancer IPs via ARP
│  10.32.11.60-75  │
└──────────────────┘
       │
       ▼
┌──────────────────┐
│  Traefik Ingress │  Routes HTTP/HTTPS by Host header
│  10.32.11.60     │  - traefik.{IP}.nip.io (dashboard)
└──────────────────┘  - dashboard.{IP}.nip.io (k8s dashboard)
       │              - longhorn.{IP}.nip.io (storage UI)
       ▼
┌──────────────────┐
│  Kubernetes      │  ClusterIP services
│  Services        │
└──────────────────┘
       │
       ▼
┌──────────────────┐
│  Pods            │  Application containers
│  (Calico VXLAN)  │
└──────────────────┘
```

## Component Details

### Container Runtime: containerd

- Installed from official Docker repository
- Configured with systemd cgroup driver
- Default runtime for Kubernetes 1.28+

### CNI: Calico (Tigera Operator)

- Deployed via Helm chart
- Uses VXLAN encapsulation (cross-subnet)
- BGP disabled (suitable for L2 networks)
- Pod CIDR: configurable via `pod_network_cidr`

### Ingress Controller: Traefik

- Deployed via Helm to `traefik-system` namespace
- Exposes ports 80 (HTTP) and 443 (HTTPS)
- Kubernetes CRD provider enabled (IngressRoute)
- Standard Ingress provider enabled
- Cross-namespace routing allowed

**Resource Limits:**
- CPU: 200m request, 500m limit
- Memory: 256Mi request, 512Mi limit

### Load Balancer: MetalLB

- Layer 2 mode (ARP-based)
- IP pool defined in `inventory.ini`
- Provides external IPs for LoadBalancer services

### Storage: Longhorn

- Distributed block storage
- Replicated across worker nodes
- Web UI protected with basic auth
- Default StorageClass for PVCs

### Dashboard: Kubernetes Dashboard

- Standard v2.7.0 deployment
- Accessed via Traefik IngressRoute
- Admin ServiceAccount with cluster-admin role

## Namespaces

| Namespace | Purpose |
|-----------|---------|
| `kube-system` | Core Kubernetes components |
| `tigera-operator` | Calico operator |
| `calico-system` | Calico components (created by operator) |
| `traefik-system` | Traefik ingress controller |
| `metallb-system` | MetalLB load balancer |
| `longhorn-system` | Longhorn storage |
| `kubernetes-dashboard` | Dashboard UI |
| `dev` | Development workloads |
| `cicd` | CI/CD pipelines |
| `prod` | Production workloads |

## RBAC Structure

### Roles

| Role | Namespace | Permissions |
|------|-----------|-------------|
| `developer` | dev | Full access to pods, deployments, services; read-only secrets |
| `cicd-operator` | cicd | Full access to deployments, pods, jobs, secrets |
| `prod-operator` | prod | Read-only + pod exec |
| `prod-admin` | prod | Full access |
| `longhorn-admin` | cluster-wide | Full Longhorn CRD access |

### Groups

Groups map to roles via RoleBindings:
- `developers` → `developer` role in `dev`
- `cicd` → `cicd-operator` role in `cicd`
- `prod-operators` → `prod-operator` role in `prod`
- `prod-admins` → `prod-admin` role in `prod`
- `longhorn-admins` → `longhorn-admin` ClusterRole
