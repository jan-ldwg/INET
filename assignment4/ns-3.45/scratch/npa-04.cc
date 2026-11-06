#include "ns3/applications-module.h"
#include "ns3/core-module.h"
#include "ns3/flow-monitor-module.h"
#include "ns3/internet-module.h"
#include "ns3/network-module.h"
#include "ns3/ping-helper.h"
#include "ns3/point-to-point-module.h"
#include "ns3/traffic-control-module.h"

#include <string>

using namespace ns3;

void TxCallback(Ptr<OutputStreamWrapper> stream,
    Ptr <const Packet> packet){
        *stream->GetStream() << Simulator::Now().GetSeconds() <<
        " " << packet->GetSize() <<std::endl;
    }

int main(int argc, char* argv[])
{
    int simulationTime = 20;
    std::string queueDiscType = "FifoQueueDisc";

    CommandLine cmd;
    cmd.AddValue("queueDiscType",
                 "Type of queue disc: FifoQueueDisc, CoDelQueueDisc, RedQueueDisc, etc.",
                 queueDiscType);
    cmd.Parse(argc, argv);

    NodeContainer sources, sink, routers;
    sources.Create(2);
    sink.Create(1);
    routers.Create(2);

    // channel to connect hosts to routers, same characteristics for all four links
    PointToPointHelper hc;
    hc.SetDeviceAttribute("DataRate", StringValue("5Mbps"));
    hc.SetChannelAttribute("Delay", StringValue("1ms"));

    NetDeviceContainer h1_r1 = hc.Install(sources.Get(0), routers.Get(0));
    NetDeviceContainer h2_r1 = hc.Install(sources.Get(1), routers.Get(0));
    NetDeviceContainer r2_h3 = hc.Install(routers.Get(1), sink.Get(0));

    // channel to connect routers
    PointToPointHelper rc;
    rc.SetDeviceAttribute("DataRate", StringValue("1Mbps"));
    rc.SetChannelAttribute("Delay", StringValue("3ms"));

    NetDeviceContainer r1_r2 = rc.Install(routers.Get(0), routers.Get(1));

    // install IP stack on all devices
    InternetStackHelper stack;
    stack.Install(sources);
    stack.Install(sink);
    stack.Install(routers);

    // assign one /24 subnet to each link
    Ipv4AddressHelper address;

    address.SetBase("10.1.0.0", "255.255.255.0");
    Ipv4InterfaceContainer if_h1_r1 = address.Assign(h1_r1);

    address.SetBase("10.0.0.0", "255.255.255.0");
    Ipv4InterfaceContainer if_h2_r1 = address.Assign(h2_r1);

    address.SetBase("10.2.0.0", "255.255.255.0");
    Ipv4InterfaceContainer if_r1_r2 = address.Assign(r1_r2);

    address.SetBase("10.3.0.0", "255.255.255.0");
    Ipv4InterfaceContainer if_r2_h3 = address.Assign(r2_h3);

    Ipv4GlobalRoutingHelper::PopulateRoutingTables();

    // install udp sender on h1
    OnOffHelper onoff("ns3::UdpSocketFactory",
        InetSocketAddress(if_r2_h3.GetAddress(1), 1616));
    onoff.SetConstantRate(DataRate("2Mbps"), 1000);

    ApplicationContainer app = onoff.Install(sources.Get(0));
    app.Start(Seconds(5.0));
    app.Stop(Seconds(15.0));

    // install udp receiver on h3
    PacketSinkHelper rcv("ns3::UdpSocketFactory",
        InetSocketAddress(Ipv4Address::GetAny(), 1616));
    ApplicationContainer rcv_app=rcv.Install(sink.Get(0));
    rcv_app.Start(Seconds(0.0));
    rcv_app.Stop(Seconds(20.0));


    //AsciiHelper @24:40 in video
    //this is only an example, not what is required for the task
    AsciiTraceHelper ascii;
    Ptr<OutputStreamWrapper> txStream = 
        ascii.CreateFileStream("onoff-tx-trace.txt");
    Config::ConnectWithoutContext(
        "/NodeList/0/ApplicationList/0/$ns3::OnOffApplication/Tx",
        MakeBoundCallback(&TxCallback, txStream)
    );




    // TODO

    std::cout << "Starting Simulation" << std::endl;
    Simulator::Stop(Seconds(simulationTime));
    Simulator::Run();
    Simulator::Destroy();

    return 0;
}
