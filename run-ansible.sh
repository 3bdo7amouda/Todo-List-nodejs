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
    ansible all -m command -a "docker ps"
    ;;
  *)
    echo "Usage: $0 {test|setup|deploy|status}"
    echo ""
    echo "Commands:"
    echo "  test   - Test Ansible connectivity to servers"
    echo "  setup  - Configure servers with Docker and dependencies"
    echo "  deploy - Deploy Todo App using Docker Compose"
    echo "  status - Check running containers on servers"
    exit 1
    ;;
esac