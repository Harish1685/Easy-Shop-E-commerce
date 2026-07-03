#!/bin/bash
set -e

# Update
apt update -y

# Java
apt install -y fontconfig openjdk-21-jdk

# Jenkins
mkdir -p /etc/apt/keyrings

wget -O /etc/apt/keyrings/jenkins-keyring.asc \
https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key

echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" \
> /etc/apt/sources.list.d/jenkins.list

apt update -y
apt install -y jenkins

# Docker
apt install -y docker.io
usermod -aG docker ubuntu
usermod -aG docker jenkins

systemctl enable docker
systemctl start docker

systemctl enable jenkins
systemctl start jenkins

# Trivy
curl -fsSL https://aquasecurity.github.io/trivy-repo/deb/public.key \
| gpg --dearmor -o /usr/share/keyrings/trivy.gpg

echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb noble main" \
> /etc/apt/sources.list.d/trivy.list

apt update -y
apt install -y trivy

# AWS CLI
snap install aws-cli --classic

# Helm
snap install helm --classic

# kubectl
snap install kubectl --classic