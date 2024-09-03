
; I2JR-1.ASM - Josh's Altair/IMSAIR Replacement (JAIR) for IMP - 09/03/24
;
;		USES 8250 I/O (with baudrate generator)
;
; You will want to look this file over carefully. There are a number of
; options that you can use to configure the program to suit your taste.
; This file adapts the North Star Horizon (no baudrate generator) to IMP.
;
; Edit this file for your preferences then follow the "TO USE:" example
; shown below.
;
; Many terminals will clear the screen with a CTL-Z.  If yours does, put
; a 1AH at CLEAR: (010AH).  Many terminals use two characters, the first
; normally an ESC.  For example, ESC *.  In this case put '*' at CLEAR:
; (The ESC will automatically be typed with no CTL-character present.)
; If you don't know what your terminal uses, put a 0 at CLEAR: and IMP
; will scroll up 24 blank lines to clear the CRT for things like MENU,
; looking at the function key table, typing CTL-Z in command mode, etc.
;
; Use the "SET" command to change the baudrate when desired.  The value
; at MSPEED controls the baudrate when the program is first called up.
;
;	TO USE: First edit this file filling in answers for your own
;		equipment.  Then assemble with ASM.COM or equivalent
;		assembler.  Then use MLOAD to merge into the main file:
;
;		MLOAD IMP.COM=IMP.COM,I2JR-1.HEX
;
; =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =
;
; 09/03/24  Added support for 19.2K, 38.4K, and 57.6K
;           baud rates.                         - Patrick Linstruth
; 06/01/87  Improved the GOODBYE routine, added BREAK routine, needs
;	    IMP245 to use it.			- Irv Hoff
;
; 10/27/85  Minor changes			- Irv Hoff
; 09/03/85  Written to work with IMP		- Irv Hoff
;
; =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =   =
;
;
YES	EQU	0FFH
NO	EQU	0
;
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
COM8N1	equ	03h		;8N1
COMSBRK	equ	40h		;Set Break
COM110	equ	1047		;110 baud rate
COM300	equ	384		;300 baud rate
COM1200	equ	96		;1200 baud rate
COM2400	equ	48		;2400 baud rate
COM9600	equ	12		;9600 baud rate
COM192K	equ	6		;19.2K baud rate
COM384K	equ	3		;38.4K baud rate
COM576K	equ	2		;57.6K baud rate
;
;
;-----------------------------------------------------------------------
;
ESC	EQU	'['-40H	; ^[ = Escape
BELL	EQU	'G'-40H	; ^G = Bell character
LF	EQU	'J'-40H	; ^J = Linefeed
NEXTRY	EQU	'K'-40H	; ^K = Try next phone number, abort this try
CR	EQU	'M'-40H	; ^M = Carriage return
CLEARSC	EQU	'Z'-40H	; ^Z = Clears screen, command mode only
EOFCHAR	EQU	'Z'-40H	; ^Z = End of file
;
;
;-----------------------------------------------------------------------
;
;
	ORG	0100H
;
;
	DS	3		; Skip the data area below
;
;
; These routines and equates are at the beginning of the program so
; they can be patched by a monitor or overlay file without re-assembling
; the program.
;
MSPEED:	 DB	8	; 0=110 1=300 2=450 3=600 4=710 5=1200		103H
			; 6=2400 7=4800 8=9600 9=19200 default
HS2400:	 DB	NO	; Yes=2400 bps highest speed			104H
HS1200:	 DB	NO	; Yes=1200 bps highest speed			105H
RACAL:	 DB	NO	; Yes=Racal-Vadic 1200V or 2400V or 2400PA	106H
PROMODM: DB	NO	; Yes=Prometheus ProModem 1200 bps		107H
RESVD1:	 DB	NO	; Reserved for special modems			108H
RESVD2:	 DB	NO	; Reserved for special modems			109H
;
;
CLEAR:	 DB	1AH	; Clear screen character (ESC not needed)	10AH
CLOCK:	 DB	37	; Clock speed in MHz x10, 25.5 MHz max. 	10BH
			; 20=2 MHh, 37=3.68 MHz, 40=4 MHz, etc.
BYTDLY:	 DB	2	; 0=0 delay  1=10ms  5=50 ms - 9=90 ms		10CH
			;   default time to send character in ter-
			;   minal mode file transfer for slow BBS
CRDLY:	 DB	2	; 0=0 delay 1=100 ms 5=500 ms - 9=900 ms	10DH
			;   default time for extra wait after CRLF
			;   in terminal mode file transfer
NOFCOL:	 DB	5	; Number of directory columns shown		10EH
TCHPUL:	 DB	'T'	; T=tone, P=Pulse (Hayes 2400 modems)		10FH
;.....
;
;
ADDLFD:	 DB	NO	; Yes=add LF after CR to send file in terminal	110H
			;   mode (normally added by remote echo)
CONVRUB: DB	YES	; Yes=convert rub to backspace			111H
CRCDFLT: DB	YES	; Yes=default to CRC checking			112H
IGNRCTL: DB	YES	; Yes=CTL-chars above ^M not displayed		113H
;.....
;
;
EXTCHR:	 DB	'['-40H	; ESC = preceeds local control character	114H
EXITCHR: DB	'E'	; Exit character				115H
FILESND: DB	'F'	; Send file when in terminal mode		116H
NOCONCT: DB	'N'	; Disconnect from phone line			117H
LOGCHR:	 DB	'L'	; Send logon					118H
LSTCHR:	 DB	'P'	; Toggle printer				119H
UNSAVCH: DB	'R'	; Close input text buffer			11AH
SAVECHR: DB	'Y'	; Open input text buffer			11BH
CLEARS:	 DB	'Z'	; Clears screen, terminal mode			11CH
BRKCHR:	 DB	'Q'	; Send a break tone				11DH
NODTR:	 DB	NO	; YES if no DTR and need ATH0 to disconnect	11EH
;.....
;
;
; Handles in/out ports for data and status
;
I$MDCTL1: IN	COM2LSR		;					11FH
	  RET			; IN modem control port 		121H
	  DB	0,0,0,0,0,0,0	; Spares if needed			122H
;
I$MDTXE:  IN	COM2LSR		; (Needed for SIO or DART register 1	129H
	  RET			;					12BH
	  DB	0,0,0,0,0,0,0	;					12CH
;
I$MDDATP: IN	COM2DAT		;					133H
	  RET			;					139H
	  DB	0,0,0,0,0,0,0	; Spares if needed			13AH
;
O$MDDATP: OUT	COM2DAT		;					13DH
	  RET			; OUT modem data port			13FH
	  DB	0,0,0,0,0,0,0	; Spares if needed			140H
;.....
;
;
A$MDRCV:  ANI	COMDR		;					147H
	  RET			;					149H
;
C$MDRCV:  CPI	COMDR		;					14AH
	  RET			;					14CH
;
A$MDSND:  ANI	COMTHRE		;					14DH
	  RET			;					14FH
;
C$MDSND:  CPI	COMTHRE		;					150H
	  RET			;					152H
;
A$MDTXE:  ANI	COMTHRE		;					153H
	  RET			;					155H
;
C$MDTXE:  CPI	COMTHRE		;					156H
	  RET			;					158H
;.....
;
;
; Special exit vector, used by some computers to reset interrupt vectors
;
J$EXITVEC:RET			;					159H
	  DB	0,0		;					15AH
;.....
;
;
; Jump vectors needed by each overlay
;
J$GOODBYE:JMP	GOODBYE		; Disconnects modem by dropping DTR	15CH
J$INITMOD:JMP	INITMOD		; Initializes modem, autosets baudrate	15FH
J$STUPR:  JMP	STUPR		; SET routine to change baudrate	162H
J$SYSVR:  JMP	SYSVR		; Signon message			165H
;.....
;
;
; "AT" command strings, can be replaced in individual overlay if needed
;
J$STRNGA: DS	3		; 1200 bps "AT" string			168H
J$STRNG1: DS	3		; 2400 bps "AT" string			16BH
;
;
; Next fourteen lines should not be changed by user overlay as these go
; to specific locations in the main program, not in the overlay.
;
;
J$CMDSPL: DS	3		; Allows entry of baudrate on CMD line	16EH
J$CRLF:	  DS	3		; Turns up one new line on display	171H
J$DIAL:	  DS	3		; Start of dialing routine		174H
J$DSCONT: DS	3		; Terminates modem use			177H
J$GOLST:  DS	3		; Printer routine, needed by Apple //e	17AH
J$ILPRT:  DS	3		; Prints an inline string, 0 to end	17DH
J$INBUF:  DS	3		; Stores a keybd string for comparison	180H
J$INLNCP: DS	3		; Inline "compare strings" routine	183H
J$INMDM:  DS	3		; Max .1 sec wait for modem character	186H
J$RCVRSP: DS	3		; For 3801 I/O use (TV-803)		189H
J$SNDCHR: DS	3		; Sends a character to the modem	18CH
J$SNDSTR: DS	3		; Sends a string to the modem, $ to end 18FH
J$TIMER:  DS	3		; .1 second timer (amount in 'B' reg.)	192H
J$BREAK:  JMP	SENDBRK		; Break routine 			195H
J$NEW2:	  DB	0,0,0		; For future needs			198H
;.....
;
;
; For 2400 bps auto-stepdown units
;
MANUAL:	  DB	0		; For manual selection flag		19BH
J$300:	  JMP	OK300		; Sets baudrate to 300 baud		19CH
J$1200:	  JMP	OK1200		; Sets baudrate to 1200 bps		19FH
J$2400:	  JMP	OK2400		; Sets baudrate to 2400 bps		1A2H
;.....
;
;
LOGPTR:	  DW	LOGON		; Pointer to display LOGON message	1A5H
;
SYSVR:	  CALL	J$ILPRT		; Display the following line		1A7H
	  DB	'Version for JAIR COM2 port 28H'		;	1AAH
	  DB	CR,LF,0
	  RET
;.....
;
;
;-----------------------------------------------------------------------
;
; NOTE:  You can change the SYSVER message to be longer or shorter.  The
;	 end of your last routine should terminate by 0400H (601 bytes
;	 available after start of SYSVER).
;
;-----------------------------------------------------------------------
;
; You can put in a message at this location which can be called up with
; (special character-L).  You can put in several lines.  End with a 0.
;
LOGON:	DB	'This is a JAIR computer...'
	DB	CR,LF,0
;
;-----------------------------------------------------------------------
;
; This routine sets a 300 ms break tone
;
SENDBRK:
	JMP	GBBRK
;.....
;
;
; This routine sets DTR low for 300 ms to disonnect the phone
;
GOODBYE:
	MVI	A,COMRTS	; turn off DTR
	OUT	COM2MCR		; Send to status port

GBBRK:	MVI	A,(COMSBRK+COM8N1)
	OUT	COM2LCR

	MVI	B,3		; Delay 300 ms to hang up phone
	CALL	J$TIMER

	MVI	A,COM8N1	; Clear break
	OUT	COM2LCR

	MVI	A,(COMDTR + COMRTS)
	OUT	COM2MCR

	RET
;.....
;
;
; Sets 8250 to 8 bits, DTR and RTS
;
INITMOD:
	LDA	MSPEED		; Get the selected value
	CPI	0		; 110 bps
	JZ	OK110
	CPI	1		; 300 bps
	JZ	OK300
	CPI	5		; 1200 bps
	JZ	OK1200
	CPI	8		; 9600 bps
	JZ	OK9600
	CPI	9		; 19.2K bps
	JZ	OK192K
	CPI	10		; 38.4K bps
	JZ	OK192K
	CPI	11		; 57.6K bps
	JZ	OK192K
	JMP	STUPR1		; Else ask what is wanted
;.....
;
;
STUPR:	CALL	J$CMDSPL	; Gives us CMDBUF+6
	JNC	STUPR2
;
STUPR1:	CALL	J$ILPRT
	DB	'Input Baud Rate (110, 300, 1200, 2400, 9600, '
	DB	'19200, 38400, 57600): ',0
	LXI	D,BAUDBUF	; Point to new input buffer
	CALL	J$INBUF
	CALL	J$CRLF
	LXI	D,BAUDBUF+2
;
STUPR2:	CALL	J$INLNCP	; Compare BAUDBUF+2 with chars. below
	DB	'110',0
	JNC	OK110		; Go if got match
	CALL	J$INLNCP
	DB	'300',0
	JNC	OK300		; Go if got match
	CALL	J$INLNCP
	DB	'1200',0
	JNC	OK1200		; Go if got match
	CALL	J$INLNCP
	DB	'2400',0
	JNC	OK2400		; Go if got match
	CALL	J$INLNCP
	DB	'9600',0
	JNC	OK9600		; Go if got match
	CALL	J$INLNCP
	DB	'19200',0	; Go if got match
	JNC	OK192K
	CALL	J$INLNCP
	DB	'38400',0	; Go if got match
	JNC	OK384K
	CALL	J$INLNCP
	DB	'57600',0	; Go if got match
	JNC	OK576K
	CALL	J$ILPRT		; All matches failed, tell operator
	DB	'++ Incorrect entry ++',CR,LF,BELL,CR,LF,0
	JMP	STUPR1		; Try again
;
OK110:	MVI	A,0		; MSPEED 110 baud value
	LXI	H,BD110		; Get 110 baud parameters in 'HL'
	JMP	LOADBD		; Go load them
;
OK300:	MVI	A,1
	LXI	H,BD300
	JMP	LOADBD
;
OK1200:	MVI	A,5
	LXI	H,BD1200
	JMP	LOADBD
;
OK2400:	MVI	A,6
	LXI	H,BD2400
	JMP	LOADBD
;
OK9600:	MVI	A,8
	LXI	H,BD9600
	JMP	LOADBD
;
OK192K:	MVI	A,9
	LXI	H,BD192K
	JMP	LOADBD
;
OK384K:	MVI	A,10
	LXI	H,BD384K
	JMP	LOADBD
;
OK576K:	MVI	A,11
	LXI	H,BD576K
	JMP	LOADBD
;
LOADBD:	STA	MSPEED		; Change time-to-send to match baudrate

	MVI	A,COMDLAB	; 8250 DLAB
	OUT	COM2LCR

	MOV	A,L		; Divisor Latch (LS)
	OUT	COM2DLS
	MOV	A,H		; Divisor Latch (MS)
	OUT	COM2DMS

	MVI	A,COM8N1	; 8N1 and Clear DLAB
	OUT	COM2LCR

	MVI	A,(COMDTR+COMRTS)
	OUT	COM2MCR

	IN	COM2DAT		; Clear data port
	XRA	A		; Clear the input

	RET
;.....
;
;
; Table of baudrate parameters
;
BD110	EQU	COM110		; 110 baud
BD300	EQU	COM300		; 300 baud
BD1200	EQU	COM1200		; 1200 bps
BD2400	EQU	COM2400		; 1200 bps
BD9600	EQU	COM9600		; 9600 bps
BD192K	EQU	COM192K		; 19.2K bps
BD384K	EQU	COM384K		; 38.4K bps
BD576K	EQU	COM576K		; 57.6K bps
;
BAUDBUF:DB	10,0,0,0,0,0
	DB	0,0,0,0,0,0
;
;			       end
;-----------------------------------------------------------------------
;
; NOTE: Must terminate by 0400H
;
	END

