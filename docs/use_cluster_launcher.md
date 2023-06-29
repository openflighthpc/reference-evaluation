## Running it



## Tty-prompt Interface Questions

The ruby tty-prompt interface is the easiest way to start up a Flight Solo cluster on up to 3 cloud platforms. 

### Get started
Assuming that you are in the git repository's top level directory, change into the `deployment_automated` directory and run `ruby config.rb`
e.g.
```
cd deployment_automated
ruby config.rb
```

### Answer cluster configuration questions

After running `config.rb` you will be presented with a series of questions for setting up a cluster.

1. `Name of cluster?` - What should the name of the cluster be?
2. `Standalone cluster? (y/N)` - Is this going to be a standalone cluster? This can only be answered as a yes or no, and by default is no.
3. `Launch on what platform?` - A dropdown menu of platform options.
4. `What testing?` - A dropdown menu of testing options. `basic` means only basic tests. `full` means all tests. `none` means no tests. More information about tests can be found on the testing doc page.
5. `What instance size login node?` - A dropdown menu of instance sizes. These correspond to cloud platform instance sizes.
6. `What volume size login node? (GB) (20)` - What disk size in gigabytes, should the login node be?
7. `Share Pub Key?` - Should the Flight Solo user data option to share a public key between login nodes and compute nodes be used? This can only be answered as a yes or no.
8. `Auto Parse match regex` - Enter a regular expression to be passed as Flight Solo user data.
9. `How many compute nodes? (2)` - If launching a multinode cluster, the number of compute nodes can be changed
10. `What instance size compute nodes?` - A drop down menu of instance sizes for the compute nodes in the cluster. These correspond to cloud platform sizes.
11. `What volume size compute nodes (GB) (20)` - What disk size in gigabytes, should each of the compute nodes be?
12. `Delete on success?` - If testing, if all tests pass then the cluster will be deleted on "yes". On "no" then nothing will be deleted regardless of testing outcome.
After finishing the questions, the cluster will start launching. When it is done, it will print out the ip addresses of all nodes in the cluster.
Note:
- A lot of information from commands being run is sent to a log file instead of displayed, this is kept in `deployment_automated/log/stdout`
- Any tests run will have an output file stored on the instance, but also in `deployment_automated/log/tests`
- The template used to launch an instance will be stored in `deployment_automated/log/templates`


