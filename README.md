# MWproject-TinyOS
In network data collection and processing with TinyOS

Implement a data collection infrastructure to retrieve the average temperature in an area. Each node periodically measures and stores the ambient temperature (under TOSSIM use an emulation of the temperature sensor).

The sink node periodically broadcast a message COLLECT that starts data collection. The COLLECT message has to flood the network and trigger a data collection that calculates, in network, the average temperature read by sensors, that must be back to the sink.

A possible solution to the problem above is to build, during the flooding of the COLLECT message, a spanning tree, used backward to collect data and calculate the required average.

In practice, receiving nodes should forward the COLLECT message in broadcast (insert a random timeout to reduce collisions) to flood the network (nodes are supposed to be spread in an area that cannot be directly reached by the sink node). Upon receiving the COLLECT messages, nodes not only should reforward it, but they should also start waiting for a time period that is inversely proportional to the number of hops the COLLECT message already travelled. During this time period they collect replies coming from downstream nodes. At the end of the time period, each node averages the data collected with the temperature it reads, sending the result upstream (using unicast communication) toward the node from which it received the COLLECT message.

Make the appropriate choice in terms of data forwarded upstream, to correctly calculate the global average.

Test the system in TOSSIM, with a network big enough to stress the multi-hop nature of the protocol.
