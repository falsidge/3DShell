/* Obtained from ctrmus source with permission. */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "audio/opus.h"
#include "music.h"

static OggOpusFile *opusFile;

static FILE * f;
static const size_t buffSize = ( 5760*2 );

/**
 * Set decoder parameters for Opus.
 *
 * \param	decoder	Structure to store parameters.
 */
void setOpus(struct decoder_fn * decoder)
{
	decoder->init = &initOpus;
	decoder->rate = &rateOpus;
	decoder->channels = &channelOpus;
	decoder->buffSize = buffSize;
	decoder->decode = &decodeOpus;
	decoder->exit = &exitOpus;
}

/**
 * Initialise Opus decoder.
 *
 * \param	file	Location of opus file to play.
 * \return			0 on success, else failure.
 */
int initOpus(const char * file)
{
	int err = -1;

    opusFile = op_open_file(file,&err);
	if (!err)
		goto out;

out:
	return err;
}

/**
 * Get sampling rate of Opus file.
 *
 * \return	Sampling rate.
 */
u32 rateOpus(void)
{
	return 48000; // all opus files resampled to 48khz
}

/**
 * Get number of channels of Opus file.
 *
 * \return	Number of channels for opened file.
 */
u8 channelOpus(void)
{
	return op_channel_count(opusFile,-1);
}

/**
 * Decode part of open Opus file.
 *
 * \param buffer	Decoded output.
 * \return			Samples read for each channel. 0 for end of file, negative
 *					for error.
 */
u64 decodeOpus(void * buffer)
{
	return fillOpusBuffer(buffer);
}

/**
 * Free Opus decoder.
 */
void exitOpus(void)
{
    op_free(opusFile);
    fclose(f);
}

/**
 * Decode Opus file to fill buffer.
 *
 * \param opusFile		File to decode.
 * \param bufferOut		Pointer to buffer.
 * \return				Samples read per channel.
 */
u64 fillOpusBuffer(int16_t * bufferOut)
{
	u64 samplesRead = 0;
	int samplesToRead = buffSize;

	while (samplesRead <samplesToRead)
    {  
        int samplesJustRead = op_read(opusFile, bufferOut+samplesRead, samplesToRead , NULL)*op_channel_count(opusFile,-1);
        
        if (samplesJustRead < 0) 
            return samplesJustRead;
        else if (samplesJustRead == 0)
            break;
        samplesRead += samplesJustRead;
    }

    return samplesRead;
}

/**
 * Checks if the input file is Opus.
 *
 * \param in	Input file.
 * \return		0 if Opus file, else not or failure.
 */
int isOpus(const char * in)
{
	OggOpusFile* testof;
	int err;

    testof = op_test_file(in, &err);

	op_free(testof);

	return err;
}