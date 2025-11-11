## Vagrant Usage

### Managing VMs

**Start all VMs:**
```bash
vagrant up
```

**Start a specific VM:**
```bash
vagrant up master
vagrant up worker1
vagrant up worker2
```

**SSH into VMs:**
```bash
vagrant ssh master
vagrant ssh worker1
vagrant ssh worker2
```

**Check VM status:**
```bash
vagrant status
```

**Stop all VMs:**
```bash
vagrant halt
```

**Stop a specific VM:**
```bash
vagrant halt master
```

**Restart VMs:**
```bash
vagrant reload
```

**Destroy all VMs:**
```bash
vagrant destroy
```

### Network Access

All VMs are connected via a private network and can communicate with each other:

**From your host machine:**
```bash
# SSH directly (password: vagrant)
ssh vagrant@192.168.56.10  # master
ssh vagrant@192.168.56.11  # worker1
ssh vagrant@192.168.56.12  # worker2

# Ping test
ping 192.168.56.10
```

**From within VMs:**
```bash
# Test connectivity between nodes
ping 192.168.56.11  # from master to worker1
ping 192.168.56.12  # from master to worker2
```

## Customization

### Changing IP Addresses

Edit the `Vagrantfile` and modify the IP addresses:
```ruby
master.vm.network "private_network", ip: "192.168.56.10"   # Change this IP
worker1.vm.network "private_network", ip: "192.168.56.11"  # Change this IP
worker2.vm.network "private_network", ip: "192.168.56.12"  # Change this IP
```

### Adjusting VM Resources

Modify the provider block in `Vagrantfile`:
```ruby
vb.memory = 4096    # Change RAM (in MB)
vb.cpus = 2         # Change CPU cores
```

### Adding Provisioning Scripts

The Vagrantfile includes placeholder sections for:
- **Common provisioning**: Runs on all VMs
- **Master-specific provisioning**: Runs only on master
- **Worker-specific provisioning**: Runs only on workers

Example additions:
```ruby
# Install Docker on all nodes
$common_script = <<-SCRIPT
  apt-get update
  apt-get install -y docker.io
  systemctl enable docker
  systemctl start docker
  usermod -aG docker vagrant
SCRIPT
```

## Use Cases

This cluster setup is ideal for:

- **Kubernetes Learning**: Practice setting up K8s clusters
- **Container Orchestration**: Docker Swarm, K3s, etc.
- **Distributed Systems**: Consul, etcd, distributed databases
- **Load Balancer Testing**: HAProxy, NGINX configurations
- **Microservices Development**: Service mesh testing
- **CI/CD Pipeline Testing**: GitLab Runner, Jenkins agents
- **Database Clustering**: MongoDB replica sets, MySQL clusters

## Troubleshooting

### Common Issues

**VMs won't start on Apple Silicon Macs:**
- VirtualBox doesn't support ARM64 natively
- Use UTM, Parallels, or VMware Fusion instead

**Network connectivity issues:**
- Check if VirtualBox host-only network is configured
- Verify IP addresses don't conflict with existing networks

**Low disk space:**
- VMs use about 4GB each when fully provisioned
- Clean up with `vagrant destroy` when not needed

**Slow performance:**
- Reduce VM count or resources if host machine is limited
- Consider using linked clones (available in Parallels/VMware)

### Useful Commands

**View VM logs:**
```bash
vagrant up --debug
```

**Reload Vagrantfile changes:**
```bash
vagrant reload --provision
```

**Re-run provisioning:**
```bash
vagrant provision
```

**Check Vagrant version:**
```bash
vagrant --version
```
