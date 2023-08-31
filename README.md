# Reference Cluster Evaluation

A series of scripts to evaluate the configuration and functionality  of a cluster. The configuration tests are designed for a cluster built with the cluster config instructions in this [documentation](https://docs.openflighthpc.org/cluster_build_methods/manual/centos8_slurm_multi_manual/introduction/).

The deployment templates directory contains templates to start a 3 node cluster (1 login, 2 compute) with Flight Solo on every currently supported platform. The idea of these is to make testing Flight Solo faster.

See [here](https://docs.openflighthpc.org/cluster_build_methods/manual/centos8_slurm_multi_manual/configuration_testing/) for information about the configuration tests.

See [here](https://docs.openflighthpc.org/functionality_testing/automatic_tests/#automatic-tests) for information about the functionality tests.

See [here](https://docs.openflighthpc.org/functionality_testing/automatic_tests/#automatic-web-suite-testing) for information about functionality tests for web suite.

## Setup and Usage of the Cluster Launcher

### Requirements:
You will need:
- the AWS CLI
- the Azure CLI
- Python
- Cram
- Ruby
- tty-prompt
- the openstack CLI

### Setup
Installation and usage of reference-evaluation is done in 5 steps.
1. Install all the required cli for this repository to work.
2. Configure the credentials, openrc and web login to make sure cli is able to connect cloud providers successfully.
3. Verify the keypairs and images for release under test is available in the cloud and also updated in `setup_1.sh`
4. Build and test the clusters.
5. Verify the results.

#### 1. Install the required tools
Install the tools required for this repository to work like ruby, python, aws, azure and openstack cli.
```
cd reference-evaluation/
sudo bash tools-installation-scripts.sh
```

#### 2. Configure credentials(aws), openrc(openstack) and web authentication(azure)

##### Configure AWS credentials
Configure credentials by running this command, then add your aws access key, aws secret key, default region name and output format.
```
[user@machine ~]$ aws configure
AWS Access Key ID [None]: ***
AWS Secret Access Key [None]: ***
Default region name [None]: eu-west-2
Default output format [None]: 
```

Once all the information are added you can validate cloud access by running the below command, if it works fine then configuration is completed.
```
aws ec2 describe-instances
```

##### Configure Azure credentials
Configure credentials by running this command, the command will return the link and secret.
```
az login
```

You will need a web browser to open the link provided by command, and a microsoft account and azure credentials for successful authentication.

Once all the information are added you can validate cloud access by running the below command, if it works fine then configuration is completed.
```
az group list
```

##### Configure OpenStack credentials
Go to openstack(horizon) using web browser, and under "Project" should be the heading "API Access" - click on it, On the far right of the page should be a button that says "Download Openstack RC File⬇" and then click on it and two options will drop down.

Click on "Openstack RC File" which will download a file name "*-openrc.sh", then copy the content of "*-openrc.sh" file to `~/.openrc` file in the shell where we have installed cli.

Instead of taking password from prompt, it is suggested to pass password in openrc file, remove or comment below lines in openrc file.
`echo "Please enter your OpenStack Password for project $OS_PROJECT_NAME as user $OS_USERNAME: "` 
`read -sr OS_PASSWORD_INPUT `

and in line `export OS_PASSWORD=$OS_PASSWORD_INPUT` we have `$OS_PASSWORD_INPUT` replace it with openstack password and then save the file.

Once all the information are added you can validate cloud access by running the below command, if it works fine then configuration is completed.
```
source ~/.openrc
openstack server list
```

#### 3. Verify cluster resources are placed in cloud environments
TBD

#### 4. Cluster building and testing
TBD

#### 5. Result Verification
TBD

### Usage
- Run `config.rb` to use the interactive cluster launcher.
- Run `run_auto_tests.sh` to run a series of Flight Solo tests automatically.
