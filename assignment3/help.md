```sh
vagrant up
vagrant ssh

sudo mn --custom /vagrant/dumbbell_topo.py --topo dumbbell --controller=remote

ryu-manager /vagrant/mac-learning.py


sh ovs-ofctl dump-flows s1
sh ovs-ofctl dump-flows s2


```
