# K8s Node Setup Script for Ubuntu
This script (installk8s.sh) automates the essential steps required to prepare an Ubuntu server to become a Kubernetes node.
It installs necessary packages, configures kernel modules, sets up the container runtime (containerd),
and installs the Kubernetes components (kubeadm, kubelet, kubectl).


## Table of Contents
- [Purpose](#Purpose)
- [Features](#Features)
- [Prerequisites](#Prerequisites)
- [How to Use](#How to Use)
- [Important Notes](#Important Notes)

## Prerequisites
      Operating System:
        This script is designed specifically for Ubuntu. It will exit with an error if another OS is detected.
      Root Privileges:
        The script must be run with sudo or as the root user, as it performs system-level modifications and package installations.
      Internet Connectivity:
        The script requires active internet access to download packages and GPG keys from various repositories.


## Purpose
    The main purpose of this script is to streamline the initial setup of a Ubuntu Linux machine to serve as either a Kubernetes Control Plane (Master) node or a Worker node.
    It handles the underlying dependencies and core Kubernetes binaries, getting the system ready for kubeadm to initialize or join a cluster.

## Features
    The script executes the following functions in sequence:


    1. basic_update()
        Performs a system update (apt-get update && apt-get upgrade -y).
        Installs essential packages required for system operations and secure package retrieval, including apt-transport-https, ca-certificates, curl, gpg, and software-properties-common.

    2. enable_modules()
        . Loads Kernel Modules:
            Uses modprobe to load the overlay and br_netfilter kernel modules.
                overlay: Essential for container runtimes (like containerd) to implement efficient image layering (overlay filesystems).
                br_netfilter: Enables iptables rules to properly filter network traffic that bridges between virtual interfaces, which is crucial for Kubernetes networking.
        . Configures Sysctl Parameters:
            Creates /etc/sysctl.d/kubernetes.conf with the following settings:
                net.bridge.bridge-nf-call-ip6tables = 1: Enables iptables processing for IPv6 bridged traffic.
                net.bridge.bridge-nf-call-iptables = 1: Enables iptables processing for IPv4 bridged traffic. These are critical for Kubernetes Network Policies and kube-proxy.
                net.ipv4.ip_forward = 1: Enables IP forwarding on the host, allowing packets to be routed between different network interfaces (necessary for Pod-to-Pod communication across nodes).
        . Applies Sysctl Settings:
        Runs sysctl --system to immediately apply the new kernel parameters.

    3. install_containerd()
        . Adds Docker's APT Repository:
             Configures the official Docker APT repository to ensure access to the containerd.io package. This involves adding the Docker GPG key and the repository definition.
        . Installs Containerd:
             Updates the apt package index and installs containerd.io. Containerd is a robust, high-performance container runtime that Kubernetes uses to manage containers.
        . Generates and Modifies Containerd Configuration:
             Generates a default config.toml file for containerd at /etc/containerd/config.toml.
             Modifies this configuration using sed to set SystemdCgroup = true.
             This is crucial for systems using systemd (like Ubuntu) to ensure that containerd delegates Cgroup management to systemd, preventing resource management conflicts and ensuring stable operation.
        . Restarts Containerd Service:
             Restarts the containerd system service to apply the new configuration.

    4. install_k8s()
        . Adds Kubernetes APT Repository:
             Configures the official Kubernetes APT repository for v1.31 to retrieve Kubernetes components. This involves downloading the Kubernetes GPG key and adding the repository to apt sources.
        . Installs Kubernetes Components:
            Installs kubelet, kubeadm, and kubectl using apt-get.
                kubelet: The agent that runs on each node and ensures containers are running in Pods.
                kubeadm: A tool to bootstrap Kubernetes clusters.
                kubectl: The command-line tool for interacting with a Kubernetes cluster.
        . Holds Package Versions:
            Uses apt-mark hold to prevent kubelet, kubeadm, and kubectl from being accidentally updated during future apt-get upgrade commands.
            This is important to ensure controlled upgrades in a Kubernetes cluster.

## How to Use
    1. Download the script:
            curl -o installk8s.sh https://raw.githubusercontent.com/sai-raavi/my-k8s-CKA-preparation-guide/refs/heads/main/setup-guides/installk8s.sh
    2. Make it executable:
            chmod +x installk8s.sh
    3. Run the script:
            sudo ./installk8s.sh
## Important Notes
       Single Node Setup:
            This script only prepares a single node. To form a complete Kubernetes cluster, you will need to run kubeadm init on one node (Control Plane) and kubeadm join on other nodes (Workers) after this script completes successfully on each.
       Kubernetes Version:
            This script targets Kubernetes v1.31. If you need a different version, you will need to modify the Kubernetes repository URL in the install_k8s() function.
       Networking (CNI):
            This script does not install a Container Network Interface (CNI) plugin (like Calico or Cilium). A CNI plugin is essential for Pod-to-Pod communication after the cluster is initialized. You will need to install one separately after kubeadm init.
       Error Handling:
            The script uses set -e to exit immediately if any command fails and includes basic error messages.
       Idempotency:
             While some steps are idempotent (e.g., modprobe won't fail if a module is already loaded), running the script multiple times without a clean slate might lead to unexpected behavior if package versions change or if the hold marks are manually removed. It's generally intended for initial setup
