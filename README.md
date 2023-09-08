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

----
### Setup
Installation and usage of reference-evaluation is done in 5 steps.
1. Install all the required cli for this repository to work.
2. Configure the credentials, openrc and web login to make sure cli is able to connect cloud providers successfully.
3. Verify the keypairs and images for release under test is available in the cloud and also updated in `setup_1.sh`
4. Build and test the clusters.
5. Verify the results.

----
#### 1. Install the required tools
Install the tools required for this repository to work like ruby, python, aws, azure and openstack cli.
```
cd reference-evaluation/deployment_automated/scripts
sudo bash tools-installation-scripts.sh
```
---

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
---

#### 3. Verify cluster resources are placed in cloud environments and local configuration
Validate the existence of below resources in cloud providers as per the release and user.

##### OpenStack
- `Release Image` : Correct image should be present in cloud provider.
- `Keypair`: Either we can create a keypair or add our existing public key in cloud provider.
- `Public Network`: Check whether external/public network is placed in the environment.

##### AWS
- `Release Image` : Correct image should be present in cloud provider.
- `Keypair`: Either we can create a keypair or add our existing public key in cloud provider.

##### Azure
- `Release Image` : Correct image should be present in cloud provider.
- `Keypair`: Either we can create a keypair or add our existing public key in cloud provider.

Once we have verified the resources in the cloud providers, next we need to check the local configuration.

Create a copy of configutation with below command
```
cp reference-evaluation/deployment_automated/etc/regression.conf.example reference-evaluation/deployment_automated/etc/regression.conf
```
Then populated the configuration by taking information from cloud providers

We also need to create private key files with name `os_key`, `aws_key`, `azure_key` at path `reference-evaluation/deployment_automated/keys/`, once files are created copy the content of private key to those files.

---

#### 4. Cluster building and testing
Assuming that you are in the git repository's top level directory, change into the `deployment_automated` directory and run `ruby config.rb`
e.g.
```
cd deployment_automated
ruby config.rb
```

##### Answer cluster configuration questions

After running `config.rb` you will be presented with a series of questions for setting up a cluster.

1. `Name of cluster?` - What should the name of the cluster be?
2. `Standalone cluster? (y/N)` - Is this going to be a standalone cluster? This can only be answered as a yes or no, and by default is no.
3. `Launch on what platform?` - A dropdown menu of platform options.
4. `What testing?` - A dropdown menu of testing options. `basic` means only basic tests. `full` means all tests. `none` means no tests. More information about tests can be found on the testing doc page.
5. `What instance size login node?` - A dropdown menu of instance sizes. These correspond to cloud platform instance sizes.
6. `What volume size login node? (GB) (20)` - What disk size in gigabytes, should the login node be?
7. `Share Pub Key?` - Should the Flight Solo user data option to share a public key between login nodes and compute nodes be used? This can only be answered as a yes or no.
8. `Auto Parse match regex` - Enter a regular expression to be passed as Flight Solo user data.
9. `How many compute nodes? (2)` - If launching a multinode cluster, the number of compute nodes can be changed
10. `What instance size compute nodes?` - A drop down menu of instance sizes for the compute nodes in the cluster. These correspond to cloud platform sizes.
11. `What volume size compute nodes (GB) (20)` - What disk size in gigabytes, should each of the compute nodes be?
12. `Delete on success?` - If testing, if all tests pass then the cluster will be deleted on "yes". On "no" then nothing will be deleted regardless of testing outcome.
After finishing the questions, the cluster will start launching. When it is done, it will print out the ip addresses of all nodes in the cluster.
Note:
- A lot of information from commands being run is sent to a log file instead of displayed, this is kept in `deployment_automated/log/stdout`
- Any tests run will have an output file stored on the instance, but also in `deployment_automated/log/tests`
- The template used to launch an instance will be stored in `deployment_automated/log/templates`

---

#### Testing 
TBD

---

#### 5. Result Verification
TBD
