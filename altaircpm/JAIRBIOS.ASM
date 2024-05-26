****************************************************************************
;
; CP/M 2.2 BIOS for MITS Altair 8800 and a virtual Altair 8" floppy
;    drive served through an 88-2SIO serial port. The same PC based
;    disk server that supports the FDC+ can be used as the server for
;    this version of CP/M (use server version 1.4 or newer).
;
;    With Martin Eberhard’s 88-2SIOJP board, the baud rate can be as 
;    high as 76.8K baud. At this rate, performance is the same as an
;    original Altair CP/M versions from Lifeboat and Burcon running
;    on an actual disk drive.
;
;    The same disk layout as used with the original versions of CP/M 1.4 
;    and 2.2 is maintained for full backward and forward compatibility.
;
;    This version provides full IOBYTE support to allow use of a wider
;    variety of standard Altair I/O boards. Search for "IOBYTE" in this
;    source file for details.
;
;    This version looks for a Teletype on the console port during cold boot
;    and if detected (based on baud rate), subsequently follows any CR to
;    the console device with a NULL to give the Teletype carriage time to
;    reach the left margin. The send null flag (sndNull) is located imme-
;    diately following the MODE and IOBYTE in memory so it can be over-
;    ridden if needed.
;
;		Item	  Offset from start of BIOS
;		------	  ----------------------------------
;		MODE	  33h (20B3h in memory after MOVCPM)
;		IOBYTE	  34h (20B4h in memory after MOVCPM)
;		SNDNULL	  35h (20B5h in memory after MOVCPM)
;
;    Version History
;
;    Ver     Date	  Description
;    ---   ---------	---------------------
;    1.0   10/26/2023	Original, Mike Douglas
;
;--------------------------------------------------------------------------
;
;    To patch changes made to this BIOS into a CP/M image saved from
;    MOVCPM2S (e.g., CPMxx.COM), use the following commands:
;
;	A>DDT CPMxx.COM
;	-IBIOS.HEX
;	-Rxxxx      (where xxxx = BIAS computed below)
;	-G0	    (Go zero, not "oh")
;	A>SYSGEN
;
;****************************************************************************

MEMSIZE	equ	56		;set memory size in K bytes

;-----------------------------
; CP/M size & locations
;-----------------------------
CCPLEN	equ	0800h		;CPM 2.2 fixed length
BDOSLEN	equ	0E00h		;CPM 2.2 fixed length
BIOSLEN	equ	1800h		;length of this BIOS

CCPBASE	equ	MEMSIZE*1024 - BIOSLEN - BDOSLEN - CCPLEN
BDOSENT	equ	(CCPBASE+CCPLEN+6)	 ;entry address of BDOS
BIOSBAS	equ	(CCPBASE+CCPLEN+BDOSLEN) ;base address of this BIOS

BIAS	equ	0A80h-CCPBASE	;bias in DDT to patch in this BIOS

;-----------------------------
; CP/M page zero equates
;-----------------------------
WBOOTV	equ	00h		;warm boot vector location
BDOSV	equ	05h		;bdos entry vector location
CDISK	equ	04h		;CPM current disk
DEFDMA	equ	80h		;default dma address

IOBYTE	equ	03h		;CPM IOBYTE address
SHFTCON	equ	1		;left rotate count to align CON in bits 2,1
SHFTRDR	equ	7		;left rotate count to align RDR in bits 2,1
SHFTPUN	equ	5		;left rotate count to align PUN in bits 2,1
SHFTLST	equ	3		;left rotate count to align LST in bits 2,1

;-----------------------------
; Disk parameters
;-----------------------------
NUMTRK	equ	77		;number of tracks on the disk
NUMSEC	equ	32		;sectors per track
DATATRK	equ	6		;1st data format track
NUMDISK	equ	4		;four drives supported
CSECLEN	equ	128		;CP/M sector length
PSECLEN	equ	137		;physical sector length
TRKLEN	equ	NUMSEC*PSECLEN
WBSSEC	equ	3		;starting sector of CP/M image
WBSECS	equ	(CCPLEN+BDOSLEN)/CSECLEN   ;# warm boot sectors to read

;-----------------------------
; CP/M Disk Parameter Block Values
;-----------------------------
BSH	equ	4		;allocation block shift factor (2K block)
BLM	equ	0Fh		;allocation block mask (2K block)
EXM	equ	0		;extent mask
DSM	equ	149		;max block number (150 blocks of 2K bytes)
DRM	equ	63		;max directory entry number (64 entries) 
AL0	equ	0C0h		;directory allocation block bits byte 0
AL1	equ	0		;directory allocation block bits byte 1
RESTRK	equ	2		;reserved tracks for boot image
CKS	equ	(DRM+1)/4	;directory check space

; System tracks (0-5) sector format

SYSTRK	equ	0		;offset of track number
SYSDATA	equ	3		;offset of 128 byte data payload
SYSSTOP	equ	131		;offset of stop byte (FFh)
SYSCSUM	equ	132		;offset of checksum

; Data tracks (6-76) sector format

DATTRK	equ	0		;offset of track number
DATSEC	equ	1		;offset of sector number
DATCSUM	equ	4		;offset of checksum
DATDATA	equ	7		;offset of 128 byte data payload
DATSTOP	equ	135		;offset of stop byte (FFh)

FP	equ	0FFh		;front panel/programming output

;-----------------------------
; JAIR Serial Ports 
;-----------------------------
COM1	equ	20h		;COM1 base port address
COM1DAT	equ	COM1		;1st port on 2SIO board - data register
COM1LCR	equ	COM1 + 3	;COM1 - line control register
COM1MCR	equ	COM1 + 4	;COM1 - modem control register
COM1LSR	equ	COM1 + 5	;COM1 - line status register
COM1MSR	equ	COM1 + 6	;COM1 - modem status register
COM1DLS	equ	COM1		;COM1 - divisor latch (LS)
COM1DMS	equ	COM1 + 1	;COM1 - divisor latch (MS)
COM2	equ	28h		;COM2 base port address
COM2DAT	equ	COM2		;2nd port on 2SIO board - data register
COM2LCR	equ	COM2 + 3	;COM2 - line control register
COM2MCR	equ	COM2 + 4	;COM2 - modem control register
COM2LSR	equ	COM2 + 5	;COM2 - line status register
COM2MSR	equ	COM2 + 6	;COM2 - modem status register
COM2DLS	equ	COM2		;COM2 - divisor latch (LS)
COM2DMS	equ	COM2 + 1	;COM2 - divisor latch (MS)
COMDLAB	equ	80h		;divisor latch access bit (DLAB)
COMDR	equ	01h		;data ready (DR)
COMTHRE	equ	20h		;transmit holding register empty (THRE)
COMDTR	equ	01h		;data terminal ready (DTR)
COMRTS	equ	02h		;request to send (RTS)
COM8BIT	equ	03h		;8 bits
COM96	equ	12		;9.6K baud rate
COM192	equ	6		;19.2K baud rate
COM384	equ	3		;38.4K baud rate
COM576	equ	2		;57.6K baud rate

;-----------------------------
; 2SIO Serial Board 
;-----------------------------
SIO1CTL	equ	10h		;1st port on 2SIO board - control register
SIO1DAT	equ	11h		;1st port on 2SIO board - data register
SIO2CTL	equ	12h		;2nd port on 2SIO board - control register
SIO2DAT	equ	13h		;2nd port on 2SIO board - data register
SIORDRF	equ	01h		;read data register full flag
SIOTDRE	equ	02h		;transmit data register empty flag

;-----------------------------
; Set serial server port here
;-----------------------------
SRVRCTL	equ	SIO2CTL		;serial port for disk server
SRVRDAT	equ	SIO2DAT

;-----------------------------
; SIO Serial Board 
;-----------------------------
SIOCTL	equ	00h		;SIO board at 0 - control register
SIODAT	equ	01h		;SIO board at 0 - data register
ACRCTL	equ	06h		;SIO board at 6 - control register (cassette)
ACRDAT	equ	07h		;SIO board at 6 - data register (cassette)
SIORCV	equ	01h		;data received bit (inverted)
SIOXMT	equ	80h		;read to transmit (inverted)

;-----------------------------
; LPC Line Printer Controller
;-----------------------------
LPCCTL	equ	02h		;line printer control port
LPCDAT	equ	03h		;line printer data port
LPCBSY	equ	02h		;mask to test printer busy flag

;-----------------------------
; Misc equates
;-----------------------------
RDTRIES	equ	3		;read tries 
WRTRIES	equ	3		;write tries

UNDEF	equ	0FFh		;undefined value
CR	equ	13		;ascii for carriage return
LF	equ	10		;ascii for line feed

	org	BIOSBAS
;-----------------------------------------------------------------------------
;  BIOS Entry Jump Table
;-----------------------------------------------------------------------------
	jmp	boot		;cold start
wbJump	jmp	wBoot		;warm start
	jmp	conSt		;console status
	jmp	conIn		;console character in (and disk flush)
	jmp	conOut		;console character out
	jmp	list		;list character out
	jmp	punch		;punch character out
	jmp	reader		;reader character in
	jmp	home		;move head to home position
	jmp	selDsk		;select disk
	jmp	setTrk		;set track number
	jmp	setSec		;set sector number
	jmp	setDma		;set dma address
	jmp	read		;read disk
	jmp	write		;write disk
	jmp	listSt		;return list status
	jmp	secTran		;sector translate

;-----------------------------------------------------------------------------
;  MODE byte flags (offset 33h)
;-----------------------------------------------------------------------------
mode	db	00h		;default mode byte
fCLDCMD	equ	01h		;true = CCP process cmd on cold start
fWRMCMD	equ	02h		;true = CCP process cmd on warm start

;---------------------------------------------------------------------------
;  IOBYTE definition (offset 34h)
;
;    CON device (bits 1,0):
;	00 - TTY on SIO at I/O address 0
;	01 - CRT on JAIR COM1
;	10 - BAT indirect through RDR logical device
;	11 - UC1 on JAIR COM2
;
;    RDR device (bits 3,2):
;	00 - TTY on SIO at I/O address 0
;	01 - PTR on JAIR COM1
;	10 - UR1 on cassette port (SIO 6/7)
;	11 - UR2 on 2SIO port 2*
;
;    PUN device (bits 5,4):
;	00 - TTY on SIO at I/O address 0
;	01 - PTP on JAIR COM1
;	10 - UP1 on cassette port (SIO 6/7)
;	11 - UP2 on 2SIO port 2*
; 
;    LST device bits (7,6):
;	00 - TTY on SIO at I/O address 0
;	01 - CRT on JAIR COM1
;	10 - LPT on LPC board
;	11 - UL1 on 2SIO port 2*
;
;  * Do not use (this is the disk server serial port)
;---------------------------------------------------------------------------
dIoByte	db	055h		;CON = CRT (JAIR COM1)
				;RDR = PTR (JAIR COM1)
				;PUN = PTP (JAIR COM1)
				;LST = UL1 (JAIR COM1)
				
; sndNull flag (offset 35h)
;    Determines if a NULL should be transmitted following a CR when
;    writing to the console device. This is automatically set during
;    cold start based on the baud rate of the console device. A user
;    can change this flag if needed after each cold start.

sndNull	db	0		;true if null should be sent after CR

;----------------------------------------------------------------------------
; boot - Cold boot BIOS entry. CPM is already loaded in memory. Initialize
;    serial ports, display welcome banner and enter the CCP.
;----------------------------------------------------------------------------
boot	lxi	sp,0100h	;init stack pointer

	call	serInit		;initialize serial ports and IOBYTE

	call	dispMsg		;display welcome message
	db	CR,LF,LF
	db	MEMSIZE/10 + '0',MEMSIZE mod 10 + '0'
	db	'K CP/M 2.2 v1.0 JAIR',CR,LF
	db	'For SERIAL Altair 8" Floppy',CR,LF,0

				;dispMsg returns with A=0
	sta	CDISK		;current CPM disk is drive zero
	sta	coldSt		;no longer in cold start

	call	initCpm		;common cold/warm boot CPM initialization

	lda	mode		;see if cold start command line requested
	ani	fCLDCMD
	jz	CCPBASE+3	;enter CCP and don't run command line

	jmp	CCPBASE		;enter CCP with possible cmd line

;----------------------------------------------------------------------------
; wBoot - Warm boot BIOS entry. Reload CPM from disk up to, but
;    not including the BIOS. Re-enter CPM after loading.
;----------------------------------------------------------------------------
wBoot	lxi	sp,0100h	;init stack pointer
	xra	a		;boot from drive zero
	sta	drvNum
	lxi	b,WBSECS*256+WBSSEC    ;B=secs to read, C=starting sec
	lxi	h,CCPBASE	;HL->CP/M load address

wbTrk	sta	trkNum		;save track number to use

wbLoop	shld	dmaAddr		;set read destination
	mov	a,c		;set sector number from C
	sta	secNum

	push	b		;save sector count and number
	call	read		;read next sector
	pop	b
	jnz	wBoot		;failed read, start over
	
	dcr	b		;decrement total sector count
	jz	warmCpm		;warm boot is done, warm enter CP/M
	
	inr	c		;bump to next sector number
	mvi	a,NUMSEC	;A=number of sectors in a track
	sub	c		;all sectors in track done?
	jnz	wbLoop		;no, read next sector
	
	mov	c,a		;start with C=sector 0 on text track
	lda	trkNum		;increment track number
	inr	a

	jmp	wbTrk		;continue

warmCpm	call	initCpm		;common warm/cold boot CPM initialization

	lda	mode		;see if warm start command line requested
	ani	fWRMCMD
	jz	CCPBASE+3	;enter CCP and don't run command line
	jmp	CCPBASE		;else, enter CCP with possible cmd line

;----------------------------------------------------------------------------
; initCpm - Initialization for CPM that is common to both warm
;    boot and cold boot.
;----------------------------------------------------------------------------
initCpm	lxi	h,DEFDMA	;set the default dma address (80h)
	shld	dmaAddr

	mvi	a,JMP		;8080 "jump" opcode
	sta	WBOOTV		;store in 1st byte of warm boot vector
	sta	BDOSV		;and 1st byte of bdos entry vector

	lxi	h,wbJump	;get the warm boot jump address
	shld	WBOOTV+1	;and put it after the jump

	lxi	h,BDOSENT	;BDOS entry address
	shld	BDOSV+1		;put it after the jump opcode

	lda	CDISK		;get current disk number
	mov	c,a		;pass it to CPM in register C
	ret

;----------------------------------------------------------------------------
; selDsk - Select Disk BIOS entry. C contains the disk number to select.
;    Validate the disk number and return a pointer to the disk parameter
;    header in HL. Zero is returned in HL for invalid drive number. The
;    disk number is stored in drvNum. No drive activity takes place.
;
; On Entry
;    C = disk number to select (or FFh, see Extended Functions below)
;
; On Exit
;    drvNum = disk number to select
;    Success: HL->DPH for this drive. Error: HL=0
;    Clobbers A,D,E,H,L
;----------------------------------------------------------------------------
; selDsk is also used as the "Extended Function" entry point. If a drive
;    number of FFh is passed in C, then this call is an extended function
;    request and not a disk select request. In this case:
;
; On Entry
;    C = FFh (extended function request)
;    B = extended function number (see list below)
;
; On Exit
;    H = 0, L = number of functions supported. This return value is neither
;	the "invalid drive" response (HL=0) or a valid DPH pointer when a
;    	drive is selected. This allows the caller to detect whether a
;	BIOS supports extended functions or not.
;    Z flag set true if the extended function executed without error, Z flag
;	false otherwise.
;    Clobbers All
;
;    Extended Functions supported by this BIOS:
;	00h - Invalidate and flush track buffer.
;----------------------------------------------------------------------------
selDsk	lxi	h,0		;init HL=0 for invalid drive request
	inr	c		;test for drive number of 0FFh
	jnz	notExt		;not an extended function request

	inr	l		;H=0, L=1 (number of functions supported)
	mov	a,b		;A=extended function code
	ora	a		;code 0 = flush track buffer?
	cz	invFlsh		;yes, invalidate and flush track buffer
	ret			;exit with HL=1 and proper zero status

notExt	mov	a,c		;A=drive number + 1
	dcr	a		;A=drive number
	cpi	NUMDISK		;verify drive number less than number of disks
	rnc			;invalid drive number, return with HL=0=error
	sta	drvNum		;else, save new drive number

	rlc			;compute disk parameter header address
	rlc			;   as (16*drvNum) + dpHead
	rlc
	rlc			;A=16*drvNum
	lxi	h,dpHead  	;HL->start of disk parameter headers
	mov	e,a
	mvi	d,0
	dad	d		;HL->DPH for the passed drive number
	ret

;----------------------------------------------------------------------------
; home - Home BIOS entry. Set trkNum to zero. No drive activity takes place.
;
; On Entry
;
; On Exit
;    trkNum set to zero
;    Clobbers A
;----------------------------------------------------------------------------
home	xra	a		;set trkNum to zero
	sta	trkNum
	ret

;----------------------------------------------------------------------------
; setTrk - Set Track BIOS entry. C contains the desired track number.
;    The track number is saved in trkNum for later use.
;
; On Entry
;    C = track number to set
;
; On Exit
;    trkNum = track specified in C
;    Clobbers A
;----------------------------------------------------------------------------
setTrk	mov	a,c		;save track number passed in C
	sta	trkNum
	ret

;----------------------------------------------------------------------------
; setSec - Set Sector BIOS entry. C contains the 1-indexed CPM physical 
;   sector. Saved in secNum as a zero-indexed value.  
;
; On Entry
;    C = 1-indexed sector number to set
;
; On Exit
;    secNum = zero-indexed sector number
;    Clobbers A
;----------------------------------------------------------------------------
setSec	mov	a,c		;A=1-indexed sector number
	dcr	a		;convert to zero indexed
	sta	secNum
	ret

;----------------------------------------------------------------------------
; setDma - Set DMA BIOS entry. BC contains the address for reading or
;    writing sector data for subsequent I/O operations. The address is
;    stored in dmaAddr.
;
; On Entry
;    BC = I/O buffer address
;
; On Exit
;    dmaAddr = address specified in BC
;    Clobbers H,L
;----------------------------------------------------------------------------
setDma	mov	h,b		;save buffer address passed in BC
	mov	l,c
	shld	dmaAddr
	ret
	
;----------------------------------------------------------------------------
; secTran - Sector translation BIOS entry. Convert zero-indexed logical 
;    sector number in BC to a CPM one-indexed physical sector number in HL
;    based on the translate table passed in DE.
;
; On Entry
;    BC = logical sector number
;    DE->sector translate table for selected drive
;
; On Exit
;    HL = physical sector number
;    Clobbers B,D,E,H,L
;----------------------------------------------------------------------------
secTran	xchg			;HL->translate table
	mvi	b,0		;make sure msb of sector is zero
	dad	b		;HL->translated sector num
	mov	l,m		;L=lsb of sector
	mov	h,b		;H=0=msb of sector
	ret

;----------------------------------------------------------------------------
; read - Read sector BIOS entry. Read one sector using the drvNum, 
;    trkNum, secNum, and dmaAddr previously specified.
;
; On Entry
;    drvNum = drive to read from
;    trkNum = track to read from
;    secNum = sector number to read (0-31)
;    dmaAddr = address of buffer to read into
;
; On Exit
;    If read successful
;	sector read into (dmaAddr)
;	HL = (dmaAddr) + CSECLEN
;	A=0, Z flag set true
;    Else
;	A=1, Z flag set false
;    Interrupts enabled
;    Clobbers all
;----------------------------------------------------------------------------
read	call	ckFlush		;flush track buffer if needed
	call	readTrk		;fill track buffer if needed
	jnz	exitDio		;track read error, exit
	
	call	movRead		;move sector to (dmaAddr)

exitDio	mvi	a,0		;if zero is true, return zero
	rz
	inr	a		;else return A<>0, Z false
	ret

;----------------------------------------------------------------------------
; movRead - Move sector data from track buffer to (dmaAddr) for a
;    CPM read request
;
; On Entry
;    trkNum = track to read
;    secNum = sector number to read (0-31)
;    dmaAddr = address of buffer to read into
;
; On Exit
;    sector data moved to (dmaAddr), Z flag set true
;    HL = (dmaAddr) + CSECLEN
;    Clobbers all
;----------------------------------------------------------------------------
movRead	call	altSkew		;secNum to hard sector in A
	call	sec2Adr		;HL->sector in trkBuf
	
	lxi	d,DATDATA	;DE=offset to data portion of sector
	lda	trkNum		;on a data track?
	cpi	DATATRK
	jnc	mrMove		;yes, data track (DE already correct)
	lxi	d,SYSDATA	;else, use system track offset

mrMove	dad	d		;HL->data portion of sector
	xchg			;DE->data portion of sector
	lhld	dmaAddr		;HL->destination for data
	mvi	b,CSECLEN	;B=number of bytes to move
	
mrLoop	ldax	d		;move sector from trkBuf to (dmaAddr) 
	mov	m,a
	inx	h		;increment pointers
	inx	d
	dcr	b		;loop count
	jnz	mrLoop 

	ret			;exit with zero	status

;----------------------------------------------------------------------------
; write - Write sector BIOS entry. Write one sector using the drvNum,
;    trkNum, secNum and dmaAddr specified. 
;
; On Entry
;    drvNum = drive to write
;    trkNum = track to write
;    secNum = sector number to write (0-31)
;    dmaAddr = address of buffer to write from
;
; On Exit
;    If successful
;	sector written to trkBuf from (dmaAddr)
;	A=0, Z flag set true
;    Else
;	A=1, Z flag set false
;    Interrupts enabled
;    Clobbers all
;----------------------------------------------------------------------------
write	call	ckFlush		;flush track buffer if needed
	call	readTrk		;fill track buffer if needed
	jnz	exitDio		;track read error, exit

	call	altSkew		;secNum to hard sector in A
	call	sec2Adr		;HL->sector in trkBuf

	lda	trkNum		;A=track
	ori	80h		;set sync bit
	mov	m,a		;set track in sector
	
	inx	h		;HL->byte after track
	cpi	DATATRK+80h	;on a system or data track?
	jnc	wDatTrk		;data track 6-76

; Create Altair sector for system tracks 0-5

	xra	a		;put 0100h (16 bit) at offset 1,2
	mov	m,a
	inx	h		;HL->offset 2
	inr	a		;A=1
	mov	m,a
	
	inx	h		;HL->128 byte CPM sector in Altair sector
	call	wrtMove		;move (dmaAddr) to sector in trkBuf
	
	mvi	m,0FFh		;offset 131 is stop byte (0FFh)
	
	inx	h		;offset 132 is checksum
	mov	m,b		;store checksum at offset 132
	jmp	wExit		;exit

; wDatTrk- Create Altair sector for tracks 6-76 (mindisk 4-34)

wDatTrk	lda	secNum		;A=sector before Altair skew
	mov	m,a		;store Altair logical sector number
	
	inx	h		;HL->offset 2 in sector
	xra	a		;store zero at offsets 2-6
	mov	m,a		;offset 2
	
	inx	h
	mov	m,a		;zero at offset 3
	
	inx	h
	push	h		;save address of offset 4 = checksum
	
	inx	h
	mov	m,a		;zero at offset 5
	
	inx	h
	mov	m,a		;zero at offset 6
	
	inx	h		;HL->128 byte CPM sector in Altair sector
	call	wrtMove		;move (dmaAddr) to sector in trkBuf

	mvi	m,0FFh		;offset 135 is stop byte (0FFh)
	
	pop	h		;HL->checksum byte in Altair sector
	mov	m,b		;store the checksum
	
; wExit - set dirty flag true, return success status

wExit	mvi	a,0FFh		;set dirty flag true
	sta	bfDirty
	xra	a		;return success status
	ret

;------------------------------------------------------------------------------
; wrtMove - Move sector buffer (128 bytes) from (dmaAddr) to (HL) as part
;   of a CPM write command. Compute checksum on all bytes moved and return
;   the checksum in B.
;
; On Entry
;    HL->destination sector in trkBuf
;    dmaAddr = address of buffer to move from
;
; On Exit
;    128 bytes moved from (dmaAddr) to (HL)
;    HL = HL + 128
;    B = checksum of the 128 bytes moved
;    Clobbers all
;------------------------------------------------------------------------------
wrtMove	xchg			;DE->destination CPM sector in trkBuf
	lhld	dmaAddr		;HL->source buffer
	lxi	b,CSECLEN	;B=checksum (0), C=128 byte count
	
mwLoop	mov	a,m		;move from (HL) to (DE)
	stax	d
	add	b		;add byte to checksum
	mov	b,a
	
	inx	d		;increment both pointers
	inx	h
	dcr	c		;decrement character count
	jnz	mwLoop		;loop until count = 0
	
	xchg			;return with buffer pointer in HL	
	ret
	
;----------------------------------------------------------------------------
; altSkew - Perform Altair skew on the sector number in secNum and return
;    the result in A. The skew is based on the track as:
;
;	Tracks 0-5, secOut = secIn
;	Tracks 6-76, secOut = (secIn * 17) MOD 32
;
;    The skew computation for tracks 6-76 is implemented as:
;	secOut = secIn if secIn is even
;	secOut = secIn XOR 10h if secIn is odd
;
; On Entry
;    trkNum = current track
;    secNum = sector number (0-31)
;
; On Exit
;    A = sector number after Altair skew
;    Clobbers A,B
;----------------------------------------------------------------------------	
altSkew	lda	trkNum		;on a data track?
	cpi	DATATRK
	lda	secNum		;A=unmodified sector number
	rc			;system track, no change to sector
	
	mov	b,a		;save secNum in B
	rrc			;test for even/odd
	mov	a,b		;restore secNum in A
	rnc			;return with secNum if even	
	xri	10h		;else translate as in comments above
	ret

;---------------------------------------------------------------------------
; sec2Adr - Convert hard sector in A to address within trkBuf for
;    the specified sector
;
; On Entry
;    A = Hard sector number
;
; On Exit
;    HL->sector buffer in trkBuf
;    Clobbers A,B,C,H,L
;---------------------------------------------------------------------------
sec2Adr	lxi	h,secAddr  	;HL->sector address table
	mvi	b,0		;form BC=sector*2
	rlc			;A=sector*2 (2 bytes per table entry)
	mov	c,a		;BC=sector*2
	dad	b		;HL->address table entry for passed sector
	
	mov	a,m		;A=lsb of sector buffer address
	inx	h
	mov	h,m		;H=msb of sector buffer address
	mov	l,a		;HL->sector buffer
	ret

;----------------------------------------------------------------------------
; readTrk- read full track into track buffer if the requested 
;    drive (drvNum) or track (trkNum) does not match the buffered
;    drive (bfDrive) or buffered track (bfTrack). The status byte
;    at the start of each sector is set to zero if the sector is
;    good, non-zero if the sector couldn't be read.
;
; On Entry
;    drvNum = drive to read
;    trkNum = track to read
;    bfDrive = drive from which trkBuf was filled
;    bfTrack = track from which trkBuf was filled
;
; On Exit
;    trkNum on drvNum read into trkBuf
;    Zero true if track read or already there, zero false otherwise
;    Clobbers all
;----------------------------------------------------------------------------
readTrk	lhld	bfDrive		;L=buffered drive, H=buffered track
	lda	drvNum		;A=requested drive
	cmp	l		;same drive buffered?
	jnz	rtNew		;drive doesn't match, need a new buffer

	lda	trkNum		;A=requested track
	cmp	h		;same track buffered?
	rz			;yes, already have this buffer

; rtNew - New track needs to be read

rtNew	mvi	a,UNDEF		;invalidate buffered data
	sta	bfDrive
	mvi	a,RDTRIES	;init retry counter
	sta	rtryCnt

rtRetry	lda	drvNum		;A=drive to read
	lxi	h,trkNum	;B=track to read
	mov	b,m
	lxi	h,readCmd	;send read command to server
	call	srvrCmd

	lxi	h,trkBuf	;receive track data into trkBuf
	lxi	d,TRKLEN	;length to read
	call	srvrRcv
	jnz	rtErr		;error	

	lhld	drvNum		;L=drvNum, H=trkNum
	shld	bfDrive		;set the buffered drive and track values
	mov	a,l		;save copy of drive number
	sta	bfDrvSv
	ret			;exit with Z flag true

rtErr	lxi	h,rtryCnt	;else retry
	dcr	m
	jnz	rtRetry

	inr	m		;exit with non-zero error status
	ret

;----------------------------------------------------------------------------
; ckFlush - Check if track buffer should be flushed. This
;    function must be called before any drive selection or seek
;    operation. The buffer is flushed if the bfDirty flag is
;    set and the drive or track number are different than the
;    buffered track.
;
; On Entry
;    Drive still selected and on same track as in trkBuf
;    drvNum, trkNum updated for the new I/O call
;
; On Exit
;    Zero true for no error, zero false if write error occured
;    Clobbers all
;----------------------------------------------------------------------------
ckFlush	lda	bfDirty		;see if track buffer is dirty
	ora	a
	rz			;no, exit with Z set

	lhld	bfDrive		;L=buffered drive, H=buffered track
	lda	drvNum		;A=requested drive number
	cmp	l		;same drive?
	jnz	wrtTrk		;no, flush

	lda	trkNum		;A=requested track number
	cmp	h		;same track?
	rz			;yes, no need to flush

wrtTrk	xra	a		;clear buffer dirty flag
	sta	bfDirty
	mvi	a,WRTRIES	;init retry counter
	sta	rtryCnt

wtRetry	lda	bfDrvSv		;A=buffered data drive number
	lxi	h,bfTrack	;B=buffered data track number
	mov	b,m
	lxi	h,wrtCmd	;send write command to server
	call	srvrCmd

	lxi	h,cmdResp	;receive write response
	lxi	d,CMDLEN
	call	srvrRcv
	jnz	wtErr		;error	

	lda	cmdResp		;verify 'WRIT' received
	cpi	'W'
	jnz	wtErr
	lda	cmdResp+1
	cpi	'R'
	jnz	wtErr

	lda	crCode		;A=response code
	ora	a		;zero = 'OK'
	jnz	wtErr

	lxi	h,trkBuf	;send track buffer to write	
	lxi	d,TRKLEN
	call	srvrSnd

	lxi	h,cmdResp	;receive write response
	lxi	d,CMDLEN
	call	srvrRcv
	jnz	wtErr		;error	

	lda	cmdResp		;verify 'WSTA' received
	cpi	'W'
	jnz	wtErr
	lda	cmdResp+1
	cpi	'S'
	jnz	wtErr

	lda	crCode		;A=response code
	ora	a		;zero = 'OK'
	rz

wtErr	lxi	h,rtryCnt	;decrement the write retry counter
	dcr	m
	jnz	wtRetry		;retry the write

	call	dispMsg
	db	CR,LF,'Delayed Write Error', CR, LF, 0

	inr	a		;dispMsg returns zero
	ret			;exit with non-zero

;------------------------------------------------------------------------------
; invFlush - Invalidate and flush the track buffer.
;    Console input is used as an idle indicator and as a good time
;    to flush a dirty track buffer, so the conIn function calls this
;    subroutine. Even if not flushed, the track buffer is invalidated
;    to force a track read on the next disk I/O request. This helps
;    catch a disk swap.
;
; On Entry:
;    Same drive is on the same track as buffered in trkBuf
;
; On Exit:
;    Track buffer written if required and invalidated.
;    Head unloaded
;    Z set for no error, Z cleared if write error occured.
; Clobbers all except HL
;------------------------------------------------------------------------------
invFlsh	push	h		;preserve h
	lxi	h,bfDrive
	mvi	m,UNDEF		;invalidate the track buffer
	call	ckFlush		;flush the track if needed
	pop	h
	ret

;------------------------------------------------------------------------------
; srvrCmd - Send command pointed to by HL to the serial disk server.
;    Computes and sends the checksum as well.
;
; On Entry:
;    HL->command string to send
;    A=Drive number
;    B=Track number
;
; On Exit:
;
; Clobbers all
;------------------------------------------------------------------------------
srvrCmd	push	h		;preserve command pointer
	rlc			;put drive in upper nibble
	rlc
	rlc
	rlc
	lxi	d,rcDrive-readCmd    ;DE=offset to drive number
	dad	d
	mov	m,a		;store drive number in command

	dcx	h		;move to track number
	mov	m,b		;store track number in command
	
	pop	h		;restore command pointer
	lxi	d,CMDLEN	;DE=length to send
				;fall into srvrSnd

;------------------------------------------------------------------------------
; srvrSnd - Send a data buffer to the serial disk server. Computes and
;    sends the checksum as well.
;
; On Entry:
;    HL points to the buffer to send
;    DE contains the length of the buffer
;
; On Exit:
;
; Clobbers all
;------------------------------------------------------------------------------
srvrSnd	lxi	b,0		;BC=checksum

ssLoop	mov	a,m		;A=byte to send
	add	c		;update checksum LSB
	mov	c,a		
	mvi	a,0
	adc	b		;MSB
	mov	b,a	

	mov	a,m		;A=byte to send
	call	ssByte		;server send byte
	inx	h		;point to next byte
	dcx	d		;decrement byte count
	mov	a,d		;all done?
	ora	e
	jnz	ssLoop		;loop until zero

; Send checksum (2 bytes)

	mov	a,c		;LSB of checksum
	call	ssByte
	mov	a,b		;MSB of checksum
				;fall into ssByte

;-------------------------------------------------------------------
; ssByte - Send a single byte from A to the serial disk server
;-------------------------------------------------------------------
ssByte	push	psw		;preserve char to send
	
ssbLoop	in	COM2LSR		;loop until OK to send
	ani	COMTHRE	
	jz	ssbLoop

	pop	psw		;A=byte to send
	out	COM2DAT
	ret

;------------------------------------------------------------------------------
; srvrRcv - Receive a data buffer from the serial disk server. Computes and
;    verifies the checksum as well.
;
; On Entry:
;    HL points to the buffer to receive
;    DE contains the length of the buffer
;
; On Exit:
;    Zero true if received without error
;    Zero false for timeout or checksum error
; Clobbers all
;------------------------------------------------------------------------------
srvrRcv	lxi	b,0		;compute checksum in BC

srLoop	call	srByte		;get a byte
	rnz			;timeout error
	mov	m,a		;save byte in the buffer

	add	c		;update checksum
	mov	c,a
	mvi	a,0
	adc	b
	mov	b,a

	inx	h		;increment buffer pointer
	dcx	d		;decrement byte counter
	mov	a,d
	ora	e
	jnz	srLoop		;loop until zero

; Receive and compare 16 bit checksum

	call	srByte		;get LSB of checksum
	rnz			;timeout
	cmp	c		;match?
	rnz			;no
		
	call	srByte		;get MSB of checksum
	rnz			;timeout
	cmp	b		;match?
	ret			;return with status

;-------------------------------------------------------------------
; srByte - Receive a byte from the server with 1 second timeout.
;    Returns zero false for timeout, else true.
;-------------------------------------------------------------------
srByte	push	b		;preserve BC
	lxi	b,41667		;1 second (48 cycles, 24us per loop)
	
srbLoop	in	COM2LSR		;(10)
	rrc			;(4)
	jc	srbNew		;(10)

	dcx	b		;(5)
	mov	a,b		;(5)
	ora	c		;(4)
	jnz	srbLoop		;(10)

	pop	b
	inr	a		;zero false for timeout
	ret

srbNew	pop	b		;restore BC
	xra	a		;zero true
	in	COM2DAT		;get and return the byte
	ret

;------------------------------------------------------------------------------
; dispMsg - Display the null-terminated string following the dispMsg call
;
; On Entry SP->message
;
; On Exit
;    Clobbers C,H,L
;------------------------------------------------------------------------------
dispMsg	pop	h		;HL->string

dmLoop	mov	a,m		;A=next character
	inx	h		;bump string pointer
	ora	a		;null terminator?
	jz	dmExit		;yes, exit

	mov	c,a		;conOut needs character in C
	call	conOut		;send the character
	jmp	dmLoop

dmExit	pchl			;return past message string

;---------------------------------------------------------------------------
;  CON device I/O
;---------------------------------------------------------------------------

; conSt - Console status BIOS entry point. Return FFh if character ready,
;    return zero otherwise. 

conSt	mvi	b,SHFTCON	;B=console IOBYTE alignment shift count
	call	doIo		;call the proper I/O routine below

	dw	sio1St		;TTY use 2SIO Port 1
	dw	com1St		;CRT use JAIR port 1
	dw	batchSt		;BAT indirect through RDR logical device
	dw	com2St		;UC1 use JAIR port 2

; conIn - Console input BIOS entry point. Wait for console input and
;    return character in A. Console input is used as an idle indicator
;    and as a good time to flush a dirty track buffer, unload the head, 
;    and invalidate the track buffer.

conIn	call	invFlsh		;invalidate and flush track buffer
	
	mvi	b,SHFTCON	;B=console IOBYTE alignment shift count
	mvi	c,07Fh		;C=AND mask for input byte
	call	doIo		;call the proper I/O routine below

	dw	sio1In		;TTY use 2SIO port 1
	dw	com1In		;CRT use JAIR port 1
	dw	reader		;BAT indirect through RDR logical device
	dw	com2In		;UC1 use JAIR port 2

; conOut - Console output BIOS entry point. Output the character in C.
;   If the sndNull flags is true (i.e., it was determined during cold start
;   that the console is a Teletype), then follow CR with a null.

conOut	call	doConO		;send the character passed in C

	lda	sndNull		;sending null for CR?
	ora	a
	rz			;no, exit
	
	mov	a,c		;was character a CR?
	sui	CR
	rnz			;no, exit
	
	mov	c,a		;put a zero in C and send it

doConO	mvi	b,SHFTCON	;B=console IOBYTE alignment shift count
	call	doIo		;call the proper I/O routine below

	dw	sio1Out		;TTY use 2SIO port 1
	dw	com1Out		;CRT use JAIR port 1
	dw	list		;BAT indirect through LST logical device
	dw	com2Out		;UC1 use JAIR port 2

;---------------------------------------------------------------------------
; RDR device - Reader input character BIOS entry point. Return in A
;---------------------------------------------------------------------------
reader	mvi	b,SHFTRDR	;B=reader IOBYTE alignment shift count
	mvi	c,0FFh		;C=AND mask for input byte
	call	doIo		;call the proper I/O routine below

	dw	sio1In		;TTY use 2SIO port 1
	dw	com1In		;PTR use JAIR port 1
	dw	acrIn		;UR1 use cassette port (SIO 6/7)
	dw	com2In		;UR2 use JAIR port 2 

;---------------------------------------------------------------------------
; PUN device - Punch output character BIOS entry point. Byte to send in C.
;---------------------------------------------------------------------------
punch	mvi	b,SHFTPUN	;B=punch IOBYTE alignment shift count
	call	doIo		;call the proper I/O routine below

	dw	sio1Out		;TTY use 2SIO port 1
	dw	com1Out		;PTP use JAIR port 1
	dw	acrOut		;UP1 use cassette port (SIO 6/7)
	dw	com2Out		;UP2 use JAIR port 2

;---------------------------------------------------------------------------
;  LST device I/O
;---------------------------------------------------------------------------

; listSt - List output test BIOS entry point. Return 0FFh if list device
;    is ready, 0 if not ready

listSt	mvi	b,SHFTLST	;B=list IOBYTE alignment shift count
	call	doIo		;call the proper I/O routine below

	dw	sio1OSt		;TTY use 2SIO port 1
	dw	com1OSt		;CRT use JAIR port 1
	dw	lpcOSt		;LPT use LPC board
	dw	com2OSt		;UL1 use JAIR port 2

; list - List output character BIOS entry point. Send the character
;    passed in C out the list port

list	mvi	b,SHFTLST	;B=list IOBYTE alignment shift count
	call	doIo		;call the proper I/O routine below

	dw	sio1Out		;TTY use 2SIO port 1
	dw	com1Out		;CRT use JAIR port 1
	dw	lpcOut		;LPT use LPC board
	dw	com2Out		;UL1 use JAIR port 2

;---------------------------------------------------------------------------
;  BAT device I/O - The BAT device is assigned as a physical device
;     for CON. However, BAT is actually a logical device that uses
;     whatever RDR is assigned to for input and whatever LST is assigned
;     to for output. The only jump table that does not already exist
;     is the input test routine for the reader devices
;---------------------------------------------------------------------------

; batchSt - BAT device input status

batchSt	mvi	b,SHFTRDR	;BAT in uses RDR device
	call	doIo		;call the proper I/O routine below

	dw	sio1st		;TTY test 2SIO port 1
	dw	com1St		;RDR test JAIR port 1
	dw	acrSt		;UR1 test cassette port (SIO 6/7)
	dw	com2St		;UR2 test JAIR port 2

;---------------------------------------------------------------------------
; doIo - Perform physical I/O device based on the IOBYTE. The value passed
;    in B contains the left-shift count to align the calling device's IOBYTE
;    field into bits 2 and 1 (not 1 and 0). Preserves H,L
;--------------------------------------------------------------------------- 
doIo	lda	IOBYTE		;A=CP/M IO BYTE

ioAlign	rlc			;rotate into bits 2 and 1
	dcr	b
	jnz	ioAlign

	ani	6		;get the 2 bit field alone

; 2 bit field aligned in bits 2 and 1. Index into jump table of caller.

	xthl			;hl=table address from stack, save hl

	mov	e,a		;form DE=table offset
	mvi	d,0
	dad	d		;HL->address in table based on IOBYTE

	mov	e,m		;E=lsb of where to jump
	inx	h
	mov	d,m		;D=msb of where to jump
	xchg			;HL->where to jump

	xthl			;jump address on stack, restore HL
	ret			;jump to address specified in table

;---------------------------------------------------------------------------
; Input status routines
;---------------------------------------------------------------------------

; com1St - Console status routine for JAIR port 1. Return FFh 
;    if character ready, return zero otherwise. 

com1St	in	COM1LSR		;read 2SIO #1 status/control register
	ani	COMDR		;data present?
	rz			;no, return zero

	mvi	a,0FFh		;else, return FF
	ret

; com2St - Console status routine for JAIR port 2. Return FFh 
;    if character ready, return zero otherwise. 

com2St	in	COM2LSR		;read 2SIO #1 status/control register
	ani	COMDR		;data present?
	rz			;no, return zero

	mvi	a,0FFh		;else, return FF
	ret

; sio1St - Console status routine for 2SIO port 1. Return FFh 
;    if character ready, return zero otherwise. 

sio1St	in	SIO1CTL		;read 2SIO #1 status/control register
	ani	SIORDRF		;data present?
	rz			;no, return zero

	mvi	a,0FFh		;else, return FF
	ret

; sio2St - Console status routine for 2SIO port 2. Return 0ff 
;    if character ready, return zero otherwise. 

sio2St	in	SIO2CTL		;read 2SIO #2 status/control register
	ani	SIORDRF		;data present?
	rz			;no, return zero

	mvi	a,0FFh		;else, return FF
	ret

acrSt	in	ACRCTL		;read ACR (SIO) control register
	xri	0FFh		;convert to positive logic
	ani	SIORCV		;data present?
	rz			;no, return zero

	mvi	a,0FFh		;else, return FF
	ret

;---------------------------------------------------------------------------
; Character input routines
;---------------------------------------------------------------------------

; com1In - input character from 1st port on a JAIR board and return in A.
;    C contains AND mask.

com1In	call	com1St		;wait for character
	jz	com1In		;no, loop until data available

	in	COM1DAT		;read the character
	ana	c		;possibly clear msbit
	ret

; com2In - input character from 2nd port on a JAIR board and return in A.
;    C contains AND mask.

com2In	call	com2St		;wait for character
	jz	com2In		;no, loop until data available

	in	COM2DAT		;read the character
	ana	c		;possibly clear msbit
	ret

; sio1In - input character from 1st port on a 2SIO board and return in A.
;    C contains AND mask.

sio1In	call	sio1St		;wait for character
	jz	sio1In		;no, loop until data available

	in	SIO1DAT		;read the character
	ana	c		;possibly clear msbit
	ret

; sio2In - input character from 2nd port on a 2SIO board and return in A
;    C contains AND mask.

sio2In	call	sio2St		;wait for character
	jz	sio2In		;no, loop until data available
	
	in	SIO2DAT		;read the character
	ana	c		;possibly clear msbit
	ret

; acrIn - input character from ACR SIO board at address 6/7

acrIn	call	acrSt		;wait for character
	jz	acrIn		;no, loop until data available
	
	in	ACRDAT		;read the character
	ret

;----------------------------------------------------------------------------
; Output status routines
;----------------------------------------------------------------------------

; com1OSt - Return FFh if JAIR Port #1 is ready, 0 if not ready

com1OSt	in	COM1LSR		;read COM1 line status register
	ani	COMTHRE		;0=busy
	rz			;not ready, return 0

	mvi	a,0FFh		;else, return FF
	ret

; com2OSt - Return FFh if JAIR Port #2 is ready, 0 if not ready

com2OSt	in	COM2LSR		;read COM2 line status register
	ani	COMTHRE		;0=busy
	rz			;not ready, return 0

	mvi	a,0FFh		;else, return FF
	ret

; sio1OSt - Return FFh if 2SIO Port #1 is ready, 0 if not ready

sio1OSt	in	SIO1CTL		;read 2SIO #1 status/control register
	ani	SIOTDRE		;0=busy
	rz			;not ready, return 0

	mvi	a,0FFh		;else, return FF
	ret

; sio2OSt - Return FFh if 2SIO Port #1 is ready, 0 if not ready

sio2OSt	in	SIO2CTL		;read 2SIO #2 status/control register
	ani	SIOTDRE		;0=busy
	rz			;not ready, return 0

	mvi	a,0FFh		;else, return FF
	ret

; lpcOst - Return FFh if 88-LPC is ready, 0 if not ready

lpcOSt	in	LPCCTL		;88-LPC board at port 2,3
	ani	LPCBSY		;0=busy
	rz			;not ready, return 0

	mvi	a,0FFh		;else, return FF
	ret

;---------------------------------------------------------------------------
; Character output routines
;---------------------------------------------------------------------------

; com1Out - Transmit byte through JAIR port 1. Byte to send in C.

com1Out	in	COM1LSR		;read COM1 line status register
	ani	COMTHRE		;transmit data register empty?
	jz	com1Out		;no, wait for next character

	mov	a,c		;get character to xmit
	out	COM1DAT		;send it
	ret

; com1Out - Transmit byte through JAIR port 2. Byte to send in C.

com2Out	in	COM2LSR		;read COM2 line status register
	ani	COMTHRE		;transmit data register empty?
	jz	com2Out		;no, wait for next character

	mov	a,c		;get character to xmit
	out	COM2DAT		;send it
	ret

; sio1Out - Transmit byte through JAIR port 1. Byte to send in C. Detect
;   110 baud teletype during cold start and set sndNull flag true.

sio1Out	lxi	d,0		;init inter-character timer

sio1Wt	in	SIO1CTL		;(10) read 2SIO #1 status/control register
	ani	SIOTDRE		;(7) transmit data register empty?
	jnz	sio1Rdy		;(10) yes, ready for next character

	inx	d		;(5) count 21us tics
	jmp	sio1Wt		;(10) keep waiting for ready

; If still in cold start, then see if the inter-character timer indicates
;    we're connected to a 110 baud Teletype. If so, set the sndNull
;    flag to true

sio1Rdy	lda	coldSt		;A=FF during cold start, 0 otherwise
	ana	d		;A=D during cold start, 0 otherwise
	cpi	11		;if D (MSB of counter) < 11, not 110 baud
	jc	sio1Xmt		;not 110 baud

	sta	sndNull		;otherwise, set send null flag true

; sio1Xmt - send the character in C. 

sio1Xmt	mov	a,c		;get character to xmit
	out	SIO1DAT		;send it
	ret

;---------------------------------------------------------------------------
; sio2Out - Transmit byte through 2SIO port 2. Byte to send in C. Detect
;   110 baud teletype during cold start and set sndNull flag true.

sio2Out	lxi	d,0		;init inter-character timer

sio2Wt	in	SIO2CTL		;read 2SIO #2 status/control register
	ani	SIOTDRE		;transmit data register empty?
	jnz	sio2Rdy		;yes, ready for next character

	inx	d		;count 21us tics
	jmp	sio2Wt		;keep waiting for ready

; if still in cold start, then see if the inter-character timer indicates
;    we're connected to a 110 baud Teletype. If so, set the sndNull
;    flag to true

sio2Rdy	lda	coldSt		;A=FF during cold start, 0 otherwise
	ana	d		;A=D during cold start, 0 otherwise
	cpi	11		;if D (MSB of counter) < 11, not 110 baud
	jc	sio2Xmt		;not 110 baud

	sta	sndNull		;otherwise, set send null flag true

; sio2Xmt - send the character in C. 

sio2Xmt	mov	a,c		;get character to xmit
	out	SIO2DAT		;send it
	ret

;---------------------------------------------------------------------------
; acrOut - Transmit byte through ACR SIO at address 6/7. Byte to send in C.

acrOut	in	ACRCTL		;read ACR (SIO) control register
	ani	SIOXMT		;transmit data register empty?
	jnz	acrOut		;not yet, keep waiting

	mov	a,c		;get character to xmit
	out	ACRDAT		;send it
	ret

;---------------------------------------------------------------------------
; lpcOut - Transmit byte through 88-LPC board.

lpcOut	call	lpcOSt		;wait for printer		
	jz	lpcOut

	mov	a,c
	ani	07Fh		;force bit 7 to zero
	out	LPCDAT		;output the character
	ret

;-----------------------------------------------------------------------------
; serInit - Initialize serial I/O port 0 and IOBYTE
;           Port 1 is initialized in the boot loader
;-----------------------------------------------------------------------------
serInit	mvi	a,COMDLAB
	out	COM1LCR

	mvi	a,COM96		;set COM1 to 9600
	out	COM1DLS
	mvi	a,0
	out	COM1DMS

	mvi	a,COM8BIT	;8N1
	out	COM1LCR

	lda	dIoByte		;initialize IOBYTE with default
	sta	IOBYTE

	ret

;******************************************************************************
;
;   BIOS Data Area
;
;******************************************************************************

;---------------------------------------------------------------------------
; secAddr - Sector address table. Returns sector buffer address within
;    the track buffer when indexed by hard sector number. Each sector
;    requires PSECLEN bytes.
;---------------------------------------------------------------------------
secAddr	dw	trkBuf+00*PSECLEN,trkBuf+01*PSECLEN,trkBuf+02*PSECLEN
	dw	trkBuf+03*PSECLEN,trkBuf+04*PSECLEN,trkBuf+05*PSECLEN
	dw	trkBuf+06*PSECLEN,trkBuf+07*PSECLEN,trkBuf+08*PSECLEN
	dw	trkBuf+09*PSECLEN,trkBuf+10*PSECLEN,trkBuf+11*PSECLEN
	dw	trkBuf+12*PSECLEN,trkBuf+13*PSECLEN,trkBuf+14*PSECLEN
	dw	trkBuf+15*PSECLEN,trkBuf+16*PSECLEN,trkBuf+17*PSECLEN
	dw	trkBuf+18*PSECLEN,trkBuf+19*PSECLEN,trkBuf+20*PSECLEN
	dw	trkBuf+21*PSECLEN,trkBuf+22*PSECLEN,trkBuf+23*PSECLEN
	dw	trkBuf+24*PSECLEN,trkBuf+25*PSECLEN,trkBuf+26*PSECLEN
	dw	trkBuf+27*PSECLEN,trkBuf+28*PSECLEN,trkBuf+29*PSECLEN
	dw	trkBuf+30*PSECLEN,trkBuf+31*PSECLEN
	
;-----------------------------------------------------------------------------
; dpHead - disk parameter header for each drive
;-----------------------------------------------------------------------------
dpHead	dw	tranTbl,0,0,0,dirBuf,dpb,csv0,alv0
	dw	tranTbl,0,0,0,dirBuf,dpb,csv1,alv1
	dw	tranTbl,0,0,0,dirBuf,dpb,csv2,alv2
	dw	tranTbl,0,0,0,dirBuf,dpb,csv3,alv3

;-----------------------------------------------------------------------------
; dpb - disk parameter block. This table gives a 2K block size and
;   64 directory entries. 
;-----------------------------------------------------------------------------
dpb	dw	NUMSEC		;sectors per track
	db	BSH		;allocation block shift factor (BSH)
	db	BLM		;data location block mask (BLM)
	db	EXM		;extent mask (EXM)
	dw	DSM		;maximum block number (149)	
	dw	DRM		;maximum directory entry number (63)
	db	AL0,AL1		;AL0, AL1 
	dw	CKS		;CKS=(DRM+1)/4
	dw	RESTRK		;reserved tracks for CPM and bootloader

tranTbl	db	01,09,17,25,03,11,19,27,05,13,21,29,07,15,23,31
	db	02,10,18,26,04,12,20,28,06,14,22,30,08,16,24,32

;----------------------------------------------------------------------------
; Initialized data
;----------------------------------------------------------------------------
readCmd	db	'READ'		;read command to server
rcTrack	db	0
rcDrive	db	0
rcLen	dw	TRKLEN
CMDLEN	equ	$-readCmd

wrtCmd	db	'WRIT'		;write command to server
wcTrack	db	0
wcDrive	db	0
wcLen	dw	TRKLEN

coldSt	db	0FFh		;FF during cold start, 0 otherwise

bfDirty	db	0		;non-zero if buffer has been written to
bfDrive	db	UNDEF		;drive currently in track buffer
bfTrack	db	UNDEF		;currently buffered track (MUST follow bfDrive)

;----------------------------------------------------------------------------
; Non-initialized data
;----------------------------------------------------------------------------
bfDrvSv	ds	1		;saved drive number that is currently buffered
drvNum	ds	1		;drive number from CP/M call
trkNum	ds	1		;track number from CP/M call (MUST follow drvNum)
secNum	ds	1		;sector number from CP/M call
dmaAddr	ds	2		;dma address for disk operations from CP/M call
rtryCnt	ds	1		;disk I/O retry counter

cmdResp	ds	4		;server command response buffer
crCode	ds	2		;response code
crData	ds	2		;response data

;-----------------------------------------------------------------------------
;  Disk scratchpad areas defined in the DPH table
;-----------------------------------------------------------------------------
dirBuf	ds	128		;bdos directory scratchpad
alv0	ds	(DSM/8 + 1)	;allocation vector storage
csv0	ds	CKS		;change disk scratchpad
alv1	ds	(DSM/8 + 1)
csv1	ds	CKS
alv2	ds	(DSM/8 + 1)
csv2	ds	CKS
alv3	ds	(DSM/8 + 1)
csv3	ds	CKS

;-----------------------------------------------------------------------------
; Track buffer
;-----------------------------------------------------------------------------
trkBuf	ds	NUMSEC*PSECLEN

ACTLEN	equ	$-BIOSBAS	;actual length of the BIOS

	end











