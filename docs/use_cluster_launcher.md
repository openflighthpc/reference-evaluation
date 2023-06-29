# How to use the Cluster Launcher

## Running it
Assuming that you are in the git repository's top level directory, change into the `deployment_automated` directory and run `ruby config.rb`
```
cd deployment_automated
ruby config.rb
```

## Tty-prompt Interface Questions

After running `config.rb` you will be presented with a series of questions for setting up a cluster.

1. `Name of cluster?` - What should the name of the cluster be?
2. `Standalone cluster? (y/N)` - Is this going to be a standalone cluster? This can only be answered as a yes or no, and by default is no.
3. `Launch on what platform?` - A dropdown menu of platform options.
4. `What testing?` - A dropdown menu of testing options. `basic` means only basic tests. `full` means all tests. `none` means no tests. More information about tests can be found on the testing doc page.
5. `What instance size login node?` - A dropdown menu of instance sizes. These correspond to cloud platform instance sizes/
6. `What volume size login node? (GB) (20)` - What disk size in gigabytes, should the login node be?
7. `Share Pub Key?` - Should the Flight Solo user data option to share a public key between login nodes and compute nodes be used? This can only be answered as a yes or no.
8. `Auto Parse match regex` - Enter a regular expression to be passed as Flight Solo user data.
9. `How many compute nodes? (2)` - If launching a multinode cluster, the number of compute nodes can be changed

