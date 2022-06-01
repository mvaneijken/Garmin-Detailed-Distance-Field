# Garmin-Detailed-Distance-Field
## Description
This data field shows lap distance in the following (default) formats (depending on current lap distance):
- 0 - 1 km/mile = 0.000
- 1 - 10 km/mile = 0.00
- 10 - beyond = 0.0

I've created this data field because the native lap data field on my Forerunner 935 is not able to show distances in meters. Because my good old Forerunner 310XT was able to display distances in meters and Garmin gives the opertunity to create custom datafield, I've created a new datafield that supports this functionality.

Currently English and Dutch languages are supported.

From the App settings in the Garmin Connect App you are able toe set the following parameters:
- Show the previous lap distance below the current lap distance
- Number of decimals from 0 to 1 kilometer / mile
- Number of decimals from 1 tot 10 kilometer / mile
- Number of decimals from 10 tot 100 kilometer / mile
- Number of decimals from 100 kilometer / mile

Depending on your device settings it shows distance in metric or statute format.

The data field supports adding a correction factor for the width/heigth of the screen. This is especially handy for round devices when the displayed values are to big or too small.

Note: Due limitations of the Garmin Connect SDK, detection of laps from pre-defined workout are only supported on devices compatible with Garmin Connect IQ 3.0 and higher. Other devices only can support laps recorded by pressing the "lap" button.

## What’s New
Updates:
2.2.9: Support new devices (e.g. FR255, FR955)

2.2.8: Support new devices (e.g. Fenix 7, Tactix, FR55), update Garmin Connect IQ to 4.1.3.

2.2.7: Support new devices, update Garmin Connect IQ to 4.0.6, minor code optimizations.

2.2.6: Fix for 'Out of Memory Error' on earlier devices (e.g. FR235). 

2.2.5: Fix for crash on FR935. Note! Screen correction now based on percentage 50% - 100%.
Small textual updates.

2.2.4: Background color fix for Venu devices with firmware 4.70 or higher (workarround still applies for firmware versions lower than 4.70);
Updated to Connect IQ SDK 3.1.8;

2.2.3: Background color fix for Venu devices (workarround by inverting background and foreground color)

2.2.2: Background color fix for Venu devices
Added debug option (Please only use when needed!)

2.2.1: Support for Fenix 6 devices, Venu, VivoActive 4, Bravo D2 devices, Marq devices;
Support for setting a correction factor for the width/heigth of the screen. This is especially handy for round devices when the displayed values are to big or too small.
A prefix is added to the last lap distance value.

2.1: Support for Forerunner 945, Forerunner 245 en Forerunner 245 Music

2.0: Support for additional devices like the Fenix5 and Forerunner 935
Possibility to set your own lap decimals from the Garmin Connect App
Support lap detection from workouts (Connect IQ 3.0 devices only!)

1.13: Memory optimization

1.12: Language updates

1.11: Multiple layout fixes and code optimization

1.1: Updated configurable app setting to display last lap distance too.

1.02: Minor layout changes.

1.01: Minor layout changes.

1.0: Initial release.
