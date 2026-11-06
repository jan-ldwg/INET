"""Clos topology example
Generates 3 layer clos topology of degree k
Adding the 'topos' dict with a key/value pair to generate our newly defined
topology enables one to pass in '--topo=mytopo' from the command line.
"""

from mininet.topo import Topo

class MyTopo( Topo ):
    "Simple topology example."

    def build( self ):
        "Create custom topo."

        k=4

        # Add bottom switches
        btsw=[]
        for i in range(k):
            sw=[]
            for j in range(k//2):
                sw.append(self.addSwitch(f"bsw{i}_{j}"))
            btsw.append(sw)

        # Add top switches
        tpsw=[]
        for i in range(k):
            sw=[]
            for j in range(k//2):
                sw.append(self.addSwitch(f"tsw{i}_{j}"))
            tpsw.append(sw)

        # Add backbone (spine) switches
        spsw=[]
        for i in range(k//2):
            sw=[]
            for j in range(int(k/2)):
                sw.append(self.addSwitch(f"ssw{i}_{j}"))
            spsw.append(sw)

        # Add hosts
        hosts=[]
        for i in range(k):  #every pod
            podH=[]
            for j in range(k//2):   #every bottom switch of that pod
                setH=[]
                for l in range(k//2):   #size of host set for that bottomswitch
                    setH.append(self.addHost(f"host{i}_{j}_{l}"))
                podH.append(setH)
            hosts.append(podH)


        # Add links between bottom switches and hosts
        for i in range(k):
            for j in range(k//2):
              for l in range(k//2):
                    self.addLink(hosts[i][j][l], btsw[i][j])

        # Add links between top and bottom switches
        for i in range(k):
            for j in range(k//2):
                for l in range(k//2):
                    self.addLink(btsw[i][j],tpsw[i][l])

        # Add links between top and spine switches
        for i in range(k):
            for j in range(k//2):
                for l in range(k//2):
                    self.addLink(tpsw[i][j], spsw[l][j])

topos = { 'mytopo': ( lambda: MyTopo() ) }