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


void PingCallback(Ptr<OutputStreamWrapper> stream, uint16_t seq, Time rtt)
{
    *stream->GetStream() << Simulator::Now().GetSeconds() << " " << 
        rtt.GetSeconds() << std::endl;
}

void QueueCallback(Ptr<OutputStreamWrapper> stream, uint32_t oldValue, uint32_t newValue)
{
    *stream->GetStream() << Simulator::Now().GetSeconds() << " " << 
        newValue << std::endl;
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

    ApplicationContainer source_app = onoff.Install(sources.Get(0));
    source_app.Start(Seconds(5.0));
    source_app.Stop(Seconds(15.0));

    // install udp receiver on h3
    PacketSinkHelper rcv("ns3::UdpSocketFactory",
        InetSocketAddress(Ipv4Address::GetAny(), 1616));
    ApplicationContainer sink_app=rcv.Install(sink.Get(0));
    sink_app.Start(Seconds(0.0));
    sink_app.Stop(Seconds(20.0));

    // install ping app on h2
    PingHelper ping(if_r2_h3.GetAddress(1));
    ApplicationContainer ping_app = ping.Install(sources.Get(1));
    ping_app.Start(Seconds(0));
    ping_app.Stop(Seconds(simulationTime));

    // add tracing to the ping app
    AsciiTraceHelper ascii;
    Ptr<OutputStreamWrapper> pingStream =
        ascii.CreateFileStream("ping_trace.txt");
    Config::ConnectWithoutContext(
        "/NodeList/1/ApplicationList/0/$ns3::Ping/Rtt",
        MakeBoundCallback(&PingCallback, pingStream)
    );

    // install queue discipline according to CLI arg on r1 interface
    TrafficControlHelper queueDiscipline;
    queueDiscipline.SetRootQueueDisc("ns3::" + queueDiscType);
    TrafficControlHelper::Default().Uninstall(r1_r2.Get(0));
    QueueDiscContainer queueDiscApp = queueDiscipline.Install(r1_r2.Get(0));

    // add tracing to the queue of r1
    Ptr<OutputStreamWrapper> queueDiscStream =
        ascii.CreateFileStream("queue_disc_trace.txt");
    Ptr<QueueDisc> installedQueueDisc = queueDiscApp.Get(0);
    installedQueueDisc->TraceConnectWithoutContext ("BytesInQueue",
        MakeBoundCallback (&QueueCallback, queueDiscStream));


    std::cout << "Starting Simulation with queue " << queueDiscType << std::endl;
    Simulator::Stop(Seconds(simulationTime));
    Simulator::Run();
    Simulator::Destroy();

    return 0;
}
