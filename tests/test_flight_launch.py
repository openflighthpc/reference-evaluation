import pytest
import os 
import re
from testinfra import get_host
from utils import hosts, cluster_type, is_standalone

class TestFlightLaunch():

    @pytest.mark.run(order=151)       
    def test_flight_packages(self, hosts): 
        test_hosts = []
        test_hosts.extend(hosts['login'])
        test_hosts.extend(hosts['compute'])
        packages_list = ['flight-certbot.x86_64', 'flight-console-api.x86_64', 
            'flight-console-webapp.x86_64', 'flight-desktop.x86_64', 'flight-desktop-restapi.x86_64',
            'flight-desktop-types.noarch', 'flight-desktop-webapp.x86_64', 'flight-direct-flight-starter-banner.noarch',
            'flight-env.x86_64', 'flight-env-types.noarch', 'flight-file-manager-api.x86_64', 'flight-file-manager-webapp.x86_64',
            'flight-gather.x86_64', 'flight-headnode-landing-page.x86_64', 'flight-howto.x86_64', 'flight-hunter.x86_64',
            'flight-job.x86_64', 'flight-job-script-api.x86_64', 'flight-job-script-webapp.x86_64', 'flight-jq.x86_64',
            'flight-login-api.x86_64', 'flight-nodejs.x86_64', 'flight-pdsh.x86_64', 'flight-plugin-manual-cron.noarch', 'flight-plugin-system-starter.noarch',
            'flight-plugin-system-systemd-service.noarch', 'flight-profile.x86_64', 'flight-profile-api.x86_64', 'flight-profile-types.noarch',
            'flight-python.x86_64', 'flight-runway.x86_64', 'flight-service.x86_64', 'flight-silo.x86_64', 'flight-slurm.x86_64', 'flight-slurm-devel.x86_64',
            'flight-slurm-example-configs.x86_64', 'flight-slurm-libpmi.x86_64', 'flight-slurm-perlapi.x86_64', 'flight-slurm-slurmctld.x86_64',
            'flight-slurm-slurmd.x86_64', 'flight-slurm-torque.x86_64', 'flight-starter.noarch', 'flight-user-suite.noarch', 'flight-web-suite.noarch',
            'flight-web-suite-utils.x86_64', 'flight-websockify.x86_64', 'flight-www.x86_64']
        for host in test_hosts:
            for package in packages_list:
                assert True == host.package(package).is_installed
    
    @pytest.mark.run(order=152)       
    def test_gnome_available(self, hosts): 
        test_hosts = []
        test_hosts.extend(hosts['login'])
        test_hosts.extend(hosts['compute'])
        for host in test_hosts:
            cmd = host.run('flight desktop avail')   
            assert cmd.rc == 0 
            assert 'gnome' in cmd.stdout
            assert 'Verified' in cmd.stdout
    
    @pytest.mark.run(order=153)       
    def test_hunter_cmd_execution(self, hosts): 
        test_hosts = []
        test_hosts.extend(hosts['login'])
        test_hosts.extend(hosts['compute'])
        for host in test_hosts:
            cmd = host.run('flight hunter --version')
            assert cmd.rc == 0
            assert 'flight hunter' in cmd.stdout
       
    @pytest.mark.run(order=154)       
    def test_websuite_cmd_execution(self, hosts): 
        test_hosts = []
        test_hosts.extend(hosts['login'])
        test_hosts.extend(hosts['compute'])
        for host in test_hosts:
            cmd = host.run('flight profile --version')
            assert cmd.rc == 0
            assert 'profile' in cmd.stdout
    
    @pytest.mark.run(order=155)       
    def test_env_cmd_execution(self, hosts): 
        test_hosts = []
        test_hosts.extend(hosts['login'])
        test_hosts.extend(hosts['compute'])
        for host in test_hosts:
            cmd = host.run('flight env --version')
            assert cmd.rc == 0
            assert 'flight env' in cmd.stdout

    @pytest.mark.run(order=156)       
    def test_silo_cmd_execution(self, hosts): 
        test_hosts = []
        test_hosts.extend(hosts['login'])
        test_hosts.extend(hosts['compute'])
        for host in test_hosts:
            cmd = host.run('flight silo --version')
            assert cmd.rc == 0
            assert 'flight silo' in cmd.stdout

    @pytest.mark.run(order=157)       
    def test_pdsh_cmd_execution(self, hosts): 
        test_hosts = []
        test_hosts.extend(hosts['login'])
        test_hosts.extend(hosts['compute'])
        for host in test_hosts:
            cmd = host.run('pdsh -V')
            assert cmd.rc == 0
            assert 'pdsh-' in cmd.stdout
    
    @pytest.mark.run(order=158)       
    def test_flight_gather_collect(self, hosts):
        test_hosts = []
        test_hosts.extend(hosts['login'])
        test_hosts.extend(hosts['compute'])

        for host in test_hosts:
            cmd = host.run("flight gather collect")
            assert cmd.rc == 0

    @pytest.mark.run(order=159)       
    def test_flight_gather_show(self, hosts):
        test_hosts = []
        test_hosts.extend(hosts['login'])
        test_hosts.extend(hosts['compute'])
        for host in test_hosts:
            cmd1 = host.run("flight gather show | grep -v '  '")
            cmd2 = host.run("cat  /opt/flight/opt/gather/var/data.yml | grep -v '  '")

            assert cmd1.rc == 0
            assert cmd2.rc == 0
            assert cmd1.stdout == cmd2.stdout
            assert re.search(r':primaryGroup:', cmd1.stdout)
            assert re.search(r':secondaryGroups:', cmd1.stdout)
            assert re.search(r':model: .*', cmd1.stdout)
            assert re.search(r':bios: .*', cmd1.stdout)
            assert re.search(r':serial: .*', cmd1.stdout)
            assert re.search(r':ram: .*', cmd1.stdout)
            assert re.search(r':network:', cmd1.stdout)
            assert re.search(r':sysuuid:', cmd1.stdout)
            assert re.search(r':bootif:', cmd1.stdout)
            assert re.search(r':disks:', cmd1.stdout)
            assert re.search(r':gpus:', cmd1.stdout)
            assert re.search(r':platform: .*', cmd1.stdout)

    @pytest.mark.run(order=160)       
    def test_silo_type_repo_openflight(self, hosts):
        test_hosts = []
        test_hosts.extend(hosts['login'])
        test_hosts.extend(hosts['compute'])
        for host in test_hosts:
            cmd = host.run("flight silo repo list 2>/dev/null | tr -d '\n' | grep -e 'openflight.*true' 2>&1>/dev/null; echo $?")
            assert cmd.rc == 0
            assert cmd.stdout.strip() == '0'
            
    @pytest.mark.run(order=161)       
    def test_silo_type_repo_aws(self, hosts):
        test_hosts = []
        test_hosts.extend(hosts['login'])
        test_hosts.extend(hosts['compute'])
        for host in test_hosts:
            cmd = host.run("flight silo repo list 2>/dev/null | tr -d '\n' | grep -e 'aws.*true' 2>&1>/dev/null; echo $?")
            assert cmd.rc == 0
            assert cmd.stdout.strip() == '0'
    
    @pytest.mark.run(order=162)       
    def test_silo_pull(self, hosts):
        test_hosts = []
        test_hosts.extend(hosts['login'])
        test_hosts.extend(hosts['compute'])

        for host in test_hosts:
            cmd = host.run("flight silo file pull openflight:openfoam/cavity-example.sh")
            assert cmd.rc == 0
            assert host.file("/home/flight/cavity-example.sh").exists
            host.run("rm /home/flight/cavity-example.sh")

    @pytest.mark.run(order=163)       
    def test_nodes_in_buffer(self, hosts):
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
            cmd = host.run("flight hunter list --plain --buffer")
            assert cmd.rc == 0

            for node_ip in cluster_node_ips:
                assert node_ip in cmd.stdout
            
    @pytest.mark.run(order=164)       
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
            cmd = host.run("flight hunter list --plain --buffer")
            assert cmd.rc == 0

            for node_ip in cluster_node_ips:
                assert node_ip in cmd.stdout
            
