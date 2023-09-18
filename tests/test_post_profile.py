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
    def test_install_conda(self, hosts): 
        test_host = hosts['login'][0]
        cmd = test_host.run("unset LS_COLORS; export TERM=vt220; flight env create conda")
        assert cmd.rc == 0 
        assert "Environment conda@default has been created" in  cmd.stdout 

        cmd = test_host.run("flight env activate conda && flight env deactivate")
        assert cmd.rc == 0 

        cmd = test_host.run("flight env purge --yes conda@default")
        assert cmd.rc == 0 
        

    @pytest.mark.run(order=608)       
    def test_install_easybuild(self, hosts): 
        test_host = hosts['login'][0]
        cmd = test_host.run("unset LS_COLORS; export TERM=vt220; flight env create easybuild")
        assert cmd.rc == 0 
        assert "Environment easybuild@default has been created" in  cmd.stdout 

        cmd = test_host.run("flight env activate easybuild && flight env deactivate")
        assert cmd.rc == 0 

        cmd = test_host.run("flight env purge --yes easybuild@default")
        assert cmd.rc == 0 


    @pytest.mark.run(order=609)       
    def test_install_modules(self, hosts): 
        test_host = hosts['login'][0]
        cmd = test_host.run("unset LS_COLORS; export TERM=vt220; flight env create modules")
        assert cmd.rc == 0 
        assert "Environment modules@default has been created" in  cmd.stdout 

        cmd = test_host.run("flight env activate modules && flight env deactivate")
        assert cmd.rc == 0 

        cmd = test_host.run("flight env purge --yes modules@default")
        assert cmd.rc == 0 

    @pytest.mark.run(order=610)       
    def test_install_singularity(self, hosts): 
        test_host = hosts['login'][0]
        cmd = test_host.run("unset LS_COLORS; export TERM=vt220; flight env create singularity")
        assert cmd.rc == 0 
        assert "Environment singularity@default has been created" in  cmd.stdout 

        cmd = test_host.run("flight env activate singularity && flight env deactivate")
        assert cmd.rc == 0 

        cmd = test_host.run("flight env purge --yes singularity@default")
        assert cmd.rc == 0 

    @pytest.mark.run(order=611)       
    def test_install_spack(self, hosts): 
        test_host = hosts['login'][0]
        cmd = test_host.run("unset LS_COLORS; export TERM=vt220; flight env create spack")
        assert cmd.rc == 0 
        assert "Environment spack@default has been created" in  cmd.stdout 

        cmd = test_host.run("flight env activate spack && flight env deactivate")
        assert cmd.rc == 0 

        cmd = test_host.run("flight env purge --yes spack@default")
        assert cmd.rc == 0 
