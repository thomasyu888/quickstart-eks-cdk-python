#!/bin/bash

# Script to install prerequistes on Ubuntu 20.04.2 LTS (including via Windows 10's WSL) 

# Install Node & Pyton
apt update -y
apt upgrade -y
curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
apt update -y
apt install nodejs python3-pip python3-testresources unzip -y
#ln -s /usr/bin/pip3 /usr/bin/pip
#ln -s /usr/bin/python3 /usr/bin/python

# Install the latest AWS CLI
cd /tmp
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

# Install kubectl from the deb repo
apt-get install -y apt-transport-https ca-certificates curl
curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubectl

# Install Flux
curl -s https://fluxcd.io/install.sh | sudo bash

# Install Helm
curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
sudo apt-get install apt-transport-https --yes
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm
