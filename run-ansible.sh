#!/bin/bash
# Script to run Ansible playbooks for Todo App deployment

echo "🚀 Todo App Ansible Deployment Script"
echo "======================================"

case "$1" in
  test)
    echo "🔍 Testing Ansible connectivity..."
    ansible all -m ping
    ;;
  setup)
    echo "⚙️  Setting up EC2 servers..."
    ansible-playbook ansible/playbooks/setup-servers.yml
    ;;
  deploy)
    echo "🚀 Deploying Todo App..."
    ansible-playbook ansible/playbooks/deploy-app.yml
    ;;
  status)
    echo "📊 Checking server status..."
    ansible-playbook ansible/playbooks/status-check.yml
    ;;
  full)
    echo "🔄 Running full setup and deployment..."
    echo "Step 1: Testing connectivity..."
    ansible all -m ping
    echo ""
    echo "Step 2: Setting up servers..."
    ansible-playbook ansible/playbooks/setup-servers.yml
    echo ""
    echo "Step 3: Deploying application..."
    ansible-playbook ansible/playbooks/deploy-app.yml
    ;;
  *)
    echo "Usage: $0 {test|setup|deploy|status|full}"
    echo ""
    echo "Commands:"
    echo "  test   - Test Ansible connectivity to servers"
    echo "  setup  - Configure servers with Docker and dependencies"
    echo "  deploy - Deploy Todo App using Docker Compose"
    echo "  status - Check application status and running containers"
    echo "  full   - Run complete setup and deployment process"
    exit 1
    ;;
esac