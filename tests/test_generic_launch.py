import pytest
import os 
from testinfra import get_host

@pytest.fixture
def hosts():
    local = get_host("local://", sudo=True)
    login = get_host("paramiko://flight@10.151.15.55", ssh_identity_file="/home/centos/v3/reference-evaluation/deployment_automated/keys/os_key")
    cnode1 = get_host("paramiko://flight@10.151.15.223", ssh_identity_file="/home/centos/v3/reference-evaluation/deployment_automated/keys/os_key")
    cnode2 = get_host("paramiko://flight@10.151.15.147", ssh_identity_file="/home/centos/v3/reference-evaluation/deployment_automated/keys/os_key")
    return {'local': [local], 'login': [login], 'compute': [cnode1, cnode2]}

class TestGenericLaunch():

    @pytest.mark.run(order=1)
    def test_all_internet_is_reachable(self, hosts): 
        test_hosts = []
        test_hosts.extend(hosts['login'])
        test_hosts.extend(hosts['compute'])

        for host in test_hosts:
            google = host.addr("8.8.8.8")
            assert True == google.is_reachable
            print(google.is_reachable)
        
    @pytest.mark.run(order=2)       
    def test_all_dns_is_resolvable(self, hosts):
        test_hosts = []
        test_hosts.extend(hosts['login'])
        test_hosts.extend(hosts['compute'])
        for host in test_hosts:
            google = host.addr("google.com")
            assert True == google.is_resolvable

    @pytest.mark.run(order=3)        
    def test_all_selinux(self, hosts):
        test_hosts = []
        test_hosts.extend(hosts['login'])
        test_hosts.extend(hosts['compute'])

        for host in test_hosts:
                cmd = host.run("sestatus")
                assert 'disabled' in cmd.stdout

    @pytest.mark.run(order=4)       
    def test_all_firewalld(self, hosts):
        test_hosts = []
        test_hosts.extend(hosts['login'])
        test_hosts.extend(hosts['compute'])

        for host in test_hosts:
            firewalld = host.service("firewalld")
            assert firewalld.is_running

            firewalld = host.service("firewalld")
            assert firewalld.is_enabled

            cmd = host.run("ip link show")
            interfaces = cmd.stdout.splitlines()
            up_interfaces = [line.split(":")[1].strip() for line in interfaces if "state UP" in line]


            for interface in up_interfaces:
                cmd = host.run(f"sudo firewall-cmd --zone=trusted --query-interface={interface}")
                assert cmd.stdout.strip() == f"no"
            
            for interface in up_interfaces:
                cmd = host.run(f"sudo firewall-cmd --zone=public --query-interface={interface}")
                assert cmd.stdout.strip() == f"yes"

    @pytest.mark.run(order=5)             
    def test_all_yum_repo_list(self, hosts):
        test_hosts = []
        test_hosts.extend(hosts['login'])
        test_hosts.extend(hosts['compute'])

        for host in test_hosts:
            cmd = host.run("yum repolist")
            assert cmd.rc == 0
            assert "appstream" in cmd.stdout
            assert "baseos" in cmd.stdout  
            assert "epel" in cmd.stdout
            assert "extras" in cmd.stdout  
            assert "powertools" in cmd.stdout

    @pytest.mark.run(order=6)       
    def test_all_ports_22_8888(self, hosts):
        test_hosts = []
        test_hosts.extend(hosts['login'])
        test_hosts.extend(hosts['compute'])

        local_host = hosts['local']
        

        for host in test_hosts:
            assert True == host.socket("tcp://22").is_listening
            # assert True == host.socket("udp://22").is_listening
            # assert True == host.socket("tcp://8888").is_listening
            # assert True == host.socket("udp://8888").is_listening
            

    # @pytest.mark.run(after='test_second')       
    # def test_login_root_ssh(self, hosts):
    #     pass
    
