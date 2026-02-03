# Create Kubernetes User

This playbook creates a Kubernetes user with certificate-based authentication and generates an embedded kubeconfig file.

## Required Parameters

| Parameter | Description |
|-----------|-------------|
| `username` | The name of the user to create |
| `group_name` or `role_name` | At least one must be provided |

## Optional Parameters

| Parameter | Description |
|-----------|-------------|
| `group_name` | Organization name embedded in the certificate |
| `role_name` | Name of the Role/ClusterRole to bind the user to |
| `role_namespace` | Namespace for RoleBinding (required when using Role) |
| `cluster_role` | Set to `true` to bind to a ClusterRole instead of Role |

## Usage Examples

**1. Create user with a namespaced Role:**
```bash
ansible-playbook playbooks/create-user.yml \
  -e username=developer \
  -e role_name=pod-reader \
  -e role_namespace=default
```

**2. Create user with a ClusterRole:**
```bash
ansible-playbook playbooks/create-user.yml \
  -e username=admin-user \
  -e role_name=cluster-admin \
  -e cluster_role=true
```

**3. Create user with group membership only (no role binding):**
```bash
ansible-playbook playbooks/create-user.yml \
  -e username=developer \
  -e group_name=developers
```

## Output

The kubeconfig file will be saved to:
- Remote: `/tmp/kubeconfigs/<username>/<username>.kubeconfig`
- Local: `./kubeconfigs/<username>/<username>.kubeconfig`

## Using the Generated Kubeconfig

```bash
export KUBECONFIG=./kubeconfigs/<username>/<username>.kubeconfig
kubectl get pods
```

Or merge with existing config:
```bash
KUBECONFIG=~/.kube/config:./kubeconfigs/<username>/<username>.kubeconfig kubectl config view --flatten > ~/.kube/config.new
mv ~/.kube/config.new ~/.kube/config
```
