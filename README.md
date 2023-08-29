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
TBD 

#### 3. Verify cluster resources are placed in cloud environments
TBD

#### 4. Cluster building and testing
TBD

#### 5. Result Verification
TBD

### Usage
- Run `config.rb` to use the interactive cluster launcher.
- Run `run_auto_tests.sh` to run a series of Flight Solo tests automatically.
