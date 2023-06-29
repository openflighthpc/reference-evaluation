# How to setup the Cluster Launcher

## Assumptions
- It is assumed that the file path of the repo is `~/git/reference-evaluation/`
- These instructions were tested on a Centos 8 machine,.

## Required installations
Installations:
```
sudo yum install -y git ruby unzip
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo yum install -y https://packages.microsoft.com/config/rhel/8/packages-microsoft-prod.rpm
sudo yum install -y azure-cli
```

## Optional Installations
```
sudo yum install -y vim 
sudo yum install -y python3-pip nmap; sudo pip3 install cram 
# can't run cram interactively?
```
- Vim is a great command line editor, I highly recommend it for coding or just general file editing on the CLI. 
- Python3, nmap and cram are all needed if you want to create/run tests locally. Otherwise you don't need them.

## Setup aws

Download this zip file
```
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
```
unzip it 
```
unzip awscliv2.zip
```
install the unzipped folder
```
sudo ./aws/install
```
Configure credentials by running this command, then following the instructions
```
aws configure
```

Configuration example that I do:
```
[user@machine ~]$ aws configure
AWS Access Key ID [None]: ***
AWS Secret Access Key [None]: ***
Default region name [None]: eu-west-2
Default output format [None]: 
```
*Note that \*\*\* is where you would put your access key and secret access key, don't actually put asterisks*
[Source](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)


## Setup azure

Required software was installed during the installation step, simply authenticate with:
```
az login
```

You will need a web browser (doesn't have to be on that instance), and a microsoft account and azure credentials


## Get the git repo
Get the repo
```
cd ~
mkdir git
cd git
git clone https://github.com/openflighthpc/reference-evaluation.git
```

## Setup openstack
```
cd ~/git/reference-evaluation/deployment_automated/setup
```

### create a directory with a python "virtual environment" called "openstack" 
```
python3 -m venv openstack 
```

### activate the openstack virtual environment
```
source openstack/bin/activate
```

### check no openstack packages
```
pip3 list | grep client
```

### Install openstack client
```
pip install python-openstackclient python-heatclient
```

### Get the openstack project rc file

1. Go to openstack, and under "Project" should be the heading "API Access" - click on it. 
2. On the far right of the page should be a button that says "Download Openstack RC File⬇"
3. Click on it and two options will drop down.
4. Click on "Openstack RC File" which will download a file name "\*-openrc.sh".
5. Copy that file into `~/git/reference-evaluation/deployment_automated/setup`

### Set the openstack project rc File variable

1. In `run_auto_tests.sh`, around line 3, change `openstack_rc_filepath` to be the filepath of the openstack rc file you have downloaded.
2. In `config.rb`, around line 18, change `openstack_rc_filepath` to be the filepath of the openstack rc file.

### (optional) remove the openstack rc verification question
1. Go to the openstack project rc file and open it with an editor.
2. Delete lines 29 and 30.
3. On the new line 29, it should say `export OS_PASSWORD=$OS_PASSWORD_INPUT` 
4. Swap `$OS_PASSWORD_INPUT` for your openstack password.
5. Save and close the file.

## After the repo has been cloned

Get tty-prompt
```
cd ~/git/reference-evaluation/deployment_automated
gem install tty-prompt
```

## Set your keys
You will need a ssh key associated with each platform in order to be able to launch a cluster. But this is beyond the scope of this documention, from now on it is assumed that you have created a keypair/already have a keypair for Openstack, AWS and Azure, and that you have the .pem file locally.

1. (optional) There is a dedicated directory for storing keys (`reference-evaluation/deployment_automated/keys
`), which you may find to be a convenient location to leave your .pem files. This git reposity ignores `.pem` files.

2. Go to  `deployment_automated/1_setup.sh`
- Set `openstack_keyfile`, `aws_keyfile` and `azure_keyfile` to the locations of the private key files you use with each platform.
- Set `openstack_key`, `aws_key` and `azure_key` to the names of the keys as they are called on the relevant platform.


## Running it
Run the cluster launcher
```
cd ~/git/reference-evaluation/deployment_automated
ruby config.rb
```

