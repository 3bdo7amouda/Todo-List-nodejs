#!/bin/bash

# ArgoCD Installation and Setup Script for Todo List Application
# This script installs ArgoCD and configures it for GitOps deployment

set -e

echo "🚀 Installing and Configuring ArgoCD for Todo List Application"
echo "=============================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Step 1: Install ArgoCD
install_argocd() {
    print_status "Installing ArgoCD..."
    
    # Create ArgoCD namespace
    kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
    
    # Install ArgoCD
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    
    # Wait for ArgoCD to be ready
    print_status "Waiting for ArgoCD to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
    
    print_status "ArgoCD installed successfully!"
}

# Step 2: Configure ArgoCD Service
configure_argocd_service() {
    print_status "Configuring ArgoCD service for external access..."
    
    # Patch ArgoCD server service to NodePort
    kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort", "ports": [{"port": 443, "nodePort": 30443, "name": "https"}, {"port": 80, "nodePort": 30080, "name": "http"}]}}'
    
    # Alternatively, create LoadBalancer service (comment out NodePort above if using this)
    # kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
    
    print_status "ArgoCD service configured!"
}

# Step 3: Get ArgoCD admin password
get_argocd_password() {
    print_status "Retrieving ArgoCD admin password..."
    
    # Wait for initial admin secret to be created
    while ! kubectl -n argocd get secret argocd-initial-admin-secret &> /dev/null; do
        echo "Waiting for ArgoCD initial admin secret..."
        sleep 5
    done
    
    ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
    
    echo ""
    print_info "================================================"
    print_info "ArgoCD Admin Credentials:"
    print_info "Username: admin"
    print_info "Password: $ARGOCD_PASSWORD"
    print_info "================================================"
    echo ""
    
    # Save credentials to file
    cat > ~/argocd-credentials.txt << EOF
ArgoCD Admin Credentials
========================
Username: admin
Password: $ARGOCD_PASSWORD

Access URLs:
- NodePort: https://your-master-ip:30443
- LoadBalancer: Check 'kubectl get svc argocd-server -n argocd' for external IP

Setup Date: $(date)
EOF
    
    print_status "Credentials saved to ~/argocd-credentials.txt"
}

# Step 4: Install ArgoCD CLI
install_argocd_cli() {
    print_status "Installing ArgoCD CLI..."
    
    # Download and install ArgoCD CLI
    curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
    sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
    rm argocd-linux-amd64
    
    print_status "ArgoCD CLI installed successfully!"
}

# Step 5: Configure ArgoCD for insecure mode (development)
configure_insecure_mode() {
    print_status "Configuring ArgoCD for insecure mode (development)..."
    
    kubectl patch configmap argocd-cmd-params-cm -n argocd --type merge -p '{"data":{"server.insecure":"true"}}'
    kubectl rollout restart deployment argocd-server -n argocd
    
    print_status "ArgoCD configured for insecure mode!"
}

# Step 6: Create ArgoCD application for Todo app
create_todo_application() {
    print_status "Creating Todo List application in ArgoCD..."
    
    # Apply the ArgoCD project and application
    kubectl apply -f ../argocd/todo-project.yaml
    kubectl apply -f ../argocd/todo-app-application.yaml
    
    print_status "Todo List application created in ArgoCD!"
}

# Step 7: Setup repository access (if private repo)
setup_repository_access() {
    print_warning "Setting up repository access..."
    print_info "If your repository is private, you need to configure repository access in ArgoCD."
    print_info "You can do this through the ArgoCD UI or CLI:"
    print_info ""
    print_info "Via CLI:"
    print_info "argocd repo add https://github.com/3bdo7amouda/Todo-List-nodejs.git --username <username> --password <token>"
    print_info ""
    print_info "Via UI:"
    print_info "1. Go to Settings → Repositories"
    print_info "2. Click 'Connect Repo using HTTPS'"
    print_info "3. Enter your repository URL and credentials"
}

# Step 8: Display access information
display_access_info() {
    print_info ""
    print_info "🎉 ArgoCD Setup Complete!"
    print_info "========================="
    print_info ""
    
    # Get service information
    MASTER_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
    
    print_info "ArgoCD Access Information:"
    print_info "- UI URL: https://$MASTER_IP:30443"
    print_info "- Username: admin"
    print_info "- Password: Check ~/argocd-credentials.txt"
    print_info ""
    print_info "Next Steps:"
    print_info "1. Access ArgoCD UI and verify the Todo application is created"
    print_info "2. Configure repository access if using private repo"
    print_info "3. Sync the application to deploy your Todo List app"
    print_info "4. Monitor the deployment in ArgoCD dashboard"
    print_info ""
    print_info "Useful Commands:"
    print_info "- Check ArgoCD status: kubectl get pods -n argocd"
    print_info "- Check Todo app status: kubectl get pods -n todo-app"
    print_info "- ArgoCD CLI login: argocd login $MASTER_IP:30443"
}

# Main execution
main() {
    case "${1:-all}" in
        "install")
            install_argocd
            configure_argocd_service
            get_argocd_password
            ;;
        "cli")
            install_argocd_cli
            ;;
        "configure")
            configure_insecure_mode
            ;;
        "app")
            create_todo_application
            ;;
        "info")
            display_access_info
            ;;
        "all")
            install_argocd
            configure_argocd_service
            get_argocd_password
            install_argocd_cli
            configure_insecure_mode
            sleep 10  # Wait for restart
            create_todo_application
            setup_repository_access
            display_access_info
            ;;
        *)
            echo "Usage: $0 {install|cli|configure|app|info|all}"
            echo ""
            echo "Commands:"
            echo "  install   - Install ArgoCD and configure service"
            echo "  cli       - Install ArgoCD CLI"
            echo "  configure - Configure ArgoCD for insecure mode"
            echo "  app       - Create Todo application in ArgoCD"
            echo "  info      - Display access information"
            echo "  all       - Run complete ArgoCD setup"
            exit 1
            ;;
    esac
}

main "$@"