#!/bin/bash

# Update and upgrade the system using apt
sudo apt update
sudo apt upgrade -y

#Check Ubuntu 22.04 and update kernel
lsb_release=$(lsb_release -a | grep "22.04")
if [[ -n "$lsb_release" ]]; then

    # Check if there's a video card with Nvidia (10de) H100 model (23xx)
    lspci_output=$(lspci -nnk | awk '/\[10de:23[0-9a-f]{2}\]/ {print $0}')
    if [[ -n "$lspci_output" ]]; then
        echo "A100 detected"
        # If yes install the necessary kernel package
        sudo apt install -y linux-generic-hwe-22.04
    fi

    # Check if there's a video card with Nvidia (10de) A100 model (20xx)
    lspci_output=$(lspci -nnk | awk '/\[10de:20[0-9a-f]{2}\]/ {print $0}')
    if [[ -n "$lspci_output" ]]; then
        echo "A100 detected"
        # If yes install the necessary kernel package
        sudo apt install -y linux-generic-hwe-22.04
    fi
fi

# Install Ubuntu drivers common package
sudo apt install ubuntu-drivers-common -y

recommended_driver=$(ubuntu-drivers devices | grep 'nvidia' | cut -d ',' -f 1 | grep 'recommended')
package_name=$(echo $recommended_driver | awk '{print $3}')
sudo apt install $package_name -y

# Install GCC compiler for CUDA install
sudo apt install gcc -y

# Get the release version of Ubuntu
RELEASE_VERSION=$(lsb_release -rs | sed 's/\([0-9]\+\)\.\([0-9]\+\)/\1\2/')

# Download and install CUDA package for Ubuntu
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu${RELEASE_VERSION}/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb

# Update and upgrade the system again to ensure all packages are installed correctly
sudo apt update
sudo apt install cuda -y
sudo apt install nvidia-cuda-toolkit -y

# Add PATH and LD_LIBRARY_PATH environment variables for CUDA in .bashrc file
echo 'export PATH="/usr/bin:/bin:$PATH/usr/local/cuda/bin\${PATH:+:\${PATH}}"' >> ~/.bashrc
echo 'export LD_LIBRARY_PATH=/usr/local/cuda-12.2/lib64\${LD_LIBRARY_PATH:+:\${LD_LIBRARY_PATH}}' >> ~/.bashrc
source ~/.bashrc

#Installing Docker binding for Nvidia

if command -v docker &> /dev/null; then
  echo "Docker is installed."
  sudo apt install -y nvidia-docker2
  sudo systemctl restart docker
else
  echo "Docker is not installed."
fi

#Reboot the system for enable kernel modules
reboot