;****************************************************************************
;
; PROM boot loader for Altair CP/M using virtual Altair 8" floppy drives
;    served through JAIR COM2 serial port.
;
;    This code loads sectors 0 and 2 of track 0, which contains the CP/M
;    loader, into RAM at address zero and then jumps to it.
;
;    Version History
;
;    Ver     Date	  Description
;    ---   ---------	---------------------
;    1.0   10/28/23	Original, Mike Douglas
;    1.1   11/26/23	Clear out possible left over bytes from UART before
;			starting a read operation from the disk server.
;    1.1J  05/27/24     Modified for JAIR
;
;****************************************************************************

PROMADR	equ	0FC00h

; 8" floppy equates

NUMSEC	equ	32		;sectors per track
PSECLEN	equ	137		;physical sector length
CSECLEN	equ	128		;CP/M sector length
TRKLEN	equ	NUMSEC*PSECLEN
SYSDATA	equ	3		;offset of 128 byte data payload in sector

;-----------------------------
; JAIR Serial Ports
;-----------------------------
COM1	equ	20h		;COM1 base port address
COM1DAT	equ	COM1		;1st port on JAIR board - data register
COM1LCR	equ	COM1 + 3	;COM1 - line control register
COM1MCR	equ	COM1 + 4	;COM1 - modem control register
COM1LSR	equ	COM1 + 5	;COM1 - line status register
COM1MSR	equ	COM1 + 6	;COM1 - modem status register
COM1DLS	equ	COM1		;COM1 - divisor latch (LS)
COM1DMS	equ	COM1 + 1	;COM1 - divisor latch (MS)
COM2	equ	28h		;COM2 base port address
COM2DAT	equ	COM2		;2nd port on JAIR board - data register
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
BAUD	equ	COM384		;set COM2 baud rate

;--------------------------------------------------------------------------
;  Entry point
;--------------------------------------------------------------------------
	org	PROMADR

start	di			;disable interrupts
	lxi	sp,STACK	;init stack pointer

	mvi	a,COMDLAB
	out	COM1LCR
	out	COM2LCR

	mvi	a,COM96		;set COM1 to 9.6K baud rate
	out	COM1DLS
	mvi	a,BAUD		;set COM2 to baud rate
	out	COM2DLS
	mvi	a,0
	out	COM1DMS
	out	COM2DMS

	mvi	a,COM8BIT	;8N1
	out	COM1LCR
	out	COM2LCR

; Load sector 0 and 2 of track 0 into RAM starting at address zero

load	call	srb3ms		;discard received bytes until 3ms passes
	jz	load		;   with no data received

	call	readTrk		;read the track
	jnz	load		;error
	
	lxi	h,TRKBUF+SYSDATA   ;source pointer (sector 0)
	lxi	d,0		;destination pointer
	call	movSec		;move 128 bytes to run location

	lxi	h,TRKBUF+(2*PSECLEN)+SYSDATA   ;source pointer (sector 2)
	call	movSec		;move 128 bytes to run location

	jmp	0		;execute boot loader

;--------------------------------------------------------------------------
; movSec - Move 128 byte sector from TRKBUF to RAM
;
; On Entry
;    HL->data portion of sector in TRKBUF
;    DE->where to put sector
;
; On Exit
;    HL and DE point to next sector
; Clobbers B,D,E,H,L
;----------------------------------------------------------------------------
movSec	mvi	b,CSECLEN	;B=count of bytes to move

msLoop	mov	a,m		;move sector from TRKBUF to run location
	stax	d
	inx	h		;increment pointers
	inx	d
	dcr	b		;loop count
	jnz	msLoop

	ret

;----------------------------------------------------------------------------
; readTrk- read full track into track buffer
;
; On Entry
;    trkNum = track to read
;
; On Exit
;    track read into TRKBUF
;    Clobbers all
;----------------------------------------------------------------------------
readTrk	lxi	h,readCmd	;send read command to server
	mvi	b,CMDLEN	;B=count of bytes to send

waitSnd	in	COM2LSR		;loop until OK to send
	ani	COMTHRE
	jz	waitSnd

	mov	a,m		;A=byte to send
	out	COM2DAT		;send it

	inx	h		;point to next byte
	dcr	b		;decrement byte count
	jnz	waitSnd		;loop until command is sent

	lxi	h,TRKBUF	;receive track data into TRKBUF
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
;    Returns zero false for timeout, else true.
;
; srb3ms does the same thing but with a 3ms timeout
;-------------------------------------------------------------------
srb3ms	push	b		;popped later, so must push
	lxi	b,125		;3ms timeout
	jmp	srbLoop

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

;---------------------------------------------------------------------------
; Data Area
;---------------------------------------------------------------------------
CSUMVAL	equ	'R'+'E'+'A'+'D'+(TRKLEN/256)+(TRKLEN AND 0FFh)

readCmd	db	'READ'		;read command to server
trkNum	db	0		;track number to read
drvNum	db	0
readLen	dw	TRKLEN
chkSum	dw	CSUMVAL
CMDLEN	equ	$-readCmd

STACK	equ	0200h		;stack grows down from here
TRKBUF	equ	STACK		;track buffer above stack

	end
