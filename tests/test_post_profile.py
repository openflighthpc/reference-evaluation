import pytest
import os 
import re
from testinfra import get_host
from time import sleep 

@pytest.fixture
def hosts():
    local = get_host("local://", sudo=True)
    login = get_host("paramiko://flight@10.151.15.55", ssh_identity_file="/home/centos/v3/reference-evaluation/deployment_automated/keys/os_key")
    cnode1 = get_host("paramiko://flight@10.151.15.223", ssh_identity_file="/home/centos/v3/reference-evaluation/deployment_automated/keys/os_key")
    cnode2 = get_host("paramiko://flight@10.151.15.147", ssh_identity_file="/home/centos/v3/reference-evaluation/deployment_automated/keys/os_key")
    return {'local': [local], 'login': [login], 'compute': [cnode1, cnode2]}

class TestPostProfile():

    @pytest.mark.run(order=70)       
    def test_password_set(self, hosts): 
        test_host = hosts['login'][0]
        cmd = test_host.run("sudo passwd flight --status")
        assert 'Password set' in cmd.stdout

    @pytest.mark.run(order=71)       
    def test_prepare_kde(self, hosts): 
        test_host = hosts['login'][0]
        cmd = test_host.run("sudo su - root -c 'flight desktop prepare kde'")
        assert 'Desktop type kde has been prepared' in cmd.stdout 

    @pytest.mark.run(order=72)       
    def test_prepare_xfce(self, hosts): 
        test_host = hosts['login'][0]
        cmd = test_host.run("sudo su - root -c 'flight desktop prepare xfce'")
        assert 'Desktop type xfce has been prepared' in  cmd.stdout 

    @pytest.mark.run(order=73)       
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



    @pytest.mark.run(order=74)       
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


    @pytest.mark.run(order=75)       
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

    @pytest.mark.run(order=76)       
    def test_install_conda(self, hosts): 
        test_host = hosts['login'][0]
        cmd = test_host.run("unset LS_COLORS; export TERM=vt220; flight env create conda")
        assert cmd.rc == 0 
        assert "Environment conda@default has been created" in  cmd.stdout 

        cmd = test_host.run("flight env activate conda && flight env deactivate")
        assert cmd.rc == 0 

        cmd = test_host.run("flight env purge --yes conda@default")
        assert cmd.rc == 0 
        

    @pytest.mark.run(order=77)       
    def test_install_easybuild(self, hosts): 
        test_host = hosts['login'][0]
        cmd = test_host.run("unset LS_COLORS; export TERM=vt220; flight env create easybuild")
        assert cmd.rc == 0 
        assert "Environment easybuild@default has been created" in  cmd.stdout 

        cmd = test_host.run("flight env activate easybuild && flight env deactivate")
        assert cmd.rc == 0 

        cmd = test_host.run("flight env purge --yes easybuild@default")
        assert cmd.rc == 0 


    @pytest.mark.run(order=78)       
    def test_install_modules(self, hosts): 
        test_host = hosts['login'][0]
        cmd = test_host.run("unset LS_COLORS; export TERM=vt220; flight env create modules")
        assert cmd.rc == 0 
        assert "Environment modules@default has been created" in  cmd.stdout 

        cmd = test_host.run("flight env activate modules && flight env deactivate")
        assert cmd.rc == 0 

        cmd = test_host.run("flight env purge --yes modules@default")
        assert cmd.rc == 0 

    @pytest.mark.run(order=79)       
    def test_install_singularity(self, hosts): 
        test_host = hosts['login'][0]
        cmd = test_host.run("unset LS_COLORS; export TERM=vt220; flight env create singularity")
        assert cmd.rc == 0 
        assert "Environment singularity@default has been created" in  cmd.stdout 

        cmd = test_host.run("flight env activate singularity && flight env deactivate")
        assert cmd.rc == 0 

        cmd = test_host.run("flight env purge --yes singularity@default")
        assert cmd.rc == 0 

    @pytest.mark.run(order=80)       
    def test_install_spack(self, hosts): 
        test_host = hosts['login'][0]
        cmd = test_host.run("unset LS_COLORS; export TERM=vt220; flight env create spack")
        assert cmd.rc == 0 
        assert "Environment spack@default has been created" in  cmd.stdout 

        cmd = test_host.run("flight env activate spack && flight env deactivate")
        assert cmd.rc == 0 

        cmd = test_host.run("flight env purge --yes spack@default")
        assert cmd.rc == 0 
