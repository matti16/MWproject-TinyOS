/**
*  @author Mattia Brusamento
*/

#ifndef TEMPERATURE_H
#define TEMPERATURE_H

typedef nx_struct_tmessage{
	nx_uint8_t type;
 	nx_uint16_t hope;

	nx_uint16_t weigth;
	nx_uint16_t avg;
} temperature_msg_t;

#define COLLECT 1;
#define MEASURE 2;

#define WAITING_TIME 30*1000;

enum{
AM_TEMP_MSG = 6,
};

#endif