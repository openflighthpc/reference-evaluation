import pytest
import os 
import re
from testinfra import get_host
from time import sleep
from utils import hosts, cluster_type, is_standalone, platform, image_name

class TestGenericLaunch():

    @pytest.mark.run(order=0)
    def test_image_version(self, hosts, platform, image_name): 
        local_host = hosts['local'][0]
        test_host = hosts['login'][0]
        pattern = r'(\d{4}\.\d)'
        cmd = test_host.run("sudo su - root -c 'cat /etc/solo-release'")
        match = re.search(pattern, cmd.stdout)
        if match:
            machine_image_version = match.group(1)
        

        config_image_name = image_name
        if platform == 'aws':
            cmd = local_host.run(f"aws ec2 describe-images --image-ids {config_image_name} --query 'Images[].Name' --output text")
            config_image_name = cmd.stdout()
        
        match = re.search(pattern, cmd.stdout)
        if match:
            config_image_version = match.group(1)

        assert config_image_version == machine_image_version


    @pytest.mark.run(order=1)
    def test_all_internet_is_reachable(self, hosts): 
        test_hosts = []
        test_hosts.extend(hosts['login'])
        test_hosts.extend(hosts['compute'])
        print(hosts['login'])
        print(hosts['compute'])

        for host in test_hosts:
            google = host.addr("8.8.8.8")
            assert True == google.is_reachable
        
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

        local_host = hosts['local'][0]
        sleep(90)
        
        for host in test_hosts:
            host_addr = local_host.addr(host.backend.hostname)
            assert host_addr.port(22).is_reachable
            assert host_addr.port(8888).is_reachable
            

    @pytest.mark.run(order=7)       
    def test_login_root_ssh(self, hosts, is_standalone):
        if is_standalone:
            pytest.skip("Cluster type is not multinode.")

        test_host = hosts['login'][0]
        compute_hosts = hosts['compute']
        for host in compute_hosts:
            cmd = test_host.run(f"sudo su - root -c 'ssh {host.backend.hostname} exit'")
            assert cmd.rc == 0
    
