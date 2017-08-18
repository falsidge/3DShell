#include "common.h"
#include "clock.h"
#include "mp3.h"
#include "music.h"
#include "ogg.h"
#include "power.h"
#include "screen.h"
#include "screenshot.h"
#include "utils.h"
#include "wifi.h"

static struct audio * music;

void musicPlayer(char * path)
{
	music = mp3_create(SFX);
	
	if (music != NULL)
		mp3_load(path, music);
	else 
		music->status = -1;
	
	while (aptMainLoop())
	{
		hidScanInput();
		
		screen_begin_frame();
		screen_select(GFX_BOTTOM);
		screen_draw_texture(TEXTURE_MUSIC_BOTTOM_BG, 0, 0);
		
		if (!(audio_isPaused(music)))
		{
			screen_draw_texture(TEXTURE_MUSIC_PAUSE, ((320 - screen_get_texture_width(TEXTURE_MUSIC_PAUSE)) / 2) - 2, ((240 - screen_get_texture_height(TEXTURE_MUSIC_PAUSE)) / 2));
			if (kPressed & KEY_A)
				audio_togglePlayback(music);
		}
		else
		{
			screen_draw_texture(TEXTURE_MUSIC_PLAY, ((320 - screen_get_texture_width(TEXTURE_MUSIC_PLAY)) / 2) - 2, ((240 - screen_get_texture_height(TEXTURE_MUSIC_PLAY)) / 2));
			if (kPressed & KEY_A)
				audio_togglePlayback(music);
		}
		
		screen_select(GFX_TOP);
		screen_draw_texture(TEXTURE_MUSIC_TOP_BG, 0, 0);
		
		drawWifiStatus(270, 2);
		drawBatteryStatus(295, 2);
		digitalTime();
		
		screen_draw_stringf(5, 25, 0.5f, 0.5f, RGBA8(255, 255, 255, 255), "%s", fileName);
		
		screen_end_frame();
		
		if (kPressed & KEY_B)
		{
			// wait(100000000);
			break;
		}
		
		if ((kHeld & KEY_L) && (kHeld & KEY_R))
			captureScreenshot();
	}
	
	audio_stop(music);
}