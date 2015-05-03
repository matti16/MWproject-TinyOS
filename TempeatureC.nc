/**
 *  Implementation of module temperatureC.
 *  Node 1 is the coordinator and periodically sends a COLLECT message.
 *  The other nodes, upon receiving a COLLECT, forward it.
 *  Finally the information return back from the leaves to Node 1,
 *  on the way back, the average temperature of all the nodes is calculated.
 *
 *  @author Mattia Brusamento
 */


 #include "Temperature.h"
 #include "Timer.h"

 module temperatureC{

 	uses{
 		interface Boot;
		interface SplitControl;

 		interface AMPacket;
 		interface Packet;

 		interface AMSend;
 		interface Receive;

 		interface Timer<TMilli> as ProtocolTimer;
 		interface Timer<TMilli> as CollectTimer;
 		interface Timer<TMilli> as RandomTimer;
 		interface Random;

 		interface Read<uint16_t>;
 	}


 	implementation{

 		uint16_t num_measures = 0;
 		uint16_t total_temp = 0 ;
 		message_t packet;
 		uint8_t back_node = -1;
 		uint8_t my_hope;
 		bool collecting = FALSE;


 	//***************** Boot interface ********************//
  	event void Boot.booted() {
		dbg("boot","Application booted.\n");
		call SplitControl.start();
  	}

  	//***************** SplitControl interface ********************//
  	event void SplitControl.startDone(error_t err){
		if(err == SUCCESS) {
			if ( TOS_NODE_ID == 1 ) {
	 			dbg("role","I'm node 1: start sending periodical COLLECT!\n");
	 	 		call CollectTimer.startPeriodic( 5*60*1000 );
			}
    	}else{
			call SplitControl.start();
   		}

  	}
  
 	event void SplitControl.stopDone(error_t err){}


 	//***************** CollectTimer interface ********************//
 	event void CollectTimer.fired(){
 		temperature_msg_t* collect = (temperature_msg_t*)(call Packet.getPayload(&packet,sizeof(temperature_msg_t)));
 		collect->type = COLLECT;
 		collect->hope = 1;

 		dbg("radio_send", "Try to send COLLECT at time %s \n", sim_time_string());

 		if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(collect_msg_t)) == SUCCESS) {
			dbg("radio_send", "COLLECT passed to lower layer at time %s \n", sim_time_string());
		}else{
     		dbg("radio_send", "FAILED: tryin another time...\n");
     		if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(collect_msg_t)) == SUCCESS) {
				dbg("radio_send", "COLLECT passed to lower layer at time %s \n", sim_time_string());
			}else{
				dbg("radio_send", "ERROR in sending COLLECT!\n");
			}
     	}
 	}


 	//********************* AMSend interface ****************//
  	event void AMSend.sendDone(message_t* buf,error_t err) {
  		if(&packet == buf && err == SUCCESS ) {
			if( TOS_NODE_ID == 1 ){
				collecting = TRUE;
				dbg("radio_send", "COLLECT send! Waiting for responses...\n");
				call ProtocolTimer.startOneShot(WAITING_TIME);
			}else{
				if(((temperature_msg_t*)buf)->type == COLLECT ){
  					collecting = TRUE;
					dbg("radio_send", "COLLECT forwarded! Waiting for responses...\n");
				}else if(((temperature_msg_t*)buf)->type == MEASURE ){
					dbg("radio_send", "MEASURE forwarded back!\n");
				}
			}
		}
	}


	//***************************** Receive interface *****************//
  	event message_t* Receive.receive(message_t* buf,void* payload, uint8_t len) {
  		temperature_msg_t* mess=(temperature_msg_t*)payload;

  		//****COLLECT message*****//
  		if(mess->type == COLLECT){
  			if(TOS_NODE_ID > 1 && !collecting ){

  				//***Get the SOURCE***//
  				back_node = call AMPacket.source(buf);
  				my_hope = mess->hope;
  				dbg("radio_receive","COLLECT received at time %s from %hhu. Hope n°%i.\n", sim_time_string(), back_node, (int)my_hope);
				num_measures = 0;
				total_temp = 0;

  				//**Random Delay**//
  				call RandomTimer.startOneShot( ((call Random.rand16())%128) + 1 );
  			}

  		//****MEASURE message back****//	
  		}else if(mess->type == MEASURE && collecting){
  			dbg("radio_receive","MEASURE received at time %s from %hhu\n", sim_time_string(), call AMPacket.source(buf));
  			num_measures = num_measures + mess->weigth;
  			total_temp = total_temp + (mess->weigth * mess->avg);
		}

  	}


  	//***************** RandomTimer interface ********************//
 	event void RandomTimer.fired(){
 		temperature_msg_t* collect = (temperature_msg_t*)(call Packet.getPayload(&packet,sizeof(temperature_msg_t)));
 		collect->type = COLLECT;
 		collect->hope = my_hope + 1;

 		dbg("radio_send", "Try to send COLLECT at time %s \n", sim_time_string());

 		if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(collect_msg_t)) == SUCCESS) {
			dbg("radio_send", "COLLECT passed to lower layer at time %s \n", sim_time_string());
			call ProtocolTimer.startOneShot(WAITING_TIME/my_hope);
		}else{
     		dbg("radio_send", "FAILED: tryin another time...\n");
     		if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(collect_msg_t)) == SUCCESS) {
				dbg("radio_send", "COLLECT passed to lower layer at time %s \n", sim_time_string());
			}else{
				dbg("radio_send", "ERROR in sending COLLECT!\n");
			}
			call ProtocolTimer.startOneShot(WAITING_TIME/my_hope);
     	}

 	}
	
	//***************** ProtocolTimer interface ********************//
 	event void ProtocolTimer.fired(){
 		dbg("timer","Time is over now!\n");
 		collecting = FALSE;
 		call Read.read();
 	}

 	//***************** Read interface ********************//
 	event void Read.readDone(error_t result, uint16_t data) {
 		if(result == SUCCESS){
 			num_measures++;
 			total_temp = total_temp + data;
 		}
 		uint16_t average = total_temp/num_measures;

 		//***** INTERMEDIATE NODES *******//
 		if(TOS_NODE_ID != 1){

 			temperature_msg_t* measure = (temperature_msg_t*)(call Packet.getPayload(&packet,sizeof(temperature_msg_t)));
 			measure->type = MEASURE;
 			measure->weigth = num_measures;
 			measure->avg = average;

 			dbg("radio_send", "MEASURE: Avg=%i (with n=%i), trying to SEND it at time %s... \n", (int)average , (int)num_measures ,sim_time_string());

 			if (call AMSend.send(back_node, &packet, sizeof(collect_msg_t)) == SUCCESS) {
				dbg("radio_send", "MEASURE passed to lower layer at time %s \n", sim_time_string());
			}else{
     			dbg("radio_send", "FAILED: tryin another time...\n");
     			if (call AMSend.send(back_node, &packet, sizeof(collect_msg_t)) == SUCCESS) {
					dbg("radio_send", "MEASURE passed to lower layer at time %s \n", sim_time_string());
				}else{
					dbg("radio_send", "ERROR in sending MEASURE!\n");
				}
     		}

     	//***** NODE 1 - PROTOCOL FINISHED ********//
     	}else{
     		dbg("final", "MEASURE TAKEN! Average Temp. = %i, Contributors = %i. Time: %s.\n", (int)average,(int)num_measures, sim_time_string());
     	}

 	}



 	}
 }