#ifndef MCU_H
#define MCU_H

#include <3ds.h>

Handle mcuhwcHandle;

Result mcuInit();
Result mcuExit();
Result mcuGetBatteryLevel(u8* out);

#endif