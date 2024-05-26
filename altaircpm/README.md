##Introduction
This folder contains a version of CP/M 2.2 for the JAIR that does not require disk images on an SD card.
Instead, disk transfers are done through the second port on the JAIR and disk images are served from a PC.
The server on the PC is the same server program that works with the Altair FDC+ controller.

This JAIR supports baud rates up to 57.6K. At this rate, performance is as nearly as good as the original
Altair versions of CP/M from Lifeboat and Burcon. 

Version 1.4 or newer of the FDC+ server must be used to support the slower baud rates for this version
of CP/M. A copy of the serial server can be found at https://deramp.com/downloads/altair/hardware/fdc+/

##Using JAIR Serial Disk CP/M 2.2
The file “SerialJAIR63K.dsk” is a bootable CP/M image sized for at least 63K of RAM. Load this into drive
0 of the server to boot. Unfortunately, this version of CP/M will not boot using the standard BIOS.HEX
for booting CP/M. You can boot by either replacing BIOS.HEX on the SD card with JAIRBOOT.HEX, or manually
load JAIRBOOT.HEX during the boot process.

You can mount any of the standard 8” Altair disk images (size will be 330K) as additional drives. If you
want to make any of those other disks bootable, run SYSGEN to copy the boot image from drive A, or
run MOVCPM2S followed by SYSGEN to put the boot tracks on a different drive. MOVCPM2S also allows
you to change the location of CP/M for a system with more or less RAM than the 56K image provided.
Most any program on Altair disk images will execute properly when running under this serial disk CP/M.
However, any programs that access the disk controller directly will not work. This includes format
programs (FORMAT, AFORMAT) and the ACOPY high-speed disk copy program. 
