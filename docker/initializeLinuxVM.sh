#!/bin/bash

# Install docker
# This is taken from: https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-16-04
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
apt-cache policy docker-ce
sudo apt-get install -y docker-ce
# Execute docker without SUDO
sudo usermod -aG docker clperf

# Install odbc driver
# Taken from: https://docs.microsoft.com/en-us/sql/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server?view=sql-server-2017

curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
curl https://packages.microsoft.com/config/ubuntu/16.04/prod.list > /etc/apt/sources.list.d/mssql-release.list

sudo apt-get update
sudo ACCEPT_EULA=Y apt-get install msodbcsql
sudo ACCEPT_EULA=Y apt-get install mssql-tools
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bash_profile
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc
source ~/.bashrc

sudo apt-get install python3-all python3-pip python3-venv
sudo apt-get install unixodbc unixodbc-dev

# Initializing python vEnv
mkdir -p ~/python_venvs
python3 -m venv ~/python_venvs/swarmEnv
source ~/python_venvs/swarmEnv/bin/activate
pip3.5 install -r ~/swarmServiceCreator/requirments.txt

su - clperf
