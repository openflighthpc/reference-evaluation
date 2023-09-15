import pytest
import os 
import re
from testinfra import get_host

@pytest.fixture
def hosts():
    local = get_host("local://", sudo=True)
    login = get_host("paramiko://flight@10.151.15.55", ssh_identity_file="/home/centos/v3/reference-evaluation/deployment_automated/keys/os_key")
    cnode1 = get_host("paramiko://flight@10.151.15.223", ssh_identity_file="/home/centos/v3/reference-evaluation/deployment_automated/keys/os_key")
    cnode2 = get_host("paramiko://flight@10.151.15.147", ssh_identity_file="/home/centos/v3/reference-evaluation/deployment_automated/keys/os_key")
    return {'local': [local], 'login': [login], 'compute': [cnode1, cnode2]}

class TestPreProfile():
    pass
    @pytest.mark.run(order=21)       
    def test_parse_nodes(self, hosts): 
        test_host = hosts['login'][0]
        cmd = test_host.run("flight hunter parse --auto --prefix node --start 00")
        assert cmd.rc == 0

    @pytest.mark.run(order=22)       
    def test_add_gender(self, hosts):
        test_host = hosts['login'][0]
        cmd = test_host.run("flight hunter list --plain")
        no_of_nodes = len(cmd.stdout.splitlines())
        if no_of_nodes > 1:
            cmd = test_host.run(f"flight hunter modify-groups --add login,all node00")
            assert cmd.rc == 0

            for i in range(1, no_of_nodes):
                cmd = test_host.run(f"flight hunter modify-groups --add compute,all node00")
                assert cmd.rc == 0
    
            cmd = test_host.run(f"flight parse list --plain | grep login")
            no_login_nodes = len(cmd.stdput.splitlines())
            assert no_login_nodes == 1

            cmd = test_host.run(f"flight parse list --plain | grep compute")
            no_login_nodes = len(cmd.stdput.splitlines())
            assert no_login_nodes == (no_of_nodes - no_login_nodes)
        
        else:
            cmd = test_host.run(f"flight hunter modify-groups --add standalone,all node00")
            assert cmd.rc == 0
        
        
            

