import pytest
import os 
import re
from testinfra import get_host
from time import sleep 
from utils import hosts, is_standalone, cluster_type


class TestCluster():

# jupyter standalone test cases

    @pytest.mark.run(order=751)     
    def test_jupyter_version_jupyter_standalone(self, hosts, is_standalone, cluster_type):
        if not (is_standalone and cluster_type == 'jupyter'):
            pytest.skip("Cluster type is not jupyter standalone")

        test_host = hosts['login'][0]
        cmd = test_host.run("jupyter --version")
        assert cmd.rc == 0
        assert 'IPython' in cmd.stdout
        assert 'ipykernel' in cmd.stdout
        assert 'ipywidgets' in cmd.stdout
        assert 'jupyter_client' in cmd.stdout
        assert 'jupyter_core' in cmd.stdout
        assert 'jupyter_server' in cmd.stdout
        assert 'jupyterlab' in cmd.stdout
        assert 'nbclient' in cmd.stdout
        assert 'nbconvert' in cmd.stdout
        assert 'nbformat' in cmd.stdout
        assert 'notebook' in cmd.stdout
        assert 'qtconsole' in cmd.stdout
        assert 'traitlets' in cmd.stdout


# slurm standalone test cases


    @pytest.mark.run(order=752)      
    def test_slurm_installed_slurm_standalone(self, hosts, is_standalone, cluster_type): 
        if not (is_standalone and cluster_type == 'slurm'):
            pytest.skip("Cluster type is not slurm standalone")

        test_hosts = []
        test_hosts.extend(hosts['login'])
        test_hosts.extend(hosts['compute'])
        packages_list = ['flight-slurm.x86_64', 'flight-slurm-devel.x86_64', 'flight-slurm-example-configs.x86_64',
        'flight-slurm-libpmi.x86_64', 'flight-slurm-perlapi.x86_64', 'flight-slurm-slurmctld.x86_64',
        'flight-slurm-slurmd.x86_64', 'flight-slurm-torque.x86_64']
        for host in test_hosts:
            for package in packages_list:
                assert True == host.package(package).is_installed
    
    @pytest.mark.run(order=753)     
    def test_munge_installed_slurm_standalone(self, hosts, is_standalone, cluster_type): 
        if not (is_standalone and cluster_type == 'slurm'):
            pytest.skip("Cluster type is not slurm standalone")

        test_hosts = []
        test_hosts.extend(hosts['login'])
        test_hosts.extend(hosts['compute'])
        packages_list = ['munge.x86_64', 'munge-libs.x86_64']
        for host in test_hosts:
            for package in packages_list:
                assert True == host.package(package).is_installed

    @pytest.mark.run(order=754)     
    def test_slurmd_running_slurm_standalone(self, hosts, is_standalone, cluster_type): 
        if not (is_standalone and cluster_type == 'slurm'):
            pytest.skip("Cluster type is not slurm standalone")


        test_hosts = []
        test_hosts.extend(hosts['login'])
        
        for host in test_hosts:
            assert host.service('flight-slurmd').is_enabled
            assert host.service('flight-slurmd').is_running

    @pytest.mark.run(order=755)       
    def test_slurm_controller_running_login_slurm_standalone(self, hosts, is_standalone, cluster_type): 
        if not (is_standalone and cluster_type == 'slurm'):
            pytest.skip("Cluster type is not slurm standalone")

        test_hosts = []
        test_hosts.extend(hosts['login'])
        
        for host in test_hosts:
            assert host.service('flight-slurmctld').is_enabled
            assert host.service('flight-slurmctld').is_running


    @pytest.mark.run(order=756)       
    def test_node_identified_slurm_standalone(self, hosts, is_standalone, cluster_type): 
        if not (is_standalone and cluster_type == 'slurm'):
            pytest.skip("Cluster type is not slurm standalone")

        test_hosts = []
        test_hosts.extend(hosts['login'])
        
        for host in test_hosts:
            cmd = host.run("sinfo --Node | grep -v 'NODELIST' | wc -l")
            assert cmd.rc == 0
            assert int(cmd.stdout.strip()) == 1


    @pytest.mark.run(order=757)       
    def test_run_job_slurm_standalone(self, hosts, is_standalone, cluster_type): 
        if not (is_standalone and cluster_type == 'slurm'):
            pytest.skip("Cluster type is not slurm standalone")

        test_hosts = []
        test_hosts.extend(hosts['login'])
        
        for host in test_hosts:
            script_string ='#!/bin/bash -l\necho "Starting running on host $HOSTNAME"\nsleep 1\necho "Finished running - goodbye from $HOSTNAME"'
            cmd = host.run(f"echo -e '{script_string}' > testjob.sh")
            assert cmd.rc == 0

            cmd = host.run('sbatch testjob.sh')
            assert cmd.rc == 0
            assert 'Submitted batch job' in cmd.stdout

            cmd = host.run('squeue')
            assert cmd.rc == 0
            assert 'testjob' in cmd.stdout

            sleep(5)

            cmd = host.run('sbatch testjob.sh')
            assert cmd.rc == 0
            assert 'testjob' not in cmd.stdout

            cmd = host.run('rm testjob.sh')
            assert cmd.rc == 0
            
# k8s multinode test cases

    @pytest.mark.run(order=758)      
    def test_nodes_ready_k8s_multinode(self, hosts, is_standalone, cluster_type): 
        if not (not is_standalone and cluster_type == 'kubernetes'):
            pytest.skip("Cluster type is not k8s multinode")

        test_host = hosts['login'][0]
        cmd = test_host.run("flight hunter list --plain")
        no_of_nodes = len(cmd.stdout.splitlines())

        for i in range(5):
            cmd = test_host.run('kubectl get nodes')
            assert cmd.rc == 0
            ready_count = len(re.findall('Ready', cmd.stdout))
            if ready_count >= no_of_nodes:
                break
            sleep(60)
        assert ready_count == no_of_nodes

    @pytest.mark.run(order=759)      
    def test_launch_pod_k8s_multinode(self, hosts, is_standalone, cluster_type): 
        if not (not is_standalone and cluster_type == 'kubernetes'):
            pytest.skip("Cluster type is not k8s multinode")

        test_host = hosts['login'][0]
        cmd = test_host.run("flight silo file pull openflight:kubernetes/pod-launch-test.yaml")
        assert cmd.rc == 0
        
        cmd = test_host.run("kubectl apply -f pod-launch-test.yaml")
        assert cmd.rc == 0

        for i in range(5):
            cmd = test_host.run('kubectl get pods| grep ubuntu | grep Running | wc -l')
            assert cmd.rc == 0
            if int(cmd.stdout.strip()) > 0:
                break
            sleep(60)
        assert int(cmd.stdout.strip()) == 1


    @pytest.mark.run(order=760)      
    def test_launch_apache_k8s_multinode(self, hosts, is_standalone, cluster_type): 
        if not (not is_standalone and cluster_type == 'kubernetes'):
            pytest.skip("Cluster type is not k8s multinode")

        test_host = hosts['login'][0]
        cmd = test_host.run("flight silo file pull openflight:kubernetes/php-apache.yaml")
        assert cmd.rc == 0
        
        cmd = test_host.run("kubectl apply -f php-apache.yaml")
        assert cmd.rc == 0

        for i in range(5):
            cmd = test_host.run('kubectl get pods | grep php-apache | grep Running | wc -l')
            assert cmd.rc == 0
            if int(cmd.stdout.strip()) > 0:
                break
            sleep(60)
        assert int(cmd.stdout.strip()) == 1


    @pytest.mark.run(order=761)      
    def test_launch_busybox_k8s_multinode(self, hosts, is_standalone, cluster_type): 
        if not (not is_standalone and cluster_type == 'kubernetes'):
            pytest.skip("Cluster type is not k8s multinode")

        test_host = hosts['login'][0]
        cmd = test_host.run("flight silo file pull openflight:kubernetes/busybox-wget.yaml")
        assert cmd.rc == 0
        
        cmd = test_host.run("kubectl apply -f busybox-wget.yaml")
        assert cmd.rc == 0

        for i in range(5):
            cmd = test_host.run('kubectl get pods | grep busybox-wget | grep Completed | wc -l')
            assert cmd.rc == 0
            if int(cmd.stdout.strip()) > 0:
                break
            sleep(60)
        assert int(cmd.stdout.strip()) == 1


    @pytest.mark.run(order=762)      
    def test_check_busybox_logs_k8s_multinode(self, hosts, is_standalone, cluster_type): 
        if not (not is_standalone and cluster_type == 'kubernetes'):
            pytest.skip("Cluster type is not k8s multinode")
        
        test_host = hosts['login'][0]
        for i in range(5):
            cmd = test_host.run('kubectl get pods | grep busybox-wget | grep Completed | wc -l')
            assert cmd.rc == 0
            if int(cmd.stdout.strip()) > 0:
                break
            sleep(60)

        cmd = test_host.run("kubectl logs busybox-wget")
        assert cmd.rc == 0
        assert 'OK!' in cmd.stdout



# slurm mulitnode test cases

    @pytest.mark.run(order=763)      
    def test_slurm_installed_slurm_multinode(self, hosts, is_standalone, cluster_type): 
        if not (not is_standalone and cluster_type == 'slurm'):
            pytest.skip("Cluster type is not slurm multinode")

        test_hosts = []
        test_hosts.extend(hosts['login'])
        test_hosts.extend(hosts['compute'])
        packages_list = ['flight-slurm.x86_64', 'flight-slurm-devel.x86_64', 'flight-slurm-example-configs.x86_64',
        'flight-slurm-libpmi.x86_64', 'flight-slurm-perlapi.x86_64', 'flight-slurm-slurmctld.x86_64',
        'flight-slurm-slurmd.x86_64', 'flight-slurm-torque.x86_64']
        for host in test_hosts:
            for package in packages_list:
                assert True == host.package(package).is_installed
    
    @pytest.mark.run(order=764)     
    def test_munge_installed_slurm_multinode(self, hosts, is_standalone, cluster_type): 
        if not (not is_standalone and cluster_type == 'slurm'):
            pytest.skip("Cluster type is not slurm multinode")

        test_hosts = []
        test_hosts.extend(hosts['login'])
        test_hosts.extend(hosts['compute'])
        packages_list = ['munge.x86_64', 'munge-libs.x86_64']
        for host in test_hosts:
            for package in packages_list:
                assert True == host.package(package).is_installed

    @pytest.mark.run(order=765)     
    def test_slurmd_running_slurm_multinode(self, hosts, is_standalone, cluster_type): 
        if not (not is_standalone and cluster_type == 'slurm'):
            pytest.skip("Cluster type is not slurm multinode")


        test_hosts = []
        test_hosts.extend(hosts['compute'])
        
        for host in test_hosts:
            assert host.service('flight-slurmd').is_enabled
            assert host.service('flight-slurmd').is_running

    @pytest.mark.run(order=766)       
    def test_slurm_controller_running_login_slurm_multinode(self, hosts, is_standalone, cluster_type): 
        if not (not is_standalone and cluster_type == 'slurm'):
            pytest.skip("Cluster type is not slurm multinode")

        test_hosts = []
        test_hosts.extend(hosts['login'])
        
        for host in test_hosts:
            assert host.service('flight-slurmctld').is_enabled
            assert host.service('flight-slurmctld').is_running

    @pytest.mark.run(order=767)       
    def test_node_identified_slurm_multinode(self, hosts, is_standalone, cluster_type): 
        if not (not is_standalone and cluster_type == 'slurm'):
            pytest.skip("Cluster type is not slurm standalone")

        test_host = hosts['login'][0]
        cmd = test_host.run("flight hunter list --plain")
        no_of_nodes = len(cmd.stdout.splitlines())

        test_hosts = []
        test_hosts.extend(hosts['login'])
        
        for host in test_hosts:
            cmd = test_host.run('sinfo --Node | grep -v "NODELIST" | wc -l')
            assert cmd.rc == 0
            assert int(cmd.stdout.strip()) == no_of_nodes - len(hosts['login']) 


    @pytest.mark.run(order=768)       
    def test_run_job_slurm_multinode(self, hosts, is_standalone, cluster_type): 
        if not (not is_standalone and cluster_type == 'slurm'):
            pytest.skip("Cluster type is not slurm standalone")

        test_hosts = []
        test_hosts.extend(hosts['login'])
        
        for host in test_hosts:
            script_string ='#!/bin/bash -l\necho "Starting running on host $HOSTNAME"\nsleep 1\necho "Finished running - goodbye from $HOSTNAME"'
            cmd = host.run(f"echo -e '{script_string}' > testjob.sh")
            assert cmd.rc == 0

            cmd = host.run('sbatch testjob.sh')
            assert cmd.rc == 0
            assert 'Submitted batch job' in cmd.stdout

            cmd = host.run('squeue')
            assert cmd.rc == 0
            assert 'testjob' in cmd.stdout

            sleep(5)

            cmd = host.run('sbatch testjob.sh')
            assert cmd.rc == 0
            assert 'testjob' not in cmd.stdout

            cmd = host.run('rm testjob.sh')
            assert cmd.rc == 0


    @pytest.mark.run(order=769)       
    def test_run_multiple_job_slurm_multinode(self, hosts, is_standalone, cluster_type): 
        if not (not is_standalone and cluster_type == 'slurm'):
            pytest.skip("Cluster type is not slurm standalone")

        test_hosts = []
        test_hosts.extend(hosts['login'])
        
        for host in test_hosts:
            script_string ='#!/bin/bash -l\necho "Starting running on host $HOSTNAME"\nsleep 10\necho "Finished running - goodbye from $HOSTNAME"'
            cmd = host.run(f"echo -e '{script_string}' > testjob.sh")
            assert cmd.rc == 0
            for i in range(2):
                cmd = host.run('sbatch testjob.sh')
                assert cmd.rc == 0
                assert 'Submitted batch job' in cmd.stdout

            cmd = host.run('squeue -t RUNNING -h -o "%N" | sort -u')
            assert cmd.rc == 0
            assert 'node1' in cmd.stdout
            assert 'node2' in cmd.stdout
            assert 'testjob' not in cmd.stdout

            sleep(30)

            cmd = host.run('rm testjob.sh')
            assert cmd.rc == 0


    @pytest.mark.run(order=770)       
    def test_share_files_slurm_mutlinode(self, hosts, is_standalone, cluster_type): 
        if not (not is_standalone and cluster_type == 'slurm'):
            pytest.skip("Cluster type is not slurm standalone")

        file_name = 'shareable-file'
        test_host = hosts['login'][0]
        test_host.run(f"cd ~; touch {file_name}")

        test_hosts = []
        sleep(30)
        test_hosts.extend(hosts['compute'])
        for host in test_hosts:
            cmd = host.run('ls')
            assert cmd.rc == 0
            assert file_name in cmd.stdout
        
        test_host.run(f"cd ~; rm {file_name}")