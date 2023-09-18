echo "Installing ruby, git, unzip, vim, nmap, python3.9"
echo "-------------------------------------------------"
sudo dnf install -y git ruby unzip vim python3.9 python3-pip nmap
echo ""

echo "Installing tty-prompt"
echo "---------------------"
sudo gem install tty-prompt
echo ""

echo "Installing Azure cli version(2.49.0)"
echo "------------------------------------"
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo dnf install -y https://packages.microsoft.com/config/rhel/8/packages-microsoft-prod.rpm
sudo dnf install -y azure-cli-2.49.0-1.el8
echo ""

echo "Installing aws cli version(2.13.12)"
echo "-----------------------------------"
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-2.13.12.zip" -o "awscliv2.zip"
unzip -o awscliv2.zip
sudo ./aws/install
rm awscliv2.zip
echo ""

echo "Installing openStack client cli version(6.0.0) and heat client version(2.5.0)"
echo "-----------------------------------------------------------------------------"
python3.9 -m venv ~/.openstack
source ~/.openstack/bin/activate
pip install -U pip
pip install python-openstackclient==6.0.0
pip install python-heatclient==2.5.0
pip install pytest==7.4.2
pip install pytest-ordering==0.6
pip install bcrypt==4.0.1
pip install cffi==1.15.1
pip install cryptography==41.0.3
pip install exceptiongroup==1.1.3
pip install iniconfig==2.0.0
pip install packaging==23.1
pip install paramiko==3.3.1
pip install pluggy==1.3.0
pip install pycparser==2.21
pip install PyNaCl==1.5.0
pip install pytest-testinfra==9.0.0
pip install PyYAML==6.0.1
pip install tomli==2.0.1
pip install pytest-reportlog-0.4.0
deactivate
touch ~/.openrc
echo ""

echo "Making dir echo Cloud Providers cli installed:"
echo "----------------------------------------------"
mkdir -p /var/log/reference-evaluation

echo "Cloud Providers cli installed:"
echo "------------------------------"
echo "AWS"
echo "---"
aws --version
echo ""

echo "Azure"
echo "------"
az --version
echo ""

echo "OpenStack"
echo "---------"
source ~/.openstack/bin/activate
openstack --version
deactivate
echo ""


