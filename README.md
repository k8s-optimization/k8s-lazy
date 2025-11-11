# Lazy k8s 

This repository contains a batch of Ansible playbooks which useful for setting up an full fledged infrastructure.
For local testing and debugging it contains a Vagrantfile that creates a cluster of Ubuntu VMs consisting of one master node and two worker nodes, perfect for learning distributed systems, container orchestration, or cluster computing.
# TLDR;
```shell
brew install vagrant
brew install --cask virtualbox
make full-deploy
```
# Requirements
- **Vagrant**: 2.4.9
- **VirtualBox**: 7.2+

## Architecture

The cluster consists of 3 Ubuntu 22.04 LTS VMs (**by default uses image for Apple Silicon!!!**):

| VM Name | Hostname | IP Address | Role |
|---------|----------|------------|------|
| master | k8s-master | 192.168.56.10 | Master Node |
| worker1 | k8s-worker1 | 192.168.56.11 | Worker Node |
| worker2 | k8s-worker2 | 192.168.56.12 | Worker Node |

## VM Specifications

Each VM is configured with:
- **OS**: Ubuntu 22.04 LTS (x64)
- **RAM**: 2GB
- **CPU**: 1 core
- **Mode**: Headless (no GUI)
- **Network**: Private network with static IP addresses

## Prerequisites

### Required Software
- [Vagrant](https://www.vagrantup.com/downloads) (latest version)
- [VirtualBox](https://www.virtualbox.org/wiki/Downloads) (7.0+)


### Installation Commands

**macOS (using Homebrew):**
```bash
brew install vagrant
brew install --cask virtualbox
```

**Ubuntu/Debian:**
```bash
# Install Vagrant
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install vagrant

# Install VirtualBox
sudo apt-get install virtualbox
```

**Windows:**
Download and install from official websites:
- [Vagrant Downloads](https://www.vagrantup.com/downloads)
- [VirtualBox Downloads](https://www.virtualbox.org/wiki/Downloads)

## Quick Start

1. **Clone or download this repository**
   ```bash
   git clone <your-repo-url>
   cd <repository-directory>
   ```

2. **Start all VMs**
   ```bash
   vagrant up
   ```

3. **Wait for provisioning to complete** (first run will take several minutes)

4. **Verify all VMs are running**
   ```bash
   vagrant status
   ```

More information in [Vagrant Note](docs/Vagrant.md)
