e****************************************************************************
;
;  CP/M cold boot loader for Altair CP/M using virtual Altair 8" floppy
;    drives served through the JAIR second serial port.
;
;    This code is loaded from sectors 0 and 2 into RAM by the disk boot
;    loader PROM. This loader, in turn, loads the CP/M image into RAM.
;
;    Version History
;
;    Ver     Date	  Description
;    ---   ---------	---------------------
;    1.0   10/29/23	Modified for JAIR, Patrick Linstruth
;
;    Original version for 2SIO written by Mike Douglas
;
;--------------------------------------------------------------------------
;
;    To patch changes made to this loader into a CP/M image saved from
;    MOVCPM2S (e.g., CPMxx.COM), use the following commands:
;
;	A>DDT CPMxx.COM
;	-IBOOT.HEX
;	-R900
;       -M980,9FF,A00	(splits code onto sectors 0 and 2)
;	-G0	    	(Go zero, not "oh")
;	A>SYSGEN
;
;****************************************************************************

MEMSIZE	equ	56		;set memory size in K bytes

; 8" floppy equates

NUMSEC	equ	32		;sectors per track
PSECLEN	equ	137		;physical sector length
CSECLEN	equ	128		;CP/M sector length
TRKLEN	equ	NUMSEC*PSECLEN
SYSDATA	equ	3		;offset of 128 byte data payload in sector
STRTSEC	equ	3		;starting sector of CP/M image on track 0

; CP/M size & locations

CCPLEN	equ	0800h		;CPM 2.2 fixed length
BDOSLEN	equ	0E00h		;CPM 2.2 fixed length
BIOSLEN	equ	1800h		;length of BIOS for 8" floppy

CCPBASE	equ	MEMSIZE*1024 - BIOSLEN - BDOSLEN - CCPLEN
BIOSBAS	equ	(CCPBASE+CCPLEN+BDOSLEN) ;base address of this BIOS

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
COM96 	equ	12		;9.6K baud rate
COM192	equ	6		;19.2K baud rate
COM384	equ	3		;38.4K baud rate
COM576	equ	2		;57.6K baud rate

;--------------------------------------------------------------------------
;  Entry point
;--------------------------------------------------------------------------
	org	0

start	di			;disable interrupts
	lxi	sp,CCPBASE	;stack grows down from lowest CPM address

	mvi	a,COMDLAB
	out	COM1LCR
	out	COM2LCR

	mvi	a,COM96		;set COM1 to 9.6K baud rate
	out	COM1DLS
	mvi	a,COM576	;set COM2 to 38.4K baud rate
	out	COM2DLS
	mvi	a,0
	out	COM1DMS
	out	COM2DMS

	mvi	a,COM8BIT	;8N1
	out	COM1LCR
	out	COM2LCR

; Display banner

	lxi	h,banner

sndBanr	in	COM1LSR		;send banner
	ani	COMTHRE
	jz	sndBanr

	mov	a,m
	ora	a
	jz	load

	out	COM1DAT
	
	inx	h
	jmp	sndBanr

; Load and move 1st track

load	xra	a		;track 0
	sta	trkNum
	mvi	a,CSUMVAL AND 0FFh  ;re-init checksum
	sta	chkSum
	call	readTrk		;read the track
	jnz	load		;error

	lxi	h,trkBuf+(STRTSEC*PSECLEN)+SYSDATA   ;source pointer
	lxi	d,CCPBASE	;DE->where to put CP/M
	mvi	c,NUMSEC-3	;sector count to move

secLp1	call	movSec		;move 128 bytes to run location
	dcr	c		;decrement sector count		
	jnz	secLp1

; Load and move second track

	lxi	h,trkNum	;move to track 1
	inr	m
	lxi	h,chkSum	;update checksum
	inr	m
	call	readTrk		;read second track
	jnz	load		;error
	
	lxi	h,trkBuf+SYSDATA   ;source pointer
	lxi	d,CCPBASE+CSECLEN*(NUMSEC-3)	;dest pointer
	mvi	c,NUMSEC	;sector count to move

secLp2	call	movSec		;move 128 bytes to run location
	dcr	c		;decrement sector count		
	jnz	secLp2

	jmp	BIOSBAS		;jump to BIOS cold start

;--------------------------------------------------------------------------
; movSec - Move 128 byte sector from trkBuf to RAM
;
; On Entry
;    HL->data portion of sector in trkBuf
;    DE->where to put sector
;
; On Exit
;    HL and DE point to next sector 
; Clobbers B,D,E,H,L
;----------------------------------------------------------------------------
movSec	mvi	b,CSECLEN	;B=count of bytes to move

msLoop	mov	a,m		;move sector from trkBuf to run location
	stax	d
	inx	h		;increment pointers
	inx	d
	dcr	b		;loop count
	jnz	msLoop
 	
	push	b		;increment source pointer
	lxi	b,PSECLEN-CSECLEN
	dad	b
	pop	b
	ret

;----------------------------------------------------------------------------
; readTrk- read full track into track buffer
;
; On Entry
;    trkNum = track to read
;
; On Exit
;    track read into trkBuf
;    Clobbers all
;----------------------------------------------------------------------------
readTrk	lxi	h,readCmd	;send read command to server
	mvi	b,CMDLEN	;B=count of bytes to send
	mvi	a,'.'		;send '.' on console
	out	COM1DAT

waitSnd	in	COM2LSR		;loop until OK to send
	ani	COMTHRE	
	jz	waitSnd

	mov	a,m		;A=byte to send
	out	COM2DAT		;send it

	inx	h		;point to next byte
	dcr	b		;decrement byte count
	jnz	waitSnd		;loop until command is sent

	lxi	h,trkBuf	;receive track data into trkBuf
	lxi	d,TRKLEN	;DE=length to read
	lxi	b,0		;BC=checksum

rtLoop	call	srByte		;get a byte
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
	jnz	rtLoop		;loop until zero

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
;    Returns not zero for timeout, else zero.
;-------------------------------------------------------------------
srByte	push	b		;preserve BC
	lxi	b,65000		;1 second (48 cycles, 24us per loop)
	
srbLoop	in	COM2LSR		;(10)
	rrc			;(4)
	jc	srbNew		;(10)

	dcx	b		;(5)
	mov	a,b		;(5)
	ora	c		;(4)
	jnz	srbLoop		;(10)

	out	255

	pop	b
	inr	a		;zero false for timeout
	ret

srbNew	pop	b		;restore BC

	xra	a		;zero true
	in	COM2DAT		;get and return the byte
	ret

;---------------------------------------------------------------------------
; Data Area
;---------------------------------------------------------------------------
CSUMVAL	equ	'R'+'E'+'A'+'D'+(TRKLEN/256)+(TRKLEN AND 0FFh)

banner	db	'JAIR Serial Server Boot Loader',0
readCmd	db	'READ'		;read command to server
trkNum	db	0		;track number to read
drvNum	db	0
readLen	dw	TRKLEN
chkSum	dw	CSUMVAL
CMDLEN	equ	$-readCmd

trkBuf	equ	$		;track buffer

	end
