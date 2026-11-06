## Running under Apple silicon

Install VirtualBox and Vagrant.

Change `Vagrantfile` to use an image that supports arm64 such as `bento/ubuntu-22.04` and make sure to specify `config.vm.box.architecture ="arm64"`.

Vagrant automatically syncs your local project folder (the one you ran `vagrant up` from) into the VM. You can see the synced files by running `ls /vagrant`.To run a Python script for a custom topology run:

```sh
sudo mn --custom /vagrant/clos.py --topo mytopo
```

## Helpful commands for Vagrant

| Command                       |                                                                         |
| ----------------------------- | ----------------------------------------------------------------------- |
| `vagrant up`                  | Starts the VM according to the Vagrantfile                              |
| `vagrant ssh`                 | Starts ssh connection to vm                                             |
| `vagrant halt`                | Stops the running virtual machine. Like shutting down via the guest os. |
| `vagrant destroy -f`          | Deletes the running machine and all associated state                    |
| `vagrant box list`            | Lists all installed images                                              |
| `vagrant box remove box/name` | Removes the specified image                                             |

### Assignment 1 commands

```sh
sudo mn --topo single,3 --controller=none --switch ovsbr
```

```sh
sh ovs-appctl fdb/show s1
```

```sh
sudo mn --custom /vagrant/clos.py --topo mytopo
```
