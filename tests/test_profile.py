import pytest
import os 
import re
from testinfra import get_host
from utils import hosts, cluster_type, is_standalone
from time import sleep

class TestProfile():

# jupyter standalone test cases

    @pytest.mark.run(order=451)   
    def test_configure_profile_standalone_jupyter(self, hosts, cluster_type, is_standalone): 
        if not (is_standalone and cluster_type == 'jupyter') :
            pytest.skip("Cluster type is not jupyter standalone")

        test_host = hosts['login'][0]
        cmd = test_host.run("flight profile configure --accept-defaults --answers '{\"cluster_type\": \"openflight-jupyter-standalone\", \"cluster_name\": \"my-cluster\", \"default_username\": \"flight\", \"default_password\": \"0penfl1ght\"}'")
        assert cmd.rc == 0
        cmd = test_host.run("flight profile configure --show")
        assert cmd.rc == 0
        assert 'Cluster type: Openflight Jupyter Standalone' in cmd.stdout
        assert 'Cluster name: my-cluster' in cmd.stdout
        assert 'Default user: flight' in cmd.stdout
        assert 'Set user password to: 0penfl1ght' in cmd.stdout

    @pytest.mark.run(order=452)     
    def test_apply_profile_standalone_jupyter(self, hosts, cluster_type, is_standalone): 
        if not (is_standalone and cluster_type == 'jupyter') :
            pytest.skip("Cluster type is not jupyter standalone")

        test_host = hosts['login'][0]
        cmd = test_host.run("flight profile apply node00 all-in-one")
        assert cmd.rc == 0

    @pytest.mark.run(order=453)      
    def test_complete_profile_standalone_jupyter(self, hosts, cluster_type, is_standalone): 
        if not (is_standalone and cluster_type == 'jupyter') :
            pytest.skip("Cluster type is not jupyter standalone")

        test_host = hosts['login'][0]
        for i in range(5):
            cmd = test_host.run("flight profile list")
            assert cmd.rc == 0
            complete_count = len(re.findall('complete', cmd.stdout))
            if complete_count > 0:
                break
            sleep(60)
        assert complete_count == 1



# slurm standalone test cases

    @pytest.mark.run(order=454)   
    def test_configure_profile_standalone_slurm(self, hosts, cluster_type, is_standalone): 
        if not (is_standalone and cluster_type == 'slurm'):
            pytest.skip("Cluster type is not slurm standalone")

        test_host = hosts['login'][0]
        cmd = test_host.run("flight profile configure --accept-defaults --answers '{\"cluster_type\": \"openflight-slurm-standalone\",  \"cluster_name\": \"my-cluster\",  \"default_username\": \"flight\",  \"default_password\": \"0penfl1ght\"}'")
        assert cmd.rc == 0
        cmd = test_host.run("flight profile configure --show")
        assert cmd.rc == 0
        assert 'Cluster type: Openflight Slurm Standalone' in cmd.stdout
        assert 'Cluster name: my-cluster' in cmd.stdout
        assert 'Default user: flight' in cmd.stdout
        assert 'Set user password to: 0penfl1ght' in cmd.stdout

    @pytest.mark.run(order=455)     
    def test_apply_profile_standalone_slurm(self, hosts, cluster_type, is_standalone): 
        if not (is_standalone and cluster_type == 'slurm') :
            pytest.skip("Cluster type is not slurm standalone")

        test_host = hosts['login'][0]
        cmd = test_host.run("flight profile apply node00 all-in-one")
        assert cmd.rc == 0

    @pytest.mark.run(order=456)   
    def test_complete_profile_standalone_slurm(self, hosts, cluster_type, is_standalone): 
        if not (is_standalone and cluster_type == 'slurm') :
            pytest.skip("Cluster type is not slurm standalone")

        test_host = hosts['login'][0]
        for i in range(5):
            cmd = test_host.run("flight profile list")
            assert cmd.rc == 0
            complete_count = len(re.findall('complete', cmd.stdout))
            if complete_count > 0:
                break
            sleep(60)
        assert complete_count == 1


# slurm multinode test cases


    @pytest.mark.run(order=457)      
    def test_configure_profile_multinode_slurm(self, hosts, cluster_type, is_standalone): 
        if not (not is_standalone and cluster_type == 'slurm'):
            pytest.skip("Cluster type is not slurm multinode")

        test_host = hosts['login'][0]
        cmd = test_host.run("flight profile configure --accept-defaults --answers '{\"cluster_type\": \"openflight-slurm-multinode\",  \"cluster_name\": \"my-cluster\", \"nfs_server\": \"node00\", \"slurm_server\": \"node00\", \"default_username\": \"flight\",  \"default_password\": \"0penfl1ght\"}'")
        assert cmd.rc == 0
        cmd = test_host.run("flight profile configure --show")
        assert cmd.rc == 0
        assert 'Cluster type: Openflight Slurm Multinode' in cmd.stdout
        assert 'Cluster name: my-cluster' in cmd.stdout
        assert 'Setup Multi User Environment with IPA? false' in cmd.stdout
        assert 'IPA domain: cluster.example.com' in cmd.stdout
        assert 'IPA server (short hostname or flight-hunter label): infra01' in cmd.stdout
        assert 'IPA Secure Admin Password: MySecurePassword' in cmd.stdout
        assert 'Local user login: flight' in cmd.stdout
        assert 'Set local user password to: 0penfl1ght' in cmd.stdout
        assert 'NFS server (hostname or flight-hunter label): node00' in cmd.stdout
        assert 'SLURM server (hostname or flight-hunter label): node00' in cmd.stdout
        
    @pytest.mark.run(order=458)   
    def test_apply_profile_multinode_slurm(self, hosts, cluster_type, is_standalone): 
        if not (not is_standalone and cluster_type == 'slurm') :
            pytest.skip("Cluster type is not slurm multinode")

        test_host = hosts['login'][0]
        cmd = test_host.run("flight hunter list --plain")
        no_of_nodes = len(cmd.stdout.splitlines())
        
        cmd = test_host.run(f"flight profile apply node00 login")
        assert cmd.rc == 0
        
        for i in range(1, no_of_nodes):
            cmd = test_host.run(f"flight profile apply node0{i} compute")
            assert cmd.rc == 0
        
    @pytest.mark.run(order=459)      
    def test_complete_compute_profile_multinode_slurm(self, hosts, cluster_type, is_standalone): 
        if not (not is_standalone and cluster_type == 'slurm') :
            pytest.skip("Cluster type is not slurm multinode")

        test_host = hosts['login'][0]
        cmd = test_host.run("flight hunter list --plain")
        assert cmd.rc == 0
        no_of_nodes = len(cmd.stdout.splitlines())
        
        for i in range(10):
            cmd = test_host.run("flight profile list")
            assert cmd.rc == 0
            complete_count = len(re.findall('complete', cmd.stdout))
            if complete_count >= no_of_nodes:
                break
            sleep(60)
        assert complete_count == no_of_nodes


# k8s multinode test cases

    @pytest.mark.run(order=460)      
    def test_configure_profile_multinode_kubernetes(self, hosts, cluster_type, is_standalone): 
        if not (not is_standalone and cluster_type == 'kubernetes') :
            pytest.skip("Cluster type is not kubernetes multinode")

        test_host = hosts['login'][0]
        cmd = test_host.run("flight profile configure --accept-defaults --answers '{\"cluster_type\": \"openflight-kubernetes-multinode\",  \"cluster_name\": \"my-cluster\",  \"default_username\": \"flight\",  \"default_password\": \"0penfl1ght\",  \"nfs_server\": \"node00\"}'")
        assert cmd.rc == 0
        cmd = test_host.run("flight profile configure --show")
        assert cmd.rc == 0
        assert 'Cluster type: Openflight Kubernetes Multinode' in cmd.stdout
        assert 'Cluster name: my-cluster' in cmd.stdout
        assert 'Default user: flight' in cmd.stdout
        assert 'NFS server (hostname or flight-hunter label): node00' in cmd.stdout
        assert 'Set user password to: 0penfl1ght' in cmd.stdout

    @pytest.mark.run(order=461)      
    def test_apply_profile_multinode_kubernetes(self, hosts, cluster_type, is_standalone): 
        if not (not is_standalone and cluster_type == 'kubernetes') :
            pytest.skip("Cluster type is not kubernetes multinode")

        test_host = hosts['login'][0]
        cmd = test_host.run("flight hunter list --plain")
        assert cmd.rc == 0
        no_of_nodes = len(cmd.stdout.splitlines())
        
        cmd = test_host.run(f"flight profile apply node00 master")
        assert cmd.rc == 0
        
        for i in range(1, no_of_nodes):
            cmd = test_host.run(f"flight profile apply node0{i} worker")
            assert cmd.rc == 0
        

    @pytest.mark.run(order=462)
    def test_complete_profile_multinode_kubernetes(self, hosts, cluster_type, is_standalone): 
        if not (not is_standalone and cluster_type == 'kubernetes') :
            pytest.skip("Cluster type is not kubernetes multinode")

        test_host = hosts['login'][0]
        cmd = test_host.run("flight hunter list --plain")
        assert cmd.rc == 0
        no_of_nodes = len(cmd.stdout.splitlines())
        
        for i in range(15):
            cmd = test_host.run("flight profile list")
            assert cmd.rc == 0
            complete_count = len(re.findall('complete', cmd.stdout))
            if complete_count >= no_of_nodes:
                break
            sleep(60)
        assert complete_count == no_of_nodes
