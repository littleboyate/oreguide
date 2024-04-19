#!/bin/bash
INSTALLATION_DIR=$(dirname "$(realpath "$0")")
sudo apt update -y &&
sudo apt-get update -y &&
sudo apt-get install -y build-essential gapt update bc jq &&
sudo apt install -y build-essential screen &&
sudo apt-get update -y &&


sudo apt install -y apt-transport-https ca-certificates curl software-properties-common &&

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - &&

sudo apt update && sudo apt install -y apt-transport-https ca-certificates curl software-properties-common && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - && sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" && sudo apt update && sudo apt install -y docker-ce && sudo systemctl start docker && sudo systemctl enable docker &&

sudo echo "deb http://security.ubuntu.com/ubuntu jammy-security main" >> /etc/apt/sources.list && sudo apt -qy update && sudo apt -qy install libc6

sudo apt-get update -y && sudo apt-get install git -y &&

git clone https://github.com/CryptoNodeID/pingpong.git &&

cd pingpong && chmod ug+x *.sh && ./setup.sh

