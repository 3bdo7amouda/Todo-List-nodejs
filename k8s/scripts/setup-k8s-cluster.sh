#!/bin/bash

# Kubernetes Cluster Setup Script for Todo List Application
# This script sets up a Kubernetes cluster with your VM as master and EC2 instances as workers

set -e

echo "🚀 Setting up Kubernetes Cluster for Todo List Application"
echo "=========================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
MASTER_IP="192.168.100.101"  # Your VM IP
WORKER1_IP="40.172.190.235"  # EC2 instance 1
WORKER2_IP="3.28.200.103"    # EC2 instance 2
KUBECONFIG_FILE="$HOME/.kube/config"

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Step 1: Install Docker and Kubernetes on Master Node
install_k8s_master() {
    print_status "Installing Kubernetes on Master Node..."
    
    # Update system
    sudo apt update
    sudo apt upgrade -y
    
    # Install Docker if not already installed
    if ! command -v docker &> /dev/null; then
        print_status "Installing Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker $USER
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

# Step 2: Initialize Kubernetes Master
init_k8s_master() {
    print_status "Initializing Kubernetes Master..."
    
    # Initialize cluster
    sudo kubeadm init --apiserver-advertise-address=$MASTER_IP --pod-network-cidr=10.244.0.0/16
    
    # Setup kubeconfig
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
    
    # Install Flannel CNI
    kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
    
    print_status "Master node initialized successfully!"
}

# Step 3: Get join command for worker nodes
get_join_command() {
    print_status "Generating worker node join command..."
    
    JOIN_COMMAND=$(sudo kubeadm token create --print-join-command)
    echo "Worker nodes can join the cluster using:"
    echo "$JOIN_COMMAND"
    
    # Save join command to file
    echo "$JOIN_COMMAND" > ~/k8s-join-command.sh
    chmod +x ~/k8s-join-command.sh
    
    print_status "Join command saved to ~/k8s-join-command.sh"
}

# Step 4: Install essential cluster components
install_cluster_components() {
    print_status "Installing essential cluster components..."
    
    # Install NGINX Ingress Controller
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml
    
    # Install Metrics Server
    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
    
    # Patch metrics server for development (ignore TLS)
    kubectl patch deployment metrics-server -n kube-system --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'
    
    print_status "Essential components installed!"
}

# Step 5: Label worker nodes (run after workers join)
label_worker_nodes() {
    print_status "Waiting for worker nodes to join..."
    
    # Wait for nodes to be ready
    while [[ $(kubectl get nodes --no-headers | grep -c "Ready") -lt 3 ]]; do
        echo "Waiting for all nodes to be ready..."
        sleep 10
    done
    
    # Label worker nodes
    kubectl label node $(kubectl get nodes -o jsonpath='{.items[1].metadata.name}') node-role.kubernetes.io/worker=worker
    kubectl label node $(kubectl get nodes -o jsonpath='{.items[2].metadata.name}') node-role.kubernetes.io/worker=worker
    
    print_status "Worker nodes labeled successfully!"
}

# Step 6: Create registry secret for private Docker registry
create_registry_secret() {
    print_status "Creating Docker registry secret..."
    
    read -p "Enter your Docker registry URL: " REGISTRY_URL
    read -p "Enter your Docker registry username: " REGISTRY_USERNAME
    read -s -p "Enter your Docker registry password: " REGISTRY_PASSWORD
    echo
    
    kubectl create secret docker-registry registry-secret \
        --docker-server=$REGISTRY_URL \
        --docker-username=$REGISTRY_USERNAME \
        --docker-password=$REGISTRY_PASSWORD \
        --docker-email=your-email@example.com \
        -n todo-app
    
    print_status "Registry secret created successfully!"
}

# Main execution
main() {
    case "${1:-all}" in
        "master")
            install_k8s_master
            init_k8s_master
            get_join_command
            install_cluster_components
            ;;
        "components")
            install_cluster_components
            ;;
        "labels")
            label_worker_nodes
            ;;
        "registry")
            create_registry_secret
            ;;
        "all")
            install_k8s_master
            init_k8s_master
            get_join_command
            install_cluster_components
            echo ""
            print_warning "Next steps:"
            print_warning "1. Run the join command on your EC2 worker nodes"
            print_warning "2. Run: $0 labels (after workers join)"
            print_warning "3. Run: $0 registry (to create registry secret)"
            ;;
        *)
            echo "Usage: $0 {master|components|labels|registry|all}"
            echo ""
            echo "Commands:"
            echo "  master     - Install and initialize master node"
            echo "  components - Install cluster components (ingress, metrics)"
            echo "  labels     - Label worker nodes (run after workers join)"
            echo "  registry   - Create Docker registry secret"
            echo "  all        - Run complete master setup"
            exit 1
            ;;
    esac
}

main "$@"