
#include "Temperature.h"

configuration TemperatureAppC {}

implementation {

  components MainC, TemperatureC as App;
  components new AMSenderC(AM_MY_MSG);
  components new AMReceiverC(AM_MY_MSG);
  components ActiveMessageC;
  components new TimerMilliC() as Timer0;
  components new TimerMilliC() as Timer1;
  components new TimerMilliC() as Timer2;
  components RandomC;
  components new DemoSensorC() as Sensor;

  //Boot interface
  App.Boot -> MainC.Boot;

  //Send and Receive interfaces
  App.Receive -> AMReceiverC;
  App.AMSend -> AMSenderC;

  //Radio Control
  App.SplitControl -> ActiveMessageC;

  //Interfaces to access package fields
  App.AMPacket -> AMSenderC;
  App.Packet -> AMSenderC;

  //Timer interface
  App.CollectTimer -> Timer0;
  App.ProtocolTimer -> Timer1;
  App.RandomTimer -> Timer2;
  //Random Interface
  App.Random -> RandomC;

  //Fake Sensor read
  App.Read -> Sensor;

}
