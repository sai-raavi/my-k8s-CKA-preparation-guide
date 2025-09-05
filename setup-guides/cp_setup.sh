#!/bin/bash
# Exit immediately if any command fails.
set -e

ip_addr=$(hostname -i)

new_host_entries="${ip_addr} $(hostname)
${ip_addr} cp"
# pub_ip_addr=$(curl ifconfig.me)
# new_host_entries="${pub_ip_addr} $(hostname)"

echo "Adding the following entries to /etc/hosts:"
echo "$new_host_entries" | cat - /etc/hosts | sudo tee /etc/hosts > /dev/null
echo "Successfully updated /etc/hosts."
echo "Current /etc/hosts content (first few lines):"
head -n 5 /etc/hosts

cat << EOF | tee kubeadm-config.yaml
apiVersion: kubeadm.k8s.io/v1beta4
kind: ClusterConfiguration
kubernetesVersion: 1.32.1              # Explicitly specifying Kubernetes version 1.31.1
controlPlaneEndpoint: "$(hostname):6443"     # Using the 'k8s-cp' alias defined in /etc/hosts for the control plane endpoint
networking:
  podSubnet: 192.168.0.0/16
EOF
kubeadm init --config=kubeadm-config.yaml --upload-certs --node-name=$(hostname) \
| tee kubeadm-init.out                

echo "kubeadm-config.yaml generated successfully."

export KUBECONFIG=/etc/kubernetes/admin.conf

echo "exported KUBECONFIG"

cat <<EOF > /tmp/setup_kubeconfig.sh
#!/bin/bash
mkdir -p \$HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf \$HOME/.kube/config
sudo chown \$(id -u):\$(id -g) \$HOME/.kube/config
EOF

echo "created /tmp/setup_kubeconfig.sh file"
