.PHONY: help vms-up vms-down vms-status k8s-deploy k8s-destroy k8s-status ssh-master clean example-deploy example-destroy

help: 
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

vms-up: 
	vagrant up

vms-down:
	vagrant halt
	vagrant destroy -f

vms-status: 
	vagrant status

k8s-deploy: 
	@echo "Deploying Kubernetes cluster..."
	ansible-playbook -i inventory.ini site.yml --vault-password-file .vault_pass

k8s-destroy:
	@echo "Destroying Kubernetes cluster..."
	ansible masters -i inventory.ini -b -m shell -a "kubeadm reset -f" --vault-password-file .vault_pass
	ansible workers -i inventory.ini -b -m shell -a "kubeadm reset -f" --vault-password-file .vault_pass
	ansible k8s_cluster -i inventory.ini -b -m shell -a "rm -rf /etc/kubernetes /var/lib/etcd /var/lib/kubelet /var/lib/dockershim /var/run/kubernetes ~/.kube /etc/cni/net.d" --vault-password-file .vault_pass
	ansible k8s_cluster -i inventory.ini -b -m shell -a "iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X" --vault-password-file .vault_pass
	rm -f playbooks/kubeadm_join_cmd.sh

k8s-status: 
	@echo "Checking cluster status..."
	ansible masters -i inventory.ini -m shell -a "kubectl get nodes -o wide" -u vagrant --vault-password-file .vault_pass
	@echo ""
	ansible masters -i inventory.ini -m shell -a "kubectl get pods -A -o wide" -u vagrant --vault-password-file .vault_pass

ssh-master: 
	vagrant ssh master

ssh-worker1: 
	vagrant ssh worker1

ssh-worker2:
	vagrant ssh worker2

example-deploy: 
	@echo "Deploying example echo service..."
	kubectl apply -f examples/echo-server.yaml

example-destroy:
	@echo "Removing example echo service..."
	kubectl delete -f examples/echo-server.yaml

full-deploy: vms-up k8s-deploy 

full-cleanup: k8s-destroy vms-down

full-reload: full-cleanup full-deploy

clean:
	rm -f kubeadm_join_cmd.sh
	rm -fr .vagrant
	vagrant destroy -f

up: vms-up
down: vms-down
deploy: k8s-deploy
destroy: k8s-destroy
status: k8s-status
