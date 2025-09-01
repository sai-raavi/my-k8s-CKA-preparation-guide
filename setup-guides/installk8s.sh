#!/bin/bash
# Exit immediately if any command fails.
set -e

basic_update() {
   echo "performing basic update and installing essential pkgs"
   apt-get update && apt-get upgrade -y
   apt-get install -y apt-transport-https ca-certificates curl gpg software-properties-common

   echo "Basic update and essential package installation complete."

   enable_modules || { echo "Error: 'enable_modules' function failed."; exit 1; }

}

enable_modules() { # Corrected function name and added closing brace
    echo "Enabling modules like overlay and br_netfilter, which are needed for filesystem and network handling."

    modprobe overlay || { echo "Error: Failed to load overlay module."; exit 1; }
    modprobe br_netfilter || { echo "Error: Failed to load br_netfilter module."; exit 1; }

    cat << EOF | tee /etc/sysctl.d/kubernetes.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
    # Check if tee command was successful
    if [ $? -ne 0 ]; then
        echo "Error: Failed to write sysctl configuration."
        exit 1
    fi

    echo "Applying sysctl settings..."
    sysctl --system || { echo "Error: Failed to apply sysctl settings."; exit 1; }

    echo "Module and sysctl configuration complete."
    install_containerd || { echo "Error: 'install_containerd' function failed."; exit 1; }

}

install_containerd() {

    mkdir -p /etc/apt/keyrings
    
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg || \
        { echo "Error: Failed to download or dearmor Docker GPG key."; exit 1; }
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null || \
        { echo "Error: Failed to add Docker APT repository."; exit 1; }

    echo "Updating apt package index and installing containerd.io..."
    apt-get update &&  apt-get install containerd.io -y

    echo "Generating and configuring containerd default configuration..."
    containerd config default | tee /etc/containerd/config.toml

    # Modify containerd config to use systemd cgroup driver.
    sed -e 's/SystemdCgroup = false/SystemdCgroup = true/g' -i /etc/containerd/config.toml
    
    echo "Restarting containerd service to apply changes..."
    systemctl restart containerd || { echo "Error: Failed to restart containerd service."; exit 1; }

    echo "Containerd installation and configuration complete."

    install_k8s || { echo "Error: 'install_k8s' function failed."; exit 1; }
}

install_k8s() {

   #### Install Kubernetes latest components
   echo "starting the installation of k8s components (kubeadm,kubelet,kubectl) ...."
   curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
   echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /" | tee -a /etc/apt/sources.list.d/kubernetes.list
   apt-get update
   apt-get install -y kubelet kubeadm kubectl || { echo "Error: Failed to install kubelet, kubeadm, kubectl."; exit 1; }
   echo "kubelet, kubeadm & kubectl are successfully installed"
   apt-mark hold kubelet kubeadm kubectl || { echo "Error: Failed to hold Kubernetes packages."; exit 1; }

}



################ MAIN ###################

if [ -f /etc/os-release ]; then
    # Extract the OS ID from /etc/os-release.
    osname=$(grep ID /etc/os-release | egrep -v 'VERSION|LIKE|VARIANT|PLATFORM' | cut -d'=' -f2 | sed -e 's/"//g') # Added 'g' for global replace
    echo "Detected OS: $osname"

    # Compare the detected OS name with "ubuntu".
    if [ "$osname" == "ubuntu" ]; then # Added quotes for robustness
        basic_update # Start the main installation process
    else
        echo "This script only works for Ubuntu. Detected OS: $osname"
        exit 1 # Use a non-zero exit code to indicate failure
    fi
else
    echo "Cannot locate /etc/os-release - unable to determine the OS name."
    exit 8
fi

echo "Script completed successfully."
exit 0
