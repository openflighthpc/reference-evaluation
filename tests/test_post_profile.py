import pytest
import os 
import re
from testinfra import get_host
from time import sleep 
from utils import hosts, cluster_type, is_standalone

class TestPostProfile():

    @pytest.mark.run(order=601)       
    def test_password_set(self, hosts): 
        test_host = hosts['login'][0]
        cmd = test_host.run("sudo passwd flight --status")
        assert 'Password set' in cmd.stdout

    @pytest.mark.run(order=602)       
    def test_prepare_kde(self, hosts): 
        test_host = hosts['login'][0]
        cmd = test_host.run("sudo su - root -c 'flight desktop prepare kde'")
        assert 'Desktop type kde has been prepared' in cmd.stdout 

    @pytest.mark.run(order=603)       
    def test_prepare_xfce(self, hosts): 
        test_host = hosts['login'][0]
        cmd = test_host.run("sudo su - root -c 'flight desktop prepare xfce'")
        assert 'Desktop type xfce has been prepared' in  cmd.stdout 

    @pytest.mark.run(order=604)       
    def test_launch_gnome(self, hosts): 
        test_host = hosts['login'][0]
        cmd = test_host.run("unset LS_COLORS; export TERM=vt220; flight desktop start gnome")
        assert cmd.rc == 0 
        assert "A 'gnome' desktop session has been started." in  cmd.stdout 

        cmd = test_host.run("flight desktop list | grep 'gnome' | cut  -f1")
        session_id = cmd.stdout

        sleep(30)

        cmd = test_host.run(f"flight desktop kill {session_id}")
        assert "Terminating session" in cmd.stdout
        assert "has been terminated" in cmd.stdout



    @pytest.mark.run(order=605)       
    def test_launch_kde(self, hosts): 
        test_host = hosts['login'][0]
        cmd = test_host.run("unset LS_COLORS; export TERM=vt220; flight desktop start kde")
        assert cmd.rc == 0 
        assert "A 'kde' desktop session has been started." in  cmd.stdout 

        cmd = test_host.run("flight desktop list | grep 'kde' | cut  -f1")
        session_id = cmd.stdout

        sleep(30)

        cmd = test_host.run(f"flight desktop kill {session_id}")
        assert "Terminating session" in cmd.stdout
        assert "has been terminated" in cmd.stdout


    @pytest.mark.run(order=606)       
    def test_launch_xfce(self, hosts): 
        test_host = hosts['login'][0]
        cmd = test_host.run("unset LS_COLORS; export TERM=vt220; flight desktop start xfce")
        assert cmd.rc == 0 
        assert "A 'xfce' desktop session has been started." in  cmd.stdout 

        cmd = test_host.run("flight desktop list | grep 'xfce' | cut  -f1")
        session_id = cmd.stdout

        sleep(30)

        cmd = test_host.run(f"flight desktop kill {session_id}")
        assert "Terminating session" in cmd.stdout
        assert "has been terminated" in cmd.stdout

    @pytest.mark.run(order=607)       
    def test_vnc_port_accessible(self, hosts): 
        test_host = hosts['login'][0]
        local_host = hosts['local'][0]

        for i in range(3):
            cmd = test_host.run("unset LS_COLORS; export TERM=vt220; flight desktop start gnome")
            assert cmd.rc == 0 
            assert "A 'gnome' desktop session has been started." in  cmd.stdout 
        
        sleep(60)
        
        for i in range(3):
            login_addr = local_host.addr(test_host.backend.hostname)
            assert login_addr.port(int(f'590{i+1}')).is_reachable

        
        for i in range(3):
            cmd = test_host.run(f"flight desktop kill :{i+1}")
            assert "Terminating session" in cmd.stdout
            assert "has been terminated" in cmd.stdout

    @pytest.mark.run(order=608)       
    def test_install_conda(self, hosts): 
        test_host = hosts['login'][0]
        cmd = test_host.run("unset LS_COLORS; export TERM=vt220; flight env create conda")
        assert cmd.rc == 0 
        assert "Environment conda@default has been created" in  cmd.stdout 

        cmd = test_host.run("flight env activate conda && flight env deactivate")
        assert cmd.rc == 0 

        cmd = test_host.run("flight env purge --yes conda@default")
        assert cmd.rc == 0 
        

    @pytest.mark.run(order=609)       
    def test_install_easybuild(self, hosts): 
        test_host = hosts['login'][0]
        cmd = test_host.run("unset LS_COLORS; export TERM=vt220; flight env create easybuild")
        assert cmd.rc == 0 
        assert "Environment easybuild@default has been created" in  cmd.stdout 

        cmd = test_host.run("flight env activate easybuild && flight env deactivate")
        assert cmd.rc == 0 

        cmd = test_host.run("flight env purge --yes easybuild@default")
        assert cmd.rc == 0 


    @pytest.mark.run(order=610)       
    def test_install_modules(self, hosts): 
        test_host = hosts['login'][0]
        cmd = test_host.run("unset LS_COLORS; export TERM=vt220; flight env create modules")
        assert cmd.rc == 0 
        assert "Environment modules@default has been created" in  cmd.stdout 

        cmd = test_host.run("flight env activate modules && flight env deactivate")
        assert cmd.rc == 0 

        cmd = test_host.run("flight env purge --yes modules@default")
        assert cmd.rc == 0 

    @pytest.mark.run(order=611)       
    def test_install_singularity(self, hosts): 
        test_host = hosts['login'][0]
        cmd = test_host.run("unset LS_COLORS; export TERM=vt220; flight env create singularity")
        assert cmd.rc == 0 
        assert "Environment singularity@default has been created" in  cmd.stdout 

        cmd = test_host.run("flight env activate singularity && flight env deactivate")
        assert cmd.rc == 0 

        cmd = test_host.run("flight env purge --yes singularity@default")
        assert cmd.rc == 0 

    @pytest.mark.run(order=612)       
    def test_install_spack(self, hosts): 
        test_host = hosts['login'][0]
        cmd = test_host.run("unset LS_COLORS; export TERM=vt220; flight env create spack")
        assert cmd.rc == 0 
        assert "Environment spack@default has been created" in  cmd.stdout 

        cmd = test_host.run("flight env activate spack && flight env deactivate")
        assert cmd.rc == 0 

        cmd = test_host.run("flight env purge --yes spack@default")
        assert cmd.rc == 0 



    @pytest.mark.run(order=613)       
    def test_all_ports_80_443_accessible(self, hosts):
        test_hosts = []
        test_hosts.extend(hosts['login'])
        local_host = hosts['local'][0]

        for host in test_hosts:
            host_addr = local_host.addr(host.backend.hostname)
            assert host_addr.port(80).is_reachable
            assert host_addr.port(443).is_reachable
    
    @pytest.mark.run(order=614)       
    def test_login_flight_ssh(self, hosts, is_standalone):
        if is_standalone:
            pytest.skip("Cluster type is not multinode.")

        test_host = hosts['login'][0]
        compute_hosts = hosts['compute']
        for host in compute_hosts:
            cmd = test_host.run(f"ssh {host.backend.hostname} 'exit'")
            assert cmd.rc == 0

    
    # @pytest.mark.run(order=615)       
    # def test_set_clustername(self, hosts):
    #     test_host = hosts['login'][0]
    #     import os

    #     cmd = test_host.run('cat /opt/flight/cloudinit.in')
    #     text = cmd.stdout
    #     pattern = r'"cluster_name": "(.*?)"'
    #     match = re.search(pattern, text)
    #     cluster_name = None
    #     if match:
            # cluster_name = match.group(1)
        
        # cmd = test_host.run('. /etc/bashrc && echo $PS1')
        # print(cmd.stdout)
        # print(cmd.rc)
        # print(cmd.stderr)

        # cmd = test_host.run('cat ~/output')

        # my_var = os.getenv('PS1')
        # print(f"{my_var}")


        # print(cmd.stdout)
        # print(cmd.stderr)
        # print(cmd.rc)
        # assert cluster_name in cmd.stdout


    @pytest.mark.run(order=616)       
    def test_restart_cluster(self, hosts):
        local_host = hosts['local'][0]
        test_hosts = []
        test_hosts.extend(hosts['login'])
        test_hosts.extend(hosts['compute'])


        for host in test_hosts:
            cmd = host.run('sudo systemctl reboot')
            assert cmd.rc == 0 or cmd.rc == -1
        
        nodes_up = 0
        for i in range(5):
            node_reachable = 0
            sleep(60)
            for host in test_hosts:
                login_addr = local_host.addr(host.backend.hostname)
                if login_addr.port(22).is_reachable:
                    node_reachable += 1
            
            if node_reachable != len(test_hosts):
                continue
            
        nodes_up = 0
        for host in test_hosts:
            cmd = host.run('echo 0')
            assert cmd.rc == 0
            if cmd.rc == 0:
                nodes_up += 1

        assert len(test_hosts) == nodes_up
