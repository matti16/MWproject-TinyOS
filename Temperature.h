/**
*  @author Mattia Brusamento
*/

#ifndef TEMPERATURE_H
#define TEMPERATURE_H

#define COLLECT 1
#define MEASURE 2
#define WAITING_TIME 30000

typedef nx_struct tmessage{
	nx_uint8_t type;
 	nx_uint16_t hope;

	nx_uint16_t weigth;
	nx_uint16_t avg;
} temperature_msg_t;


enum{
AM_MY_MSG = 6,
};

#endif
