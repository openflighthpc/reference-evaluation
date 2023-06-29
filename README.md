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
1. Install and configure all the required tools.
2. Set aws, azure and openstack keypair locations correctly in `1_setup.sh`
3. Download and set the location of the openstack rc file.
*See `docs/setup_cluster_launcher.md` for a more in depth guide on setup*

### Usage
- Run `config.rb` to use the interactive cluster launcher.
- Run `run_auto_tests.sh` to run a series of Flight Solo tests automatically.
