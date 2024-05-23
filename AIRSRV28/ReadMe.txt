These files comprise the Firmware for the 8080A CPU board replacement for IMSAI & ALTAIR vintage computers, aka JAIR, aka AIR.

By Josh Bensadon, Jan 3, 2015
jbensadon@hotmail.com
Updated for AIRSR V2.8 by Patrick Linstruth, May 23, 2024

The file you need to burn to a 27C256 EPROM is: AIRBLV25.OBJ  (It's really a HEX file)
Files you need to copy to FAT16 formated SD card are:

For large 8MB disks:
  BIGBOOT.bin
  BIOS.HEX

For small 250K disks:
  DISK-A.bin
  DISK-B.bin
  DISK-C.bin
  DISK-D.bin
  BIOS.HEX

Jumper JP5 (Shadow ROM KILL) (above EPROM) must be set 2-3 (upper position) and Output Chip 8212 (IC-J5) must be installed.

This boot loader program will:
 -display a quick message
 -Optionally test upper RAM at F000 (otherwise not testable system RAM)
 -load the hex file BIOS.HEX from the SD Card

Files included are:

Readme.txt	-The file you are reading now (this line always makes me laugh).

Bootloader program to copy main system rom to upper ram.
AIRBL.bat	-batch file to assemble (creates *.bin file)
AIRBLv25.asm	-assembler source code for boot loader

Bootloader generated files:
AIRBLv25.obj	-assembled code in Intel HEX format (BURN TO EPROM)

System ROM program (Monitor & BIOS to boot CP/M 2.2 from SD card)
AIRSR.bat	-batch file to assemble (creates bin file & attaches bootloader bin)
AIRSRV28.asm	-assembler source code for System ROM

System ROM generated files:
AIRSRV28.lst	-Listing output
AIRSRV28.obj	-assembled hex code  (This intermediate file gets renamed to BIOS.HEX). Load on SD Card.

The AIRSRV28.obj file is renamed BIOS.HEX and put on to the SD Card

CPMDISKS.TXT    -A file containing the Disk Parameter Block for various sizes/types of disks.

Aux Files:
DISK-A blank with CPM only.bin	-A raw disk image of 256,256 bytes long = 26 sectors * 77 tracks * 128 bytes long containing just CP/M in the boot tracks (1 & 2)
DISK-A with MON-32K.bin -The above file, but with my high 32K monitor included as a file on CP/M.
DISK-A with standard CPM files.bin -The above file but with all the rest of CP/M standard files.

Copy any of the BIN files to "DISK-A.bin" to the FAT16 formated SD Card, this will hold CP/M v2.2

Tool files:
TASM*.*		-Cross Assembler program
