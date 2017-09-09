/* Obtained from ctrmus source with permission. */

#include <opusfile.h>

#include "music.h"

void setOpus(struct decoder_fn * decoder);

int initOpus(const char * file);

u32 rateOpus(void);

u8 channelOpus(void);

u64 decodeOpus(void * buffer);

void exitOpus(void);

int playOpus(const char * in);

u64 fillOpusBuffer(int16_t * bufferOut);

int isOpus(const char * in);