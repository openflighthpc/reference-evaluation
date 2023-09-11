import pytest
import os 
import re
from testinfra import get_host

standalone = True
cluster_type = 'jupyter'

@pytest.fixture
def hosts():
    local = get_host("local://", sudo=True)
    login = get_host("paramiko://flight@10.151.15.55", ssh_identity_file="/home/centos/v3/reference-evaluation/deployment_automated/keys/os_key")
    cnode1 = get_host("paramiko://flight@10.151.15.223", ssh_identity_file="/home/centos/v3/reference-evaluation/deployment_automated/keys/os_key")
    cnode2 = get_host("paramiko://flight@10.151.15.147", ssh_identity_file="/home/centos/v3/reference-evaluation/deployment_automated/keys/os_key")
    return {'local': [local], 'login': [login], 'compute': [cnode1, cnode2]}

class TestProfile():

    @pytest.mark.run(order=22)   
    @pytest.mark.skipif(not standalone or cluster_type != 'jupyter',
                    reason="cluster type is not jupyter standalone")    
    def test_configure_profile_standalone_jupyter(self, hosts): 
        test_host = hosts['login'][0]
        cmd = test_host.run("flight profile configure --accept-defaults --answers '{\"cluster_type\": \"openflight-jupyter-standalone\", \"cluster_name\": \"my-cluster\", \"default_username\": \"flight\", \"default_password\": \"0penfl1ght\"}'")
        assert cmd.rc == 0
        cmd = test_host.run("flight profile configure --show")
        assert cmd.rc == 0
        assert 'Cluster type: Openflight Jupyter Standalone' in cmd.stdout
        assert 'Cluster name: my-cluster' in cmd.stdout
        assert 'Default user: flight' in cmd.stdout
        assert 'Set user password to: 0penfl1ght' in cmd.stdout

    @pytest.mark.run(order=23)   
    @pytest.mark.skipif(not standalone or cluster_type != 'jupyter',
                    reason="cluster type is not jupyter standalone")    
    def test_apply_profile_standalone_jupyter(self, hosts): 
        test_host = hosts['login'][0]
        cmd = test_host.run("flight profile apply node00 all-in-one")
        assert cmd.rc == 0

    @pytest.mark.run(order=24)   
    @pytest.mark.skipif(not standalone or cluster_type != 'jupyter',
                    reason="cluster type is not jupyter standalone")    
    def test_complete_profile_standalone_jupyter(self, hosts): 
        test_host = hosts['login'][0]
        cmd = test_host.run("flight profile list")
        assert cmd.rc == 0
        for i in range(5):
            complete_count = len(re.findall('complete', cmd.stdout))
            if complete_count > 0:
                break
            sleep(60)
        assert complete_count == 1






    @pytest.mark.run(order=25)   
    @pytest.mark.skipif(not standalone or cluster_type != 'slurm',
                    reason="cluster type is not slurm standalone")    
    def test_configure_profile_standalone_slurm(self, hosts): 
        test_host = hosts['login'][0]
        cmd = test_host.run("flight profile configure --accept-defaults --answers '{\"cluster_type\": \"openflight-slurm-standalone\",  \"cluster_name\": \"my-cluster\",  \"default_username\": \"flight\",  \"default_password\": \"0penfl1ght\"}'")
        assert cmd.rc == 0
        cmd = test_host.run("flight profile configure --show")
        assert cmd.rc == 0
        assert 'Cluster type: Openflight Slurm Standalone' in cmd.stdout
        assert 'Cluster name: my-cluster' in cmd.stdout
        assert 'Default user: flight' in cmd.stdout
        assert 'Set user password to: 0penfl1ght' in cmd.stdout

    @pytest.mark.run(order=26)   
    @pytest.mark.skipif(not standalone or cluster_type != 'slurm',
                    reason="cluster type is not slurm standalone")    
    def test_apply_profile_standalone_slurm(self, hosts): 
        test_host = hosts['login'][0]
        cmd = test_host.run("flight profile apply node00 all-in-one")
        assert cmd.rc == 0

    @pytest.mark.run(order=27)   
    @pytest.mark.skipif(not standalone or cluster_type != 'slurm',
                    reason="cluster type is not slurm standalone")    
    def test_complete_profile_standalone_slurm(self, hosts): 
        test_host = hosts['login'][0]
        cmd = test_host.run("flight profile list")
        assert cmd.rc == 0
        for i in range(5):
            complete_count = len(re.findall('complete', cmd.stdout))
            if complete_count > 0:
                break
            sleep(60)
        assert complete_count == 1






    @pytest.mark.run(order=28)   
    @pytest.mark.skipif(standalone or cluster_type != 'slurm',
                    reason="cluster type is not slurm multinode")    
    def test_configure_profile_multinode_slurm(self, hosts): 
        test_host = hosts['login'][0]
        cmd = test_host.run("flight profile configure --accept-defaults --answers '{\"cluster_type\": \"openflight-slurm-multinode\",  \"cluster_name\": \"my-cluster\", \"nfs_server\": \"node00\", \"slurm_server\": \"node00\", \"default_username\": \"flight\",  \"default_password\": \"0penfl1ght\"}'")
        assert cmd.rc == 0
        cmd = test_host.run("flight profile configure --show")
        assert cmd.rc == 0
        assert 'Cluster type: Openflight Slurm Multinode' in cmd.stdout
        assert 'Cluster name: my-cluster' in cmd.stdout
        assert 'Default user: flight' in cmd.stdout
        assert 'Set user password to: 0penfl1ght' in cmd.stdout
        assert 'NFS server (hostname or flight-hunter label): node00' in cmd.stdout
        assert 'SLURM server (hostname or flight-hunter label): node00' in cmd.stdout
        
    @pytest.mark.run(order=29)   
    @pytest.mark.skipif(standalone or cluster_type != 'slurm',
                    reason="cluster type is not slurm multinode")    
    def test_apply_profile_multinode_slurm(self, hosts): 
        test_host = hosts['login'][0]
        cmd = test_host.run("flight hunter list --plain")
        no_of_nodes = len(cmd.stdout.splitlines())
        
        cmd = test_host.run(f"flight profile apply node00 login")
        assert cmd.rc == 0
        
        for i in range(1, no_of_nodes):
            cmd = test_host.run(f"flight profile apply node0{i} compute")
            assert cmd.rc == 0
        
    @pytest.mark.run(order=30)   
    @pytest.mark.skipif(standalone or cluster_type != 'slurm',
                    reason="cluster type is not slurm multinode")    
    def test_complete_compute_profile_multinode_slurm(self, hosts): 
        test_host = hosts['login'][0]
        cmd = test_host.run("flight hunter list --plain")
        assert cmd.rc == 0
        no_of_nodes = len(cmd.stdout.splitlines())
        
        cmd = test_host.run("flight profile list")
        assert cmd.rc == 0
        for i in range(10):
            complete_count = len(re.findall('complete', cmd.stdout))
            if complete_count > 0:
                break
            sleep(60)
        assert complete_count == no_of_nodes





    @pytest.mark.run(order=31)   
    @pytest.mark.skipif(standalone or cluster_type != 'kubernetes',
                    reason="cluster type is not kubernetes multinode")    
    def test_configure_profile_multinode_kubernetes(self, hosts): 
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

    @pytest.mark.run(order=32)   
    @pytest.mark.skipif(standalone or cluster_type != 'kubernetes',
                    reason="cluster type is not kubernetes multinode")    
    def test_apply_profile_multinode_kubernetes(self, hosts): 
        test_host = hosts['login'][0]
        cmd = test_host.run("flight hunter list --plain")
        assert cmd.rc == 0
        no_of_nodes = len(cmd.stdout.splitlines())
        
        cmd = test_host.run(f"flight profile apply node00 master")
        assert cmd.rc == 0
        
        for i in range(1, no_of_nodes):
            cmd = test_host.run(f"flight profile apply node0{i} worker")
            assert cmd.rc == 0
        

    @pytest.mark.run(order=33)   
    @pytest.mark.skipif(standalone or cluster_type != 'kubernetes',
                    reason="cluster type is not kubernetes multinode")    
    def test_complete_profile_multinode_kubernetes(self, hosts): 
        test_host = hosts['login'][0]
        cmd = test_host.run("flight hunter list --plain")
        assert cmd.rc == 0
        no_of_nodes = len(cmd.stdout.splitlines())
        
        cmd = test_host.run("flight profile list")
        assert cmd.rc == 0
        for i in range(10):
            complete_count = len(re.findall('complete', cmd.stdout))
            if complete_count > 0:
                break
            sleep(60)
        assert complete_count == no_of_nodes
