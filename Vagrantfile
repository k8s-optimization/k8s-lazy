Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-22.04"

  config.vm.define "master" do |master|
    master.vm.hostname = "k8s-master"
    master.vm.network "forwarded_port", guest: 22, host: 2210, id: "ssh"  # SSH via localhost:2210
    master.vm.network "private_network", ip: "192.168.56.10"
    master.vm.provider "virtualbox" do |vb|
      vb.name = "k8s-master"
      vb.memory = 2048
      vb.cpus = 2
    end
  end

  config.vm.define "worker1" do |worker1|
    worker1.vm.hostname = "k8s-worker1"
    worker1.vm.network "forwarded_port", guest: 22, host: 2211, id: "ssh"  # SSH via localhost:2211
    worker1.vm.network "private_network", ip: "192.168.56.11"
    worker1.vm.provider "virtualbox" do |vb|
      vb.name = "k8s-worker1"
      vb.memory = 2048
      vb.cpus = 1
    end
  end

  config.vm.define "worker2" do |worker2|
    worker2.vm.hostname = "k8s-worker2"
    worker2.vm.network "forwarded_port", guest: 22, host: 2212, id: "ssh"  # SSH via localhost:2212
    worker2.vm.network "private_network", ip: "192.168.56.12"
    worker2.vm.provider "virtualbox" do |vb|
      vb.name = "k8s-worker2"
      vb.memory = 2048
      vb.cpus = 1
    end
  end
end

