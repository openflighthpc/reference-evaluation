
def pytest_addoption(parser):
    parser.addoption("--clusterinfo", action="store", default=None)