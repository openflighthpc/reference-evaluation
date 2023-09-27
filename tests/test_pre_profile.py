import pytest
import os 
import re
from testinfra import get_host
from utils import hosts, cluster_type, is_standalone

class TestPreProfile():
    pass
    @pytest.mark.run(order=301)       
    def test_parse_nodes(self, hosts): 
        test_host = hosts['login'][0]
        cmd = test_host.run("flight hunter parse --auto --prefix node --start 00")
        assert cmd.rc == 0

    @pytest.mark.run(order=302)       
    def test_nodes_in_parsed(self, hosts):
        all_hosts = []
        all_hosts.extend(hosts['login'])
        all_hosts.extend(hosts['compute'])
        cluster_node_ips = []
        for host in all_hosts:
            interface = host.interface.default().name
            cluster_node_ips.extend([host.interface(interface).addresses[0]])

        test_hosts = []
        test_hosts.extend(hosts['login'])

        for host in test_hosts:
            cmd = host.run("flight hunter list --plain")
            assert cmd.rc == 0

            for node_ip in cluster_node_ips:
                assert node_ip in cmd.stdout
            


    @pytest.mark.run(order=303)       
    def test_add_gender(self, hosts):
        test_host = hosts['login'][0]
        cmd = test_host.run("flight hunter list --plain")
        no_of_nodes = len(cmd.stdout.splitlines())
        if no_of_nodes > 1:
            cmd = test_host.run(f"flight hunter modify-groups --add login,all node00")
            assert cmd.rc == 0

            for i in range(1, no_of_nodes):
                cmd = test_host.run(f"flight hunter modify-groups --add compute,all node0{i}")
                assert cmd.rc == 0
    
            cmd = test_host.run(f"flight hunter list --plain | grep login")
            no_login_nodes = len(cmd.stdout.splitlines())
            assert no_login_nodes == 1

            cmd = test_host.run(f"flight hunter list --plain | grep compute")
            no_compute_nodes = len(cmd.stdout.splitlines())
            assert no_compute_nodes == no_of_nodes - no_login_nodes
        
        else:
            cmd = test_host.run(f"flight hunter modify-groups --add standalone,all node00")
            assert cmd.rc == 0
        
        
            

