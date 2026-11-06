Modified Vagrantfile from assignment 1, removes unneeded dependencies and adds MPI libraries.

Script is automatically shared into the VM

```sh
vagrant up
vagrant ssh
cd /vagrant
mpiexec -n 2 python3 mpi-benchmark.py -h
mpiexec -n 2 python3 mpi-benchmark.py allreduce
mpiexec -n 2 python3 mpi-benchmark.py bcast
mpiexec -n 2 python3 mpi-benchmark.py allgather


```
