#!/bin/bash

# Kubernetes Worker Node Setup Script for EC2 Instances
# Run this script on each EC2 worker node

set -e

echo "🚀 Setting up Kubernetes Worker Node"
echo "===================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Step 1: Install Docker and Kubernetes components
install_k8s_worker() {
    print_status "Installing Kubernetes components on worker node..."
    
    # Update system
    sudo apt update
    sudo apt upgrade -y
    
    # Install Docker
    if ! command -v docker &> /dev/null; then
        print_status "Installing Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker ubuntu
        rm get-docker.sh
    fi
    
    # Install Kubernetes components
    sudo apt-get update
    sudo apt-get install -y apt-transport-https ca-certificates curl
    
    # Add Kubernetes apt repository
    curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg
    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
    
    sudo apt-get update
    sudo apt-get install -y kubelet kubeadm kubectl
    sudo apt-mark hold kubelet kubeadm kubectl
    
    # Disable swap
    sudo swapoff -a
    sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
    
    print_status "Kubernetes components installed successfully!"
}

# Step 2: Configure system settings
configure_system() {
    print_status "Configuring system settings..."
    
    # Load required kernel modules
    cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
    
    sudo modprobe overlay
    sudo modprobe br_netfilter
    
    # Set required sysctl parameters
    cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
    
    sudo sysctl --system
    
    print_status "System configuration completed!"
}

# Step 3: Join cluster (interactive)
join_cluster() {
    print_warning "Ready to join the Kubernetes cluster!"
    print_warning "Please run the join command provided by the master node."
    print_warning "The command should look like:"
    print_warning "sudo kubeadm join <master-ip>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>"
    echo ""
    read -p "Do you have the join command? (y/n): " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Please run the join command now in another terminal, then press Enter to continue..."
        read -p "Press Enter after running the join command..."
        print_status "Worker node should now be part of the cluster!"
    else
        print_error "Please get the join command from the master node and run it manually."
        print_error "You can generate a new token on the master with: kubeadm token create --print-join-command"
    fi
}

# Step 4: Verify installation
verify_installation() {
    print_status "Verifying installation..."
    
    # Check Docker
    if systemctl is-active --quiet docker; then
        print_status "✓ Docker is running"
    else
        print_error "✗ Docker is not running"
    fi
    
    # Check kubelet
    if systemctl is-active --quiet kubelet; then
        print_status "✓ Kubelet is running"
    else
        print_warning "⚠ Kubelet may not be running (normal before joining cluster)"
    fi
    
    print_status "Installation verification completed!"
}

# Main execution
main() {
    case "${1:-all}" in
        "install")
            install_k8s_worker
            configure_system
            ;;
        "join")
            join_cluster
            ;;
        "verify")
            verify_installation
            ;;
        "all")
            install_k8s_worker
            configure_system
            verify_installation
            join_cluster
            ;;
        *)
            echo "Usage: $0 {install|join|verify|all}"
            echo ""
            echo "Commands:"
            echo "  install - Install Kubernetes components"
            echo "  join    - Interactive cluster join process"
            echo "  verify  - Verify installation"
            echo "  all     - Run complete worker setup"
            exit 1
            ;;
    esac
}

main "$@"