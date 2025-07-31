#!/bin/bash
# Simple script to test Ansible connectivity to EC2 instances

echo "🔍 Testing Ansible connectivity to EC2 instances..."
ansible all -m ping

echo ""
echo "📋 Gathering basic facts from servers..."
ansible all -m setup -a "filter=ansible_distribution*"