
import yaml
import pytest
from testinfra import get_host
from yaml.loader import SafeLoader

@pytest.fixture
def is_standalone(request):
    data = None
    path = request.config.getoption("--clusterinfo")
    with open(path) as f:
        data = yaml.load(f, Loader=SafeLoader)
        
    # standalone = False
    # if data['standalone'] == 'true':
    #     standalone = True
    # print(standalone)
    return data['standalone'] 

@pytest.fixture
def cluster_type(request):
    data = None
    path = request.config.getoption("--clusterinfo")
    with open(path) as f:
        data = yaml.load(f, Loader=SafeLoader)
    return data['cluster_type']

@pytest.fixture
def image_name(request):
    data = None
    path = request.config.getoption("--clusterinfo")
    with open(path) as f:
        data = yaml.load(f, Loader=SafeLoader)
    return data['image_name']

@pytest.fixture
def platform(request):
    data = None
    path = request.config.getoption("--clusterinfo")
    with open(path) as f:
        data = yaml.load(f, Loader=SafeLoader)
    return data['platform']

@pytest.fixture
def hosts(request):
    data = None
    path = request.config.getoption("--clusterinfo")
    with open(path) as f:
        data = yaml.load(f, Loader=SafeLoader)

    node_info = {}
    platform = data['platform']
    if platform == 'openstack':
        keypath = f"{data['keypath']}os_key"
    elif platform == 'azure':
        keypath = f"{data['keypath']}azure_key"
    elif platform == 'aws':
        keypath = f"{data['keypath']}aws_key"

    local = get_host("local://", sudo=True)
    node_info.update({'local': [local]})

    node_info.update({'login': []})
    for ip in data['login_public_ip']:
        login = get_host(f"paramiko://flight@{ip}", ssh_identity_file=keypath)
        node_info['login'].append(login)

    node_info.update({'compute': []})  
    for ip in data.get('compute_public_ip', []):
        compute = get_host(f"paramiko://flight@{ip}", ssh_identity_file=keypath)
        node_info['compute'].append(compute)
    return node_info