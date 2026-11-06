from ryu.base import app_manager
from ryu.controller import ofp_event
from ryu.controller.handler import CONFIG_DISPATCHER, MAIN_DISPATCHER
from ryu.controller.handler import set_ev_cls
from ryu.lib.packet import packet, ethernet
from ryu.ofproto import ofproto_v1_3

LEARN_TABLE = 0
FWD_TABLE = 1


class L2Switch(app_manager.RyuApp):
    OFP_VERSIONS = [ofproto_v1_3.OFP_VERSION]

    @set_ev_cls(ofp_event.EventOFPSwitchFeatures, CONFIG_DISPATCHER)
    def switch_features_handler(self, ev):
        datapath = ev.msg.datapath
        ofproto = datapath.ofproto
        parser = datapath.ofproto_parser
        print(f"Connection established to switch {datapath.id} with OFP version {ofproto.OFP_VERSION}")

        # Table 0, default: forward to controller AND table FWD_TABLE
        actions = [parser.OFPActionOutput(ofproto.OFPP_CONTROLLER, ofproto.OFPCML_NO_BUFFER)]
        self.add_flow(datapath, LEARN_TABLE, 0, parser.OFPMatch(), actions,
                      goto_table=FWD_TABLE)

        # Table 1, default: Flood to all ports
        actions = [parser.OFPActionOutput(ofproto.OFPP_FLOOD)]
        self.add_flow(datapath, FWD_TABLE, 0, parser.OFPMatch(), actions)

    def add_flow(self, datapath, table_id, priority, match, actions=None,
                 goto_table=None, idle_timeout=0):
        ofproto = datapath.ofproto
        parser = datapath.ofproto_parser

        inst = []
        if actions:
            inst.append(parser.OFPInstructionActions(ofproto.OFPIT_APPLY_ACTIONS, actions))
        if goto_table is not None:
            inst.append(parser.OFPInstructionGotoTable(goto_table))

        mod = parser.OFPFlowMod(datapath=datapath, table_id=table_id,
                                priority=priority, match=match,
                                instructions=inst, idle_timeout=idle_timeout)
        datapath.send_msg(mod)

    @set_ev_cls(ofp_event.EventOFPPacketIn, MAIN_DISPATCHER)
    def _packet_in_handler(self, ev):
        msg = ev.msg
        datapath = msg.datapath
        parser = datapath.ofproto_parser
        in_port = msg.match['in_port']

        pkt = packet.Packet(msg.data)
        eth = pkt.get_protocol(ethernet.ethernet)
        print(f"Got Packet_in from {datapath.id} on port {in_port}: {eth.src} -> {eth.dst}")

        # LEARN_TABLE: don't forward to controller if src is known
        match = parser.OFPMatch(in_port=in_port, eth_src=eth.src)
        self.add_flow(datapath, LEARN_TABLE, 1, match, goto_table=FWD_TABLE,
                      idle_timeout=20)

        # FWD_TABLE: forward packets to this dst addr. to the port
        match = parser.OFPMatch(eth_dst=eth.src)
        actions = [parser.OFPActionOutput(in_port)]
        self.add_flow(datapath, FWD_TABLE, 1, match, actions, idle_timeout=20)