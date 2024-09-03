
VERSION	EQU	245	; IMP (05/22/87)  -	CP/M-80 MODEM PROGRAM
;
;-----------------------------------------------------------------------
;  o  05/22/87  Added BREAK tone routine, added BRKCHR:, J$BREAK and
;		SENDBRK: routines in each overlay, added a JZ SBREAK
;		to the main program if ESC-BRKCHR is typed, added the
;		STPCHR: and SBREAK: routines to the main program and
;		changed the DONETD: and BYEBYE: routines in main pgm.
;  o  02/07/87  Changed routine for sending batch header, constructs
;		the header BEFORE looking for a 'C' from remote, also
;		uses conventional "GTACK" routine, saving bytes.
;  o  02/04/87  Increased some "RECV" times for PC Pursuit satelite
;		networks, added a few manual abort calls, rewrote the
;		'JZ  CKCAN'  to  'CALL  CKCAN'.
;  o  01/12/87  Added 'TIG' option to toggle IGNORCTL on/off.  (For
;		David Cortesi).
;  o		Now shows file name being received or sent.
;-----------------------------------------------------------------------
; 
	ASEG		; Needed for M80, disregard error if using MAC
;
;
;     NOTE:  This program is written in Intel 8080 code.
;	     It assembles with ASM, LASM, MAC or M80 and
;	     will operate on 8080/8085 or Z80 computers.
;
;		COPYRIGHTED 1985,1987 BY IRVIN M. HOFF
;
; THIS TELEPHONE MODEM PROGRAM USES THE CHRISTENSEN PROTOCOL.  IT HAS
; BOTH 'CRC' AND CHECKSUM CAPABILITY FOR ERROR-DETECTION. IT SUPPORTS
; DIALING AND AUTO-REDIALING FOR 2400 BPS MODEMS USING THE HAYES PRO-
; TOCOL, AS WELL AS THE RACAL-VADIC 2400V, WITH ITS SUPERIOR PROGRESS
; REPORTING RESULT CODES.
;
;***********************************************************************
;
;	   THIS PROGRAM IS COPYRIGHTED. IT MAY BE DISTRIBUTED 
;          WITH NO PREVIOUS WRITTEN PERMISSION WITH THE 
;          UNDERSTANDING THAÔ NO FINANCIAL GAIN WILL RESULT 
;          FROM SUCH TRANSACTION.
;
;***********************************************************************
;
;   GENERAL INTEREST:  When transferring files modem-to-modem, the batch
;   mode is extremely useful.  It allows automatic transmission of nu-
;   merous files while the operator at the receiving end does virtually
;   nothing.  It can be used for single files or with wildcards.  With
;   normal single program transfer, the receiving end switches from CRC
;   to checksum in one minute and times out completely in 120 seconds.
;   (In batch mode it times out in 3 minutes for receive.)  This offers
;   ample opportunity to transfer programs between individuals.
;
;	  I2NM-1.ASM can be used to change the telephone overlay numbers
;	     and/or set the alternate dialing system code (also used toŠ;	     change SAVSIZ, mentioned below.)  It can also be used for
;	     intially setting (or changing) any of the function key as-
;	     signments.
;
;	  I2LIB.COM  can be used to very easily and very quickly change
;	     any of the telephone overlay numbers.
;
;	  I2FUNC.COM can be used to quickly and easily change any of the
;	     10 function key assignments (or the function key intercept
;	     character itself, which is currently the '^' character.
;
;	Significant address changes now used:
;
;	   0BFFH  -  SAVSIZ  20 = 4k file transfer buffer size
;			     40 = 8k file transfer buffer size
;			     80 = 16k file transfer buffer size
;	   0C00H  -  NUMBLIB (start of telephone number library)
;
;***********************************************************************
;
;	In past years many people have contributed ideas for modem pro-
;	grams that I have adapted for use in the IMP2 series.  The list
;	below includes as many of those as I can recall.
;
;	     Ward Christensen, Jim Mills, Mark Zeigler, Keith Petersen,
;	     Paul Kelly, Bruce Ratoff, John Mahr, Rich Berg, Bob Clyne,
;	     Bill Earnest, Paul Hansknecht, Ron Fowler, Fred Viles, Bob
;	     Plouffe, Ben Bronson, Sigi Kluger, Frank Gaude' and likely
;	     others.
;					- Irv Hoff W6FFC
;
;***********************************************************************
;
; 05/22/87  Improved the GOODBYE routine, added BREAK routine, needs
;   v245    IMP245 to use it.			- Irv Hoff
;	
; 09/22/86  Eliminated converting a '/' to '_' in batch mode.  If send-
;   v245    ing a file that already exists in batch mode, KMD22 sends an
;	    EOT which in turns displays a "File exists..." line in IMP
;	    and then aborts.  Now accepts "CALL" in addition to "CAL" in
;	    dial mode.			- Irv Hoff
;  
; 10/01/85  Fixed SMRESUL5 so autodial works normally with the Anchor
;   v244    modems.  Fixed DONETD to call J$DSCONT if using modems with
;	    no DTR for disconnect.  (Set byte 011EH to other than 00 in
;	    that case.)  SPDMSG now goes 0-36 ms for delay between char-
;	    acters when sending ASCII files in terminal mode instead of
;	    only 0-9 ms (needed by Osborne OS-1, etc.)  File length now
;	    stored at end of header in hex rather than ASCII, saved 53
;	    bytes.  Batch receive shows file name, length in records and
;	    'k' and time to receive.  (Same feature added to KMD07 - no
;	    longer shows file length at all, with earlier versions of
;	    KMD.)  Fixed STDRV to permit using area 1, which it had pre-
;	    viously ignored - although it allowed selecting all other
;	    user areas.			- Irv Hoff
;
; 09/07/85  Found the one of the flags was not being reset after a batch
;   v243    file was received.  This would prevent subsequent files from
;	    being received if the initial 'C' was garbled.  (This goes
;	    clear back to when CRC was added to MODEM7 in October 1981,
;	    that flag was never reset for batch receive.)  Also removed
;	    a  "CALL  DSCONCT"  which slowed disconneting with ESC-N
;	    or DSC.			- Irv Hoff
;
; 08/27/85  The YAM receive routine did not properly handle filenames
;   v242    with 8 characters and no extent.  Our system of storing file
;	    length turned them into read-only files to which you could
;	    not write.  Other minor changes.
;					- Irv Hoff
;
; 08/20/85  Added YAM batch mode.  Use the command: TBM to select MODEM7
;   v241    batch mode if preferred.  Uses some routines adapted from
;	    work done by Dennis Vallianos.
;					- Irv Hoff
;
; 07/17/85  First version of IMP2, adapted from MDM740.  Supports 2400
;   v240    bps modems using auto-stepdown Racal-Vadic 2400V protocol or
;	    Hayes 2400 protocol.  Companion overlays start with I2, such
;	    as I2DP-1.ASM for the 8251 with CTC implemented into this
;	    version.  These overlays only work with IMP2.
;					- Irv Hoff
;
;***********************************************************************
;
; 05/07/84  Numerous small bugs fixed that have apparently been present
;  MDM740   since MODEM7 days.	Copyright notice added when the program
;	    is brought up, to be legal.  Auto-linking added which gives
;	    the ability to automatically redial a sequential list up to
;	    32 numbers.  Two options:
;
;			B>>COMMAND:  A,F,4,G,Z
;						  or
;			B>>COMMAND:  A/F/4/G/Z
;
;	    The '/' beeps just once when connected and then jumps auto-
;	    matically to the terminal mode to catch any signon messages
;	    from IBM or Unix systems, etc.  The first option beeps con-
;	    tinuously until the operator hits any key.	This places the
;	    program in the terminal mode.  These two options combine to
;	    make MDM740 one of the most useful modem programs currently
;	    available for dialing busy numbers.
;					- Irv Hoff
;
; 01/01/83  First version.  Can be assembled with ASM.COM.  (Previously
;  MDM700   it was necessary to have the MODEM7.LIB file and use MAC.COM
;	    to assemble the program.)  Selected MDM700 as a new program
;	    to allow me to make changes that I felt might be beneficial.
;	    This would not hinder others from updating existing programs
;	    to their own satisfaction.	The name was also selected so it
;	    would fit on databanks limiting file names to 6 characters.
;					- Irv Hoff
;
;***********************************************************************
;
;
YES	EQU	0FFH	; Use in DB options, MVI  A,YES (8 bit values)
NO	EQU	0	;  "   "  "    "      "   "  "	 "  "	 "
TRUE	EQU	0FFFFH	; Use in all EQUs for conditionals (16 bits)
FALSE	EQU	0	;  "   "  "   "    "  "    "	     "	 "
;
;
; Values shown are for a 8251A I/O
;
PORT	EQU	28H	; Your base port (data or status)
MDCTL1	EQU	PORT+1	; Modem control port
MDDATP	EQU	PORT	; Modem data port
MDRCV	EQU	02H	; Modem receive ready
MDSND	EQU	01H	; Modem send ready bit
MDTXE	EQU	05H	; Modem send buffer empty, holding buffer empty
;
BDPORTR	EQU	20H	; CTC port for receive baudrate
BDPORTS	EQU	1AH	; CTC port for transmit baudrate
;
MDMODE	EQU	82H	; Insures 8251A I/O is out of mode with DTR high
MDRSET	EQU	42H	; Resets USART for additional commands
MDSET1	EQU	4EH	; 1 stop bit, no parity, 8 bits, x16
MDSET2	EQU	0CEH	; 2 stop bits, no parity, 8 bits, x16
MDCOM	EQU	17H	; Reset error flags, RCV, DTR, TX ready
;
;
;-----------------------------------------------------------------------
;
;
BUFSIZ	EQU	16	; Buffer size in Kbytes for ASCII capture to disk
			; (16k is one file extent)
XFRSIZ	EQU	16	; File transfer buffer in Kbytes.  Do not make
			; Any larger than BUFSIZ.  16k works fine on
			;   all but very slowest floppy systems
STOPBIT	EQU	FALSE	; Yes, if using 2 stop bits, no if using 1
;
BDNMCH	EQU	75H	; Bad name match
ERRLIM	EQU	10	; Maximum allowable consecutive errors
ERRCRC	EQU	6	; CRC tries, then switches to CHECKSUM
LIBLEN	EQU	34	; Length of each phone library entry
RUB	EQU	7FH	; Rub
STRSPD	EQU	3CH	; MSPEED location in low ram
CRC	EQU	'C'	; Requests 'CRC' instead of 'CKSUM'
KSND	EQU	'K'	; Requests 1k blocks
ESC	EQU	'['-40H	; ^[ = Escape
SOH	EQU	'A'-40H	; ^A = Start of header
STX	EQU	'B'-40H	; ^B = Start of text (for 1k blocks)
EOT	EQU	'D'-40H	; ^D = End of text
ACK	EQU	'F'-40H	; ^F = Acknowledge
OKNMCH	EQU	'F'-40H	; ^F = Ok name match
BELL	EQU	'G'-40H	; ^G = Bell character
BKSP	EQU	'H'-40H	; ^H = Backspace
LF	EQU	'J'-40H	; ^J = Linefeed
NEXTRY	EQU	'K'-40H	; ^K = Try next phone number, abort this try
CR	EQU	'M'-40H	; ^M = Carriage return
XON	EQU	'Q'-40H	; ^Q = XON character
XOFF	EQU	'S'-40H	; ^S = XOFF character
NAK	EQU	'U'-40H	; ^U = Not acknowledge
CANCEL	EQU	'X'-40H	; ^X = Cancel send or receive
CLEARSC	EQU	'Z'-40H	; ^Z = Clears screen, command mode
EOFCHAR	EQU	'Z'-40H	; ^Z = End of file
;
;
;-----------------------------------------------------------------------
;
;
	ORG	0100H
;
;
	JMP	START		; Skip the data area below
;
;
; These routines and equates are at the beginning of the program so
; they can be patched by a monitor or overlay file without re-assembling
; the program.
;
MSPEED:	 DB	6	; 0=110 1=300 2=450 3=600 4=710 5=1200		103H
			; 6=2400 7=4800 8=9600 9=19200 default
HS2400:	 DB	YES	; Yes=2400 bps highest speed			104H
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
TCHPUL:	 DB	'T'	; T=tone, P=Pulse ('AT' protocol only)		10FH
;.....
;
;
ADDLFD:	 DB	NO	; Yes=add LF after CR to send file in terminal	110H
			;   mode (normally added by remote echo)
CONVRUB: DB	YES	; Yes=convert rub to backspace			111H
CRCDFLT: DB	YES	; Yes=default to CRC checking			112H
IGNRCTL: DB	NO	; Yes=CTL-chars above ^M not displayed		113H
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
NODTR:	 DB	0	; For future development			11EH
;.....
;
;
; Handles in/out ports for data and status
;
I$MDCTL1: IN	MDCTL1		;					11FH
	  RET			; IN modem control port 		121H
	  DB	0,0,0,0,0,0,0	; Spares if needed			122H
;
I$MDTXE:  IN	MDCTL1		; (Needed for SIO or DART register 1	129H
	  RET			;					12BH
	  DB	0,0,0,0,0,0,0	;					12CH
;
I$MDDATP: MVI	A,MDCOM		;					133H
	  OUT	MDCTL1		;					135H
	  IN	MDDATP		;					147H
	  RET			;					139H
	  DB	0,0,0		; Spares if needed			13AH
;
O$MDDATP: OUT	MDDATP		;					13DH
	  RET			; OUT modem data port			13FH
	  DB	0,0,0,0,0,0,0	; Spares if needed			140H
;
A$MDRCV:  ANI	MDRCV		;					147H
	  RET			;					149H
;
C$MDRCV:  CPI	MDRCV		;					14AH
	  RET			;					14CH
;
A$MDSND:  ANI	MDSND		;					14DH
	  RET			;					14FH
;
C$MDSND:  CPI	MDSND		;					150H
	  RET			;					152H
;
A$MDTXE:  ANI	MDTXE		;					153H
	  RET			;					155H
;
C$MDTXE:  CPI	MDTXE		;					156H
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
J$STRNGA: JMP	STRNGA		; 1200 bps "AT" string			168H
J$STRNG1: JMP	STRNG1		; 2400 bps "AT" string			16BH
;
;
; Next fourteen lines should not be changed by user overlay as these go
; to specific locations in the main program, not in the overlay.
;
;
J$CMDSPL: JMP	CMDSPL		; Allows entry of baudrate on CMD line	16EH
J$CRLF:	  JMP	CRLF		; Turns up one new line on display	171H
J$DIAL:	  JMP	DIAL1		; Start of dialing routine		174H
J$DSCONT: JMP	DSCONT		; Terminates modem use			177H
J$GOLST:  JMP	GOLST		; Printer routine, needed by Apple //e	17AH
J$ILPRT:  JMP	ILPRT		; Prints an inline string, 0 to end	17DH
J$INBUF:  JMP	INBUF		; Stores a keybd string for comparison	180H
J$INLNCP: JMP	INLNCP		; Inline "compare strings" routine	183H
J$INMDM:  JMP	INMDM		; Max .1 sec wait for modem character	186H
J$RCVRSP: JMP	RCVRSP		; For 3801 I/O use (TV-803)		189H
J$SNDCHR: JMP	SNDCHR		; Sends a character to the modem	18CH
J$SNDSTR: JMP	SNDSTR		; Sends a string to the modem, $ to end 18FH
J$TIMER:  JMP	TIMER		; .1 second timer (amount in 'B' reg.)	192H
J$BREAK:  JMP	SENDBRK		; Break routine				195H
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
	  DB	'Version for Datapoint 1560 modem port 28H' ;		1AAH
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
;
LOGON:	DB	'              - Irv Hoff (W6FFC) '
	DB	'Los Altos Hills, CA 94022',CR,LF,0
;
;=======================================================================
;
; This routine sends a 300 ms break tone to the modem
;
SENDBRK:
	MVI	A,3FH		; DTR normal, send break tone
	JMP	GOODBYE+2
;.....
;
;
; This routine sets DTR low for 300 ms to disonnect the phone
;
GOODBYE:
	MVI	A,3DH		; Send break, turn off DTR
	OUT	MDCTL1		; Send to status port
	MVI	B,3		; Delay 300 ms to hang up phone
	CALL	J$TIMER
	MVI	A,MDCOM		; Normal send/receive with DTR
	OUT	MDCTL1		; Send to status port
	RET
;.....
;
;
; Sets 8251 to 8 bits, DTR, RCV and TX ready
;
INITMOD:
	MVI	A,MDMODE	; Insure 8251 is out of mode
	OUT	MDCTL1
	XTHL			; Small delay to complete command
	XTHL
	MVI	A,MDRSET	; Reset the 8251A for new command
	OUT	MDCTL1
	XTHL			; Small delay to complete command
	XTHL
	MVI	A,MDSET1	; Set stop pulse, no parity 8 bits, x16
	OUT	MDCTL1
	XTHL			; Small delay to complete command
	XTHL
	MVI	A,MDCOM		; Error reset, RCV, DTR, TX ready
	OUT	MDCTL1
	XTHL			; Small delay to complete command
	XTHL
;
	LDA	MSPEED		; Get the selected value
	CPI	1		; 300 bps
	JZ	OK300
	CPI	5		; 1200 bps
	JZ	OK1200
	CPI	6		; 2400 bps
	JZ	OK2400
	CPI	8		; 9600 bps
	JZ	OK9600
	JMP	STUPR1		; Else ask what is wanted
;.....
;
;
STUPR:	CALL	J$CMDSPL	; Gives us CMDBUF+6
	JNC	STUPR2
;
STUPR1:	CALL	J$ILPRT
	DB	'Input Baud Rate (300, 1200, 2400, 9600): ',0
	LXI	D,BAUDBUF	; Point to new input buffer
	CALL	J$INBUF
	CALL	J$CRLF
	LXI	D,BAUDBUF+2
;
STUPR2:	CALL	J$INLNCP	; Compare BAUDBUF+2 with chars. below
	DB	'300',0
	JNC	OK300		; Go if got match
	CALL	J$INLNCP
	DB	'1200',0
	JNC	OK1200
	CALL	J$INLNCP
	DB	'2400',0
	JNC	OK2400
	CALL	J$INLNCP
	DB	'9600',0
	JNC	OK9600
	CALL	J$ILPRT		; All matches failed, tell operator
	DB	'++ Incorrect entry ++',CR,LF,BELL,CR,LF,0
	JMP	STUPR1		; Try again
;
OK300:	MVI	A,1		; MSPEED 300 baud value
	MVI	B,BD300		; Get 300 baud parameters in 'HL'
	JMP	LOADBD		; Go load them
;
OK1200:	MVI	A,5
	MVI	B,BD1200
	JMP	LOADBD
;
OK2400:	XRA	A
	STA	MANUAL		; Reset to maximum auto-speed
	MVI	A,6
	MVI	B,BD2400
	JMP	LOADBD
;
OK9600:	MVI	A,8
	MVI	B,BD9600
;
LOADBD:	STA	MSPEED		; Change time-to-send to match baudrate
	MVI	A,47H		; CTC command word
	OUT	BDPORTR		; Give to both Tx and Rx sections
	OUT	BDPORTS
	MOV	A,B		; Get baudrate byte
	OUT	BDPORTR		; Give to both Tx and Rx sections
	OUT	BDPORTS
	RET
;.....
;
;
; Table of baudrate parameters
;
BD300	EQU	20H		; 9600/300  converted to hex value
BD1200	EQU	08H		; 9600/1200
BD2400	EQU	04H		; 9600/2400
BD9600	EQU	01H		; 9600/9600
;
BAUDBUF:DB	10,0,0,0,0,0
	DB	0,0,0,0,0,0
;
;			       end
;=======================================================================
;
;		 RACAL-VADIC/HAYES DIALING ROUTINES
;
;=======================================================================
;
;
	ORG	400H
;
;
; Dialing routine
;
DIAL1:	XRA	A
	STA	AUTODIR		; Zero the direct to terminal mode flag
	STA	AUTOFL		; Zero the auto-linking flag
	STA	CRFLAG		; Zero the continuous dial flag
	LXI	H,0
	SHLD	DIALCT		; Zero the dial count
	LXI	H,CMDBUF+1	; Point to the number of characters in..
	MOV	A,M		; The buffer, then get the number
	CPI	3+1		; Anything typed after 'CAL'?
	JC	DIAL2		; If not, go through library routine
;
;
; If there were only 3 characters, then "CAL<RET>" was typed -- the user
; obviously expecting to get a phone number (or letter) from the library
; file.  If 4 or more, a number (or letter) was typed in from the menu
; command line, so move the characters down 4 to compensate.  Needed for
; auto-redialing of menu command line entries.
;
	MOV	C,A		; Put into the 'C' reg.
	MVI	B,0		; Will move original number down 4
	SUI	4		; Eliminate the 'CAL' portion
	MOV	M,A		; Store new count at CMDBUF+1
	INX	H		; CMDBUF+2 (first character of string)
	XCHG			; 'DE' now has CMDBUF+2
	LXI	H,CMDBUF+6	; Point to number (or letter) to dial
	CALL	MOVER		; Move the group down 4 places
	JMP	DIAL4		; Check if library number, then dial
;...
;
;
; Comes here if no phone number was manually entered after 'CAL' and if
; no phone library code was entered.  Displays the phone number library
; then asks for an entry.
;
DIAL2:	MVI	C,18		; Number of lines to move
	LXI	H,NUMBLIB	; Start of phone number library
	LXI	D,BUFFER	; Buffer add. to store them temporarily
	CALL	NEWLINE		; Start with CR/LF
	STAX	D		; +LF
	INX	D		; And bump it
;
DIAL3:	MVI	B,LIBLEN	; Number of bytes to move
	CALL	MOVE		; Move to buffer
	CALL	SPACES		; 2 entries + 3 spaces = 71 characters
	PUSH	H		; Save source address
	PUSH	D		; Save destination address
	LXI	D,(17*LIBLEN)	; Get offset of 17 times entry length
	DAD	D		; Add it to source address
	POP	D		; Restore destination address
	MVI	B,LIBLEN	; Get length of library entry
	CALL	MOVE		; Move another entry
	POP	H		; Restore source address
	CALL	NEWLINE
	DCR	C		; One less line to print
	JNZ	DIAL3		; If not zero, print another
	MVI	A,'$'		; BDOS print routine terminate character
	STAX	D		; Store in buffer
	CALL	CLRTST
	MVI	C,PRINT
	LXI	D,BUFFER	; Print the library on the CRT
	CALL	BDOS
	CALL	J$ILPRT		; Ask which one is wanted
	DB	CR,LF,'Enter library code or phone number,',CR,LF
	DB	'Hit RET to abort this function now or',CR,LF
	DB	'CTL-X quits while dialing or ringing: ',0
	LXI	D,CMDBUF
	CALL	J$INBUF
;
;
; You now have either a library code or a manually entered phone num-
; ber.	These either came from the menu command line or from the library
; command line.  Next we see if a code, if so, get the corresponding
; line with phone number from the library.  If a number greater than
; one digit, we ignore the library look-up.  (Ringback numbers must end
; with letter 'R'.)
;
DIAL4:	LXI	H,CMDBUF+1	; Number of characters in buffer
	MOV	A,M
	ORA	A		; Null means CR was typed
	JZ	DIALEXIT	; Abort dialing, return to menu
	STA	NUMBER
	LDA	CMDBUF+3	; See if at least two characters entered
	CPI	'/'		; Slash for linking, direct to terminal..
	CZ	AUTO		; Mode on answer
	CPI	','		; Comma used for linking
	CZ	AUTO1		; If yes, set it up for auto-linking
;
;
; Wait until now to initialize the modem in case they only wanted to see
; a number in the library.
;
	CALL	SMIN1		; Initialize the modem
;
;
; Check to see how many characters were typed.	If more than one, then
; it was a hand-entered phone number, so exit.
;
DIAL5:	XRA	A
	STA	ANSWFL		; Clear the answer flag, just in case
	LDA	AUTOFL		; Auto-link flag set?
	ORA	A
	JNZ	AUTO2		; If yes exit
	LDA	NUMBER		; Number of characters in buffer
	STA	CMDBUF+1	; Reset the character count, if needed
	CPI	1+1		; More than one character?
	JNC	DIAL14		; If more than one, hand-entered number
	LXI	H,CMDBUF+2	; First character in phone number line
;
;
; If just one character entered, see if a (A-Z) letter
;
DIAL6:	MOV	A,M
	MVI	B,'A'		; First letter of alphabet
	MVI	E,0		; Counts number of letters to match
	MVI	C,26		; Number of letters in alphabet
;
DIAL7:	CMP	B		; Letter from table?
	JZ	DIAL9		; If yes, get phone number, else
	INR	B		; Make next letter (A-Z)
	INR	E		; Count up
	DCR	C		; Count down
	JNZ	DIAL7		; Try next one in (A-Z) table
;
;
; If not (A-Z) then should be (0-9)
;
	MVI	B,'0'		; First digit to check
	MVI	E,26		; Point past alpha codes
	MVI	C,10		; Number of digits in table
;
DIAL8:	CMP	B		; Number from table?
	JZ	DIAL9		; If yes, go dial, else
	INR	B		; Make next digit to compare
	INR	E		; Make next table line number
	DCR	C		; Count down - loop counter
	JNZ	DIAL8		; Loop
	JMP	DIALBAD		; Error if not a number or a letter
;
;
; Now have a match between the requested code and one in the library.
; E-reg. holds the library line number (1-36) that matches the requested
; code (A-Z or 0-9).
;
DIAL9:	LXI	H,NUMBLIB	; Phone number library
	LXI	B,LIBLEN	; Length of library entry
	MOV	A,E		; Number of times to library length to HL
	ORA	A		; Set flags
	JZ	DIAL11
;
DIAL10:	MOV	A,M		; Get first char of selected lib entry
	ORA	A		; Set flags
	JZ	DIALBAD		; Send bad library msg and abort
	DAD	B		; Increment 'HL' by library length
	DCR	E		; Countdown
	JNZ	DIAL10		; Not there yet, loop
;
;
; Now have the line in the phone number library matching the requested
; letter so store that line starting at 'CMDBUF+1'
;
DIAL11:	MVI	B,LIBLEN	; Number of characters to get from table
	LXI	D,CMDBUF+1	; Point to buffer
	XCHG			; 'HL' points to CMDBUF+1
	MOV	M,B		; Length of each table entry
	XCHG			; Restore the registers
	INX	D		; Point to first char position in buffer
	CALL	MOVE		; Move the table entry to the buffer
;
;
; Now have the full line including phone number in 'CMDBUF' area.  Scan
; past the descriptive portion of library entry - terminate scan at the
; first '.'  This allows commas and numbers to be part of the text, such
; as:
;	     'A=DataTech, Node 7..1-408-238-9621'
;
DIAL12:	LXI	H,CMDBUF+1
	MOV	E,M		; Number of chars in buffer
	INX	H		; Point to 1st character in buffer
;
DIAL13:	MOV	A,M		; Get next character
	CALL	TYPE		; Show it
	INX	H		; Bump pointer
	DCR	E		; Decrement count
	JZ	DIALEXIT	; Exit if no '.' (bad library entry)
	CPI	'.'		; Dot?
	JZ	DIAL15		; Yes, go dial the phone
	JMP	DIAL13		; No, loop for next character
;.....
;
;
; There is a user entered phone number in 'CMDBUF' area
;
DIAL14:	LXI	H,CMDBUF+1	; Get the number of characters in buffer
	MOV	A,M
	MOV	E,M
	INX	H		; Point to 1st character to dial
;.....
;
;
; Loop to dial the phone number pointed to by 'HL', character count in
; the 'E' register.  First, set the modem to auto-dial mode.
;
DIAL15:	PUSH	H
	CALL	SMIN2		; Put modem in dialing mode
	POP	H

DIAL16:	MOV	A,M		; Get first number from the buffer
	ORA	A		; Set flags
	JZ	DIALBAD		; Bad number if a null
;
;
; Dial a digit, check keyboard for abort
;
	CALL	DIALA		; Dial a digit, show on CRT
	CALL	STAT		; Key depressed?
	JZ	DIAL18		; If not, exit
	CALL	KEYIN		; See what it was
	CPI	CANCEL		; CTL-X to abort?
	JZ	DIAL17		; If yes, exit
	MOV	B,A		; Save the character momentarily
	LDA	EXTCHR		; Want to abort?
	CMP	B
	JNZ	DIAL18
;
DIAL17:	MVI	B,CR		; Terminate the dialing if needed
	CALL	J$SNDCHR
	JMP	DIALEXIT	; Back to command mode
;
DIAL18:	INX	H		; Bump pointer
	DCR	E		; One less character to go
	JNZ	DIAL16		; If not done, send the next digit
	MVI	B,CR		; Modem needs a CR to enter the number
	CALL	J$SNDCHR
	CALL	CATCH		; Catch the numbers the modem echoes
	CALL	J$ILPRT
	DB	' - try #',0
	LHLD	DIALCT		; Increment the dial count
	INX	H
	SHLD	DIALCT
	CALL	DECOUT		; Show number of attempts so far
	MVI	A,' '		; Extra space to position cursor
	CALL	TYPE
	CALL	CATCH		; Catch any output from the modem
	JMP	SMRESULT	; Number sent to modem, now get results
;
;
; Connection not made, see if a redial is desired
;
DIALAGN:
	LXI	SP,STACK	; Reset the stack to normal just in case
	XRA	A
	STA	RINGFL		; Reset the ring flag
	LDA	CRFLAG		; Continuous redial flag
	ORA	A
	JNZ	DIALAGN1	; If already set, go dial again
	CALL	J$ILPRT		; See if we should keep trying
	DB	CR,LF,CR,LF
	DB	'     Redial? (C/Y/N): ',BELL,0
	CALL	KBDCHR
	PUSH	PSW		; Save the answer
	CALL	CRLF		; Turn up a line
	POP	PSW		; Get the answer back
	CPI	'Y'		; Redial?
	JZ	DIALAGN1	; Yes, redial
	CPI	'C'		; Continuous redial?
	JNZ	DIALEXIT1	; None of these, quit
	MVI	A,1
	STA	CRFLAG		; Continuous redial flag
;
DIALAGN1:
	CALL	CRLF		; Start a new line
	JMP	DIAL5		; Redial entry point
;.....
;
;
; Connection has been made
;
CONMADE:
	CALL	J$ILPRT
	DB	BELL,CR,LF,CR,LF,'     CONNECTED',0
	LDA	AUTODIR		; Going direct to terminal mode?
	ORA	A
	JNZ	RETRN
	LDA	CRFLAG		; Continuous redial or first time try?
	ORA	A
	JZ	RETRN		; Go to terminal mode if first time
	CALL	J$ILPRT
	DB	' - any key for terminal mode ',0
;
CONMADE1:
	MVI	E,10
;
CONMADE2:
	CALL	STAT		; Keypress?
	JZ	CONMADE3	; Exit if no keys pressed
	CALL	KEYIN
	XRA	A
	JMP	RETRN		; Key pressed, go to terminal mode
;
CONMADE3:
	MVI	B,1		; Wait 0.1 second
	CALL	J$TIMER
	DCR	E		; One less loop to make
	JNZ	CONMADE2	; See if a keyboard character yet
	MVI	A,BELL		; Sound a bell
	CALL	TYPE
	JMP	CONMADE1	; Reset the counter
;.....
;
;
; Automatic dialing routine, prints the number being dialed.
;
DIALA:	CALL	TYPE		; Print whatever character, dashes, etc.
	MOV	B,A		; Store the character for now
	CALL	DIALAD		; Check for alternate dialing like 'MCI'
	MOV	A,B		; Get the original character back
;
DIALA1:	CPI	'*'		; * is a valid dial digit
	JZ	DIALA2
	CPI	'#'		; # is a valid dial digit
	JZ	DIALA2
	CPI	','		; Pause for all modems
	JZ	DIALA2
	CPI	'K'		; K = Racal-Vadic dial tone wait
	JZ	DIALA2
	CPI	'T'		; T = Tone dial request
	JZ	DIALA2
	CPI	'W'		; W = Hayes or Robotics dial tone wait
	JZ	DIALA2
	CPI	'0'		; Digits are (0-9)
	RC			; Exit if less than ASCII '0'
	CPI	'9'+1
	RNC			; Exit if more than ASCII '9'
;
;
; Sends the digit to the modem.  Waits 100 ms. after each digit to in-
; sure it gets to the modem ok.
;
DIALA2:	CALL	J$SNDCHR	; Go send it
	JMP	J$INMDM		; Get the echo character and ignore
;.....
;
;
; Print bad library number message and abort if a null is encountered.
;
DIALBAD:
	CALL	J$ILPRT
	DB	CR,LF,CR,LF,'++ Bad library number called ++',CR,LF,0
;
DIALEXIT:
	CALL	CRLF
;
DIALEXIT1:
	LXI	SP,STACK	; Make sure the stack is normal again
	CALL	SMIN4		; Reset the modem
	XRA	A
	STA	CRFLAG		; Reset the continuous redial flag
	JMP	MENU
;.....
;
;
; Do any alternate dialing such as 'MCI' or 'SPRINT'
;
DIALAD:	LDA	TCHPUL		; Using touch tone dialing?
	CPI	'T'
	RNZ			; If not, ignore
	MOV	A,B		; Get the character back
	CPI	'<'		; Alternate dialing system #1 (MCI?)
	JNZ	DIALAD1		; If not, exit
	PUSH	H		; Save the current values
	LXI	H,ALTDL1	; Alternate dialing area
	JMP	DIALAD2
;
DIALAD1:CPI	'>'		; Alternate dialing system #2 (Sprint?)
	RNZ			; If neither, exit
	PUSH	H		; Save the current values
	LXI	H,ALTDL2
;
DIALAD2:MOV	A,M
	CPI	'$'		; Ready to terminate?
	JZ	DIALAD3		; If yes, exit
	CALL	TYPE		; Display the character
	MOV	B,A		; Need the char. in 'B' to send to modem
	CALL	DIALA1		; Send proper characters to the modem
	INX	H		; Next location
	CALL	QUIT		; Want to quit dialing?
	JMP	DIALAD2		; If not, handle the next character
;
DIALAD3:MVI	A,' '
	MOV	B,A		; Clears 'B' from last digit sent
	CALL	TYPE		; Separate from the main number
	POP	H		; Restore the location
	RET
;.....
;
;
; Disconnect the autodial modem from the phone line.  Sends 'I, CR' to
; the Racal-Vadic to return to IDLE mode
;
;
DSCONT:	LDA	RACAL
	ORA	A
	JNZ	SMIN3		; Reset modem to normal
;
	MVI	B,15		; 1 second pause
	CALL	J$TIMER
	LXI	H,STRNG5	; Get into command mode
	CALL	J$SNDSTR
	MVI	B,15		; Another 1 second pause
	CALL	J$TIMER
	JMP	SMIN3		; Reset modem to normal
;.....
;
;
; Want to quit dialing?
;
QUIT:	CALL	STAT		; Keypress?
	RZ			; If not, do the next character
	CALL	KEYIN		; Yes, go get it
	CPI	CANCEL		; CTL-X?
	JZ	QUIT1		; Yes, quit dialing
	MOV	B,A
	LDA	EXTCHR
	CMP	B
	MOV	A,B		; Get the character back again
	JZ	QUIT1
	CPI	NEXTRY		; Special "dial next number" character
	RNZ			; None of these, proceed normally
	MVI	B,CR
	CALL	J$SNDCHR	; Send to modem to stop dialing
	MVI	B,10		; Wait one second for new dial tone
	CALL	J$TIMER		; Let it abort any busy, dialing, etc.
	POP	H
	JMP	DIALAGN
;
QUIT1:	POP	H		; Reset stack for "CALL QUIT"
	JMP	DIALEXIT	; Terminate
;.....
;
;
; Insure the modem has completed its reply
;
CATCH:	CALL	J$INMDM		; Catch any output from the modem
	JNC	CATCH		; If you got one, see if any more
	RET			; Returns if no character in 100 ms.
;.....
;
;
; Clear the result buffer for slower 300 speed combined results
;
EMPTY:	MVI	B,80
	LXI	H,TBUF		; TBUF area is not currently used
;
EMPTY1:	MVI	M,' '
	INX	H
	DCR	B
	JNZ	EMPTY1
	RET
;.....
;
;
; Initializaton
;
SMIN1:	LDA	MANUAL		; Manually selected 'SET' speed?
	ORA	A
	JNZ	SMIN11		; Exit if set for manual selection
;
	LDA	HS2400		; High speed 2400 bps?
	ORA	A
	CNZ	J$2400		; If yes, set to 2400 bps
;
	LDA	HS1200		; High speed 1200 bps?
	ORA	A
	CNZ	J$1200		; If yes, set to 1200 speed
;
SMIN11:	CALL	RATE		; Show current baudrate
	CALL	CRLF		; Turn up an extra line
;
SMIN12:	LXI	H,RTRNG1	; Set to auto-answer
	LDA	RACAL		; Using the Racal-Vadic protocol?
	ORA	A
	JNZ	J$SNDSTR	; If yes, use RTRNG1
;
	LHLD	J$STRNG1+1
	LDA	HS2400		; High speed 2400 bps?
	ORA	A
	JNZ	J$SNDSTR	; If yes, modify basic "AT" string
;
	LHLD	J$STRNGA+1	; Else must be "AT" protocol
	CALL	J$SNDSTR	; Send basic "AT" string
;
	LDA	PROMODM		; Using a 1200 bps Prometheus ProModem?
	ORA	A
	RZ			; If not, finished
	LXI	H,STRNGP	; If yes, send special ProModem string
	JMP	J$SNDSTR
;.....
;
;
SMIN2:	LXI	H,RTRNG2	; Set to disable auto-answer
	LDA	RACAL
	ORA	A
	JNZ	J$SNDSTR
;
	LDA	TCHPUL		; Touch or pulse dialing for autodial?
	STA	STRNG2+3	; Store
	LXI	H,STRNG2
	JMP	J$SNDSTR
;.....
;
;
SMIN3:	LXI	H,RTRNG3
	LDA	RACAL
	ORA	A
	JNZ	J$SNDSTR
;
	LXI	H,STRNG3
	CALL	J$SNDSTR
;
SMIN4:	LXI	H,RTRNG3
	LDA	RACAL
	ORA	A
	JNZ	J$SNDSTR
;
	MVI	B,10		; Wait 1 second to go on hook
	CALL	J$TIMER
	LXI	H,STRNG4	; Set to auto-answer OFF
	JMP	J$SNDSTR
;.....
;
;
; Racal-Vadic mode
;
RTRNG1:	DB	'E'-40H,CR,'##','I',CR,'##','E'-40H,CR,'##'
	DB	'O23121111212',CR,'####','$'
RTRNG2:	DB	'D','#','$'
RTRNG3:	DB	'#','I',CR,'#','E'-40H,CR,'#'
	DB	'O23121111212',CR,'####','I',CR,'$'
;...
;
;
; 1200 "AT" mode, start out with this string for both 1200 and 2400 bps
;
STRNGA:	DB	'ATE1Q0V0X1H0'
	DB	CR,'####','$'	; Delay to let modem accept commands
;
;
; Special mode for Prometheus
;
STRNGP:	DB	'ATV2',CR,'###','$'
;
;
; 2400 "AT" mode
;
STRNG1:	DB	'ATM3'		; Loud speaker on after dialing
	DB	'L1',CR,'####'	; Hayes 2400 speaker volume
	DB	'ATE1Q0V0X4H0'	; Extended result codes (0-10)
	DB	CR,'####','$'	; Delay to let modem accept commands
STRNG2:	DB	'ATDT','#','$'	; Dial via Tone mode
STRNG3:	DB	'ATH0',CR,'#','$'
STRNG4:	DB	'ATS0=0',CR,'#','$'
STRNG5:	DB	'+++','$'
;.....
;
;
; Send the string pointed to by 'HL' to both the CRT and the modem.
;
SNDSTR:	CALL	QUIT		; Want to quit now?
	MOV	A,M
	CPI	'$'
	RZ
;
	CPI	'#'		; Special character to catch chars.?
	JNZ	SEND1		; If not, exit
	CALL	CATCH		; Else catch any/all characters
	JMP	SEND2		; Get next char. in string and continue
;
SEND1:	MOV	B,A		; SNDCHR needs character in 'B' reg.
	CALL	J$SNDCHR
;
SEND2:	INX	H		; Next character in the string
	JMP	SNDSTR
;.....
;
;
; Checks for answer from the Racal-Vadic and stores it in the buffer.
; Has a 30-second timer included, in case the Racal times out without
; sending a "failed call", our timer will.
;
SMRESULT:
	CALL	EMPTY		; Clear the buffer
	LXI	H,TBUF		; Put the modem result answer here
	PUSH	H		; Save it
;
SMRESUL1:
	LXI	D,330		; Time out 33 seconds after dialing
;
SMRESUL2:
	CALL	RCVRDY		; See if a character is ready
	JZ	SMRESUL4	; If yes, go get it
	CALL	QUIT		; Want to quit dialing?
	CALL	J$INMDM		; Wait up to 0.1 second for an answer
	JNC	SMRESUL5	; If a character, fine, skip delay count
	DCX	D		; One less loop
	MOV	A,D		; See if both are zero, yet
	ORA	E
	JNZ	SMRESUL2	; Make next loop
	POP	H		; Restore the stack to normal
	CALL	SMIN12		; Reinitialize the modem
	JMP	FAILED		; Timed out
;
SMRESUL4:
	CALL	J$INMDM		; Wait for the character and get it
	JC	SMRESUL6	; If done now, exit
;
SMRESUL5:
	ANI	7FH		; Remove any parity
	CPI	'*'+1		; Catches spaces, nulls, CR, LF, Bell..
	JC	SMRESUL4	; Asterisk and lesser characters
	POP	H		; Get the address in the buffer
	MOV	M,A		; Store the character there
	INX	H		; Get the next address
	PUSH	H		; Save it for now
	JMP	SMRESUL4	; Get the next character, if any
;
;
; Find what comment the Racal sent
;
SMRESUL6:
	POP	H		; Reset the stack
	LXI	D,TBUF
;
	LDA	RACAL		; Using the Racal-Vadic protocol?
	ORA	A
	JNZ	SMRESUL7	; If yes, jump to other section
;
;
; Handle the Hayes 0-5 result codes
;
	CALL	INLNCP
	DB	'1',0		; Connect 300 baud
	JNC	ON$3X		; See if '1' for 300 or '10' for 2400
	CALL	INLNCP
	DB	'3',0		; No Carrier
	JNC	NO$CAR
	CALL	INLNCP
	DB	'5',0		; Connect 1200 bps
	JNC	ON$1200
;
;
; See if using a Prometheus 1200 ProModem
;
	LDA	PROMODM		; Using a Prometheus ProModem?
	ORA	A
	JNZ	PROMDM		; If yes, exit
;
;
; See if running 1200 bps
;
	LDA	HS1200		; High speed 1200 bps?
	ORA	A
	JNZ	FAILED		; If yes, no other result codes coming
;
;
; Keep going if running 2400 bps with AT protocol
;
	CALL	INLNCP
	DB	'6',0		; No dial tone
	JNC	NO$DT
	CALL	INLNCP
	DB	'7',0		; Busy
	JNC	BUSY
	CALL	INLNCP
	DB	'8',0		; No answer
	JNC	FAILED
	CALL	INLNCP
	DB	'10',0		; Connect 2400 bps
	JNC	ON$2400
	JMP	FAILED		; If anything else, an error
;...
;
;
PROMDM:	CALL	INLNCP
	DB	'43',0
	JNC	NO$DT		; No dial tone
	CALL	INLNCP
	DB	'60',0
	JNC	DIALING		; Dialing...
	CALL	INLNCP
	DB	'61',0
	JNC	RINGING		; Ringing...
	JMP	FAILED		; Anything else, call failed
;...
;
;
; Handle the Racal results
;
SMRESUL7:
	CALL	INLNCP
	DB	'B',0		; Busy
	JNC	BUSY
	CALL	INLNCP
	DB	'H',0		; HELLO:I'M READY
	JNC	SMIN2
	CALL	INLNCP
	DB	'D',0		; Dialing...
	JNC	DIALING
	CALL	INLNCP
	DB	'R',0		; Ringing...
	JNC	RINGING
	CALL	INLNCP
	DB	'A',0		; Answer tone
	JNC	ANSWER
	CALL	INLNCP
	DB	'1',0		; On line
	JNC	ON$300
	CALL	INLNCP
	DB	'2',0		; On line
	JNC	ON$1200
	CALL	INLNCP
	DB	'3',0		; On line
	JNC	ON$2400
	CALL	INLNCP
	DB	'L',0		; On line
	JNC	ON$LINE
	CALL	INLNCP
	DB	'F',0		; Failed call - no answer, abort
	JNC	FAILED
	CALL	INLNCP
	DB	'T',0		; Timed out
	JNC	FAILED
	CALL	INLNCP
	DB	'E',0		; No dial tone
	JNC	NO$DT
	JMP	FAILED		; Anything else, call failed
;.....
;
;
ANSWER:	CALL	J$ILPRT
	DB	'answer, ',0
	INR	A
	STA	ANSWFL		; Show it did answer at least
;
;
; At 300 bps, the modems come back almost simultaneously with ANSWER and
; ONLINE, so we check the buffer to see if both answers are stored now.
;
	LDA	TBUF+1		; For 300 baud and terse mode
	CPI	'L'
	JZ	ON$LINE
	CPI	'1'
	JZ	ON$300
	CPI	'2'
	JZ	ON$1200
	CPI	'3'
	JZ	ON$2400
	LDA	TBUF+12		; For 300 bps and verbose mode
	CPI	'L'
	JZ	ON$LINE
	JMP	SMRESULT
;.....
;
;
BUSY:	CALL	J$ILPRT
	DB	'busy! ',0
	LDA	DIALWT
	MOV	B,A
	CALL	J$TIMER		; Slight pause to let phone hang up
	JMP	DIALAGN
;.....
;
;
DIALING:CALL	J$ILPRT
	DB	'dial, ',0
	JMP	SMRESULT
;.....
;
;
; Failed call is usually caused by continuous ringing with no answer.
; The modem times out (can be set to either 30 seconds or 60 seconds.)
;
FAILED:	CALL	J$ILPRT
	DB	'abort ',0
	LDA	DIALWT
	MOV	B,A
	CALL	J$TIMER		; Slight pause to let phone hang up
	JMP	DIALAGN
;.....
;
;
NO$CAR:	LDA	PROMODM		; Using a 1200 bps Prometheus ProModem?
	ORA	A
	JZ	FAILED		; If not, handle as a failed call
	LDA	RINGFL		; Have we recorded any rings yet?
	ORA	A
	JZ	BUSY		; If not, handle as a Busy signal
	JMP	FAILED		; If yes, handle as a failed call
;
ON$LINE:CALL	J$ILPRT
	DB	'on line',0
	JMP	CONMADE
;.....
;
;
ON$300:	CALL	J$ILPRT
	DB	'on 300',0
	CALL	J$300
	JMP	CONMADE
;.....
;
;
ON$1200:CALL	J$ILPRT
	DB	'on 1200',0
	CALL	J$1200
	JMP	CONMADE
;.....
;
;
ON$2400:CALL	J$ILPRT
	DB	'on 2400',0
	CALL	J$2400
	JMP	CONMADE
;.....
;
;
ON$3X:	LDA	TBUF+1		; If 2nd char is 0 for 10, then 2400
	CPI	'0'
	JZ	ON$2400
	JMP	ON$300
;.....
;
;
; No dial tone can occur when using the alternate dialing option and a
; dial tone is not detected after the pause 'K' or within 5 sec after
; the start of the modem dialing routine
;
NO$DT:	CALL	J$ILPRT
	DB	'- no dial tone',0
	JMP	DIALAGN
;.....
;
;
RINGING:CALL	J$ILPRT
	DB	'ring, ',0
	MVI	A,1		; Insure 'A' is not zero
	STA	RINGFL
	JMP	SMRESULT
;.....
;
;
; This is the auto-linking area.  Up to 32 numbers may be linked, each
; should have a comma for a separator, such as:
;
;	B>>COMMAND: CAL A,F,3,A,G,A,H
;
AUTO:	STA	AUTODIR		; Direct to terminal mode on answer
;
AUTO1:	MVI	A,0FFH		; Set the flags to -1
	STA	AUTOFL		; Set the auto-linking flag
	STA	CRFLAG		; Set the continuous redial flag
	MVI	B,64		; Maximum number of characters to move
	LXI	H,CMDBUF+1	; Start with number in the string
	LXI	D,CMDBUF+65	; Move to aft part of buffer
	JMP	MOVE		; When finished return to caller
;.....
;
;
; Linking routine
;
AUTO2:	LDA	AUTOFL		; Increment the flag for each new try
	INR	A
	INR	A
	STA	AUTOFL
	MOV	C,A		; Hold momentarily
	MVI	B,0
	LDA	CMDBUF+65	; See how many characters typed
	CMP	C
	JNC	AUTO3
	MVI	A,1		; Reset the flag to start over
	MOV	C,A
	STA	AUTOFL
;
AUTO3:	LXI	H,CMDBUF+65
	DAD	B
	JMP	DIAL6		; Go to work
;.....
;
;
ANSWFL:	DB	0		; Answer flag abort, no on line report
AUTODIR:DB	0		; Direct to terminal mode on answer
AUTOFL:	DB	0		; Auto-linking flag
NUMBER:	DB	0		; Number of characters in CMDBUF
RINGFL:	DB	0		; Only prints one 'ringing' msg
;.....
;
;
	DS	50		; Insures some spares will be available
;
;	       (end of Racal-Vadic/Hayes dialing routine)
;=======================================================================
;
	ORG	(($+255+50)/256*256)-50	; Even page for 'NUMLIB'
;
; Long distance alternate dialing such as MCI, SPRINT, etc.  Must end
; with a '$', use as many commas (2 seconds delay, each) as needed to
; let the alternate dialing code return with a new dial tone.  Fill in
; any character (periods are fine) after the $ to keep number of columns
; to 24, i.e.,	'1234567,,,,12345,,$.....'   --   the first group is the
; MCI or SPRINT access number, the second group is the user number.  A
; small delay is usually required after the billing number also.
;
ALTDL1:	DB	'xxxxxxx,,,,,,xxxxxxxx,,$' ; Accessed by a < character
ALTDL2:	DB	'xxxxxxx,,,,,,xxxxxxxx,,$' ; Accessed by a > character
;
;=======================================================================
;
DIALWT:	DB	5		; tenth-seconds to wait for dial tone
SAVSIZ:	DB	XFRSIZ*8	; Can easily change buffer size for file
				;   transfers with DDT for "NUMBLIB-1"
				;   address.  Normally 4k (32 records
				;   or 4k).
;
;=======================================================================
;
; Phone number library table for auto-dialing.	Each number must be as
; long as"LIBLEN" (EQU at start of program).  Some areas require extra
; characters such as:	1-313-846-7127.  Room is left for those.  Use
; a (<) for alternate dialing system #1, and a (>) for alternate dialing
; System #2.  Either would preceed the actual number, for example:
;
;	DB    'A=Alan Alda..........<123-456-7890'    ;'A'
;
; -	-     -     -	  -	-     -     -	  -	-     -     -
;
; NOTE: At least one dot (.) MUST precede the actual phone number
;
;		'----5---10---15---20---25---30--34'
NUMBLIB:DB	'A=Norman Beeler.....1-408-245-1420' ; 'A'
	DB	'B=Rich Berg.........1-618-359-4446' ; 'B'
	DB	'C=Robert Blacher....1-202-254-2008' ; 'C'
	DB	'D=Brian Callahan....1-718-625-5931' ; 'D'
	DB	'E=Bob Clyne.........1-313-759-6569' ; 'E'
	DB	'F=Bill Earnest......1-215-398-3937' ; 'F'
	DB	'G=Norm Gregory......1-206-325-1325' ; 'G'
	DB	'H=Irv Hoff................948-2166' ; 'H'
	DB	'I=Jeff King.........1-408-247-2853' ; 'I'
	DB	'J=Kim Levitt........1-213-653-6398' ; 'J'
	DB	'K=Tim Linehan.......1-206-357-7400' ; 'K'
	DB	'L=Jim Lopushinski...1-403-484-5981' ; 'L'
	DB	'M=Trevor Marshall...1-805-492-5472' ; 'M'
	DB	'N=Wayne Masters.....1-408-378-7474' ; 'N'
	DB	'O=Paul Matlin.......1-301-661-2175' ; 'O'
	DB	'P=Dave McCord ZCPR3.1-415-489-9005' ; 'P'
	DB	'Q=Byron McKay.......1-415-965-4097' ; 'Q'
	DB	'R=Dick Mead.........1-818-799-1632' ; 'R'
	DB	'S=Chuck Metz........1-408-354-5934' ; 'S'
	DB	'T=Al Mehr...........1-408-238-9621' ; 'T'
	DB	'U=Jud Newell........1-416-232-0442' ; 'U'
	DB	'V=George Peace......1-717-657-8699' ; 'V'
	DB	'W=John Riehl........1-713-488-5619' ; 'W'
	DB	'X=Gary Shaffstall...1-303-985-1108' ; 'X'
	DB	'Y=Murray Simsolo....1-516-825-8465' ; 'Y'
	DB	'Z=Larry Snyder......1-305-677-8086' ; 'Z'
	DB	'0=John Sojak........1-312-941-0049' ; '0'
	DB	'1=Alex Soya.........1-305-727-0331' ; '1'
	DB	'2=Ken Stritzel......1-312-983-5147' ; '2'
	DB	'3=Henry Trujilio....1-207-443-4657' ; '3'
	DB	'4=Bill Wood.........1-619-256-3914' ; '4'
	DB	'5=Tom Vande-Stouwe..1-516-567-8267' ; '5'
	DB	'6=Spare.............1-xxx-xxx-xxxx' ; '6'
	DB	'7=Spare.............1-xxx-xxx-xxxx' ; '7'
	DB	'8=Spare.............1-xxx-xxx-xxxx' ; '8'
	DB	'9=Spare.............1-xxx-xxx-xxxx' ; '9'
	DB	0		; End
;		'----5---10---15---20---25---30--34'
;
;-----------------------------------------------------------------------
;
; This is the storage area for the ten function keys.  The I2FUNC.COM
; program dynamically allocates the storage for the keys.  Thus, no
; function key is limited to so-and-so many characters.  Rather, the
; total number of bytes in the function key library (including flags)
; is 256.
;
INTCPT:	DB	ESC		; Intercept character (prefix)
;
FNCTBL:	DB	0,'DIR ',CR,0
	DB	1,'DIR *.* $U0AD ',CR,0
	DB	2,'KMD R ',0
	DB	3,'KMD S ',0
	DB	4,'XMODEM R ',0
	DB	5,'XMODEM S ',0
	DB	6,'BYE ',CR,0
	DB	7,'RBBS ',CR,0
	DB	8,'(vacant)',0
	DB	9,'Nice chatting, see you again soon... ',CR,0
;
	DS	256-($-FNCTBL)
;
;
;
;***********************************************************************
;
;
; P - R - O - G - R - A - M	S - T - A - R - T - S	  H - E - R - E
;
;
;***********************************************************************
;
;
START:	LXI	H,0
	DAD	SP		; Add the current stack pointer to 'HL'
	SHLD	STACK
	LXI	SP,STACK	; Start local stack
;
;
; The 'FIXCNT' calculations are done here and the values stored so the
; overhead of doing the calculation is not incurred in the RECV routine
; where it is desired to pick up a character from the modem data port as
; quickly as possible.
;
	LXI	H,480		; Adjust to get 1 second time intervals
	CALL	FIXCNT
	SHLD	TIMVAL
	LXI	H,48		; Should be 1/10 of above value
	CALL	FIXCNT
	SHLD	QUIKTIM
;
;
; Now display the program name and version number and we are under way
;
	CALL	CRCGN		; Generate tables for fast 'CRC' check
	CALL	INITADR		; Initialize addresses
	CALL	INTERCEPT	; Establish the function key intercept
	CALL	SETSPD		; Bring up DTR, set modem speed
	CALL	PROCOPT		; Process any options
	LDA	OPTION		; Any options on the command line?
	CPI	' '+1
	JNC	RSTRT
	CALL	ILPRT
	DB	CR,LF,'IMP v',VERSION/100+'0'
	DB	VERSION	MOD	100/10+'0'
	DB	VERSION	MOD 10+'0'
	DB	' modem pgm (type M for Menu)'
	DB	CR,LF,'Copyright (c) 1985, 1987 Irvin M. Hoff'
	DB	CR,LF,0
	CALL	J$SYSVR		; Give configuration message
	CALL	RATE
	JMP	MENU
;
;
; Comes here from menu once the options have been set
;
RSTRT:	LXI	SP,STACK	; Make sure we have a clean stack
	CALL	CKCHAR		; Catch any garbage characters left
;
RSTRT1:	LDA	OPTION		; Get the option
	CPI	'C'		; Call (dial) function?
	JZ	J$DIAL		; Yes, go to it
;
RSTRT2:	CALL	MOVEFCB
	XRA	A
	STA	GOTONE		; Indicated a batch file was transferred
	STA	KFLG		; Reset the flag (might have been used)
	LDA	OPTION		; Get main option
	CPI	'D'		; Disconnect?
	JZ	DONETD		; Yes, disconnect then back to the menu
	CPI	'M'		; Menu asked for?
	JZ	MENU2		; Go display the menu
	CPI	'R'		; Want to receive a file?
	JZ	RCVFL		; Exit if yes
	CPI	'S'		; Want to send a file?
	JZ	SNDFL		; Exit if yes
	CPI	'T'		; Want terminal mode?
	JNZ	RSTRT3		; If not, exit
	XRA	A
	STA	ECHOFLG		; Reset echo flag
	STA	LOCFLG		; Reset local flag
	JMP	DSKSV		; Exit if yes
;
RSTRT3:	CPI	'E'		; Want echo mode?
	JNZ	NOECHO		; If not, exit
	STA	ECHOFLG		; Set the echo flag
	XRA	A
	STA	LOCFLG		; Reset local flag
	JMP	DSKSV
;
NOECHO:	CPI	'L'		; Want local echo mode?
	JNZ	NOLOCAL		; If not, exit
	STA	LOCFLG		; Set the local flag
	XRA	A
	STA	ECHOFLG		; Reset echo flag
	JMP	DSKSV
;
NOLOCAL:CALL	NTVLDMSG	; Say not a valid option
	JMP	MENU		; Then go back to the command mode
;.....
;
;
INITADR:LHLD	0000H+1		; BIOS warm reboot jump vector
	LXI	D,3
	DAD	D
	SHLD	VSTAT+1		; BIOS console status jump vector
	DAD	D
	SHLD	VKEYIN+1	; BIOS console keyboard jump vector
	DAD	D
	SHLD	VTYPE+1		; BIOS console CRT jump vector
	LXI	D,33
	DAD	D
	SHLD	GOLIST+1	; BIOS list device status jump vector
	CALL	GETUSER		; Get current user number
	STA	OLDUSER		; Save to restore upon exit
	JMP	GTMAX		; Find maximum ram for printer use, done
;.....
;
;
; Get the function key intercept character and put in appropriate places
;
INTERCEPT:
	LDA	INTCPT		; Get the function key intercept char.
	ANI	07FH		; Strip off any parity
	STA	GTCMD1+1	; Store in the menu area
	CPI	' '		; Printing character?
	JNC	INTER1		; If yes, exit
;
	CPI	ESC		; Using the ESC key?
	JZ	INTER2		; If yes, special case
	ADI	40H		; Change to printing character
	STA	MENU3+1
	MVI	A,'^'
	STA	MENU3		; Store the "control-" character
	RET
;...
;
;
INTER1:	STA	MENU3+1
	RET
;...
;
;
INTER2:	MVI	A,'E'		; Just show 'ESC' then rather than ^[
	STA	MENU3
	MVI	A,'S'
	STA	MENU3+1
	MVI	A,'C'
	STA	MENU3+2
	RET
;.....
;
;
; Process any options - put 0 in appropriate place in option table if
; option is selected
;
PROCOPT:LXI	D,FCB+1		; Look at first char. on command line
	LDAX	D		; Get the character
	STA	OPTION		; Store it for primary option
	CPI	' '		; Exit if no options
	RZ
;
OPTLP:	INX	D		; See if an additional option
	LDAX	D		; Get the character
	CPI	' '		; Was it a space?
	JZ	ENDOPT		; If yes, options are finished
	LXI	H,OPTBL		; Start of option table
	MVI	B,OPTBE-OPTBL	; Number of entries in option table
;
OPTCK:	CMP	M		; See if character matches one in table
	JNZ	OPTNO		; If not, keep looking
	MVI	M,0		; If yes, reset the flag to zero
	JMP	OPTLP		; Check on additional options on line
;
OPTNO:	INX	H		; Next location in option table
	DCR	B		; One less to go
	JNZ	OPTCK		; If not zero, keep checking the table
	CALL	NTVLDMSG	; If none of those was a wrong entry
	POP	H		; Preserve stack
	JMP	MENU		; Jump out to the menu
;
ENDOPT:	LDA	VSEEFLG		; See if visual flag is set
	ORA	A
	JNZ	CKOPT
	STA	QFLG		; Quiet mode for watching data items
;
;
; Checked for supplementary options, now check the primary option
;
CKOPT:	LDA	OPTION		; Check on the primary option
	CPI	'C'		; Going to autodial now?
	RZ
	CPI	'D'		; Going to disconnect?
	RZ
	CPI	'E'		; Return if echo option
	RZ
	CPI	'M'		; Return if help option
	RZ
	CPI	'L'		; Return if local echo option
	RZ
	CPI	'T'		; Return if terminal mode
	RZ
;
	MOV	B,A		; Save the character
	LDA	NFILFLG		; Saving memory for disk file?
	ORA	A
	JZ	CKOPT2		; If not, continue
	POP	H		; Reset the stack from 'CALL PROCOPT'
	JMP	MENU0		; Go show the 'FILE OPEN' message
;
CKOPT2:	MOV	A,B		; Get the option back
	CPI	'S'
	JZ	CKFILE
	CPI	'R'
	JNZ	BDOPT		; None of these, bad option
;
	LDA	BATCHFLG	; See if the batch mode flag is set
	ORA	A
	RZ			; If yes, exit
;
CKFILE:	LDA	FCB+17		; 'S' and 'R' need a file name
	CPI	' '
	RNZ			; Exit if a file name is present
	MOV	A,B		; Call 'R' without filename batch
	CPI	'R'
	JNZ	CKFILE1
	XRA	A
	STA	BATCHFLG	; Show now in batch mode
	RET
;...
;
;
CKFILE1:CALL	ILPRT
	DB	'++ Enter primary option plus file name ++'
	DB	CR,LF,BELL,0
	POP	H		; Reset stack from 'CALL STFCB'
	JMP	MENU		; Abort to command line
;.....
;
;
BDOPT:	CALL	ILPRT
	DB	CR,LF,'++ Bad option ++',CR,LF,LF,0
;.....
;
;
; Check for any garbage characters on line - catch and ignore
;
CKCHAR:	CALL	RCVRDY		; Any characters ready to receive?
	RNZ			; If not, return
	CALL	I$MDDATP	; Otherwise get the character and ignore
	JMP	CKCHAR		; Check for any additional characters
;.....
;
;
; Revised terminal routine allowing memory save.  First checks for bad
; options, to prevent wiping out the disk with accidental memory save.
;
DSKSV:	LDA	BATCHFLG	; Batch flag set?
	ORA	A
	JNZ	DSKSV1		; If not set, everything is normal
	MVI	A,'B'		; If set, shouldn't be, so reset it
	STA	BATCHFLG
	JMP	NOTVLD		; If set, error for 'E', 'L' or 'T'
;
DSKSV1:	STA	XFLG		; Will use the ASCII capture buffer size
	LDA	NFILFLG		; Already saving for a file?
	ORA	A
	JZ	DSKSV2		; Exit if not, and open a file
	CALL	BUFMS		; Tell if buffer if on or off
	JMP	TERM
;
DSKSV2:	LDA	FCB+1		; First character of filename (if any)
	CPI	' '		; File specified?
	JNZ	GOODNM		; Yes, good name
	XRA	A
	STA	NFILFLG		; Show no file being saved
	STA	SAVEFLG		; Reset the flag to zero
	JMP	TERM
;...
;
;
GOODNM:	CALL	ERASF
	LXI	H,FCB3
	CALL	INITFCB
	LXI	H,FCB		; Move the disk name into FCB3 area
	LXI	D,FCB3
	MVI	B,12
	CALL	MOVE
	LXI	D,FCB3		; Now make a file from that name
	MVI	C,MAKE
	CALL	BDOS
	LXI	D,FCB3		; Now open the file from FCB3
	MVI	C,OPEN
	CALL	BDOS
	LXI	H,BUFFER	; Reset pointers to start of buffer
	SHLD	HLSAV
	MVI	A,1
	STA	NFILFLG		; Show now saving to memory for disk file
	STA	SAVEFLG		; Active the file at the same time
	CALL	BUFMS		; Show buffer is open
;
TERM:	CALL	GOLIST
	CALL	STAT		; Keyboard have a character?
	JZ	TERML		; If not, see if any incoming
;
	CALL	KEYIN		; Get character from keyboard
	MOV	B,A		; Save for now to protect 'A' reg.
	CPI	RUB		; Test for rub
	JNZ	NOTRUB		; Exit if not
	LDA	CONVRUB		; Convert rub to backspace?
	ORA	A
	JZ	NOTRUB		; Exit if no conversion
	MVI	B,BKSP		; Call it a backspace
	JMP	NTOG		; Go send a backspace
;
NOTRUB:	LDA	FNKFLG		; Get function key active flag
	ORA	A
	JZ	CKEXAC		; If not set yet, exit
;
	XRA	A		; First zero the flag
	STA	FNKFLG
	MOV	A,B		; Get character
	CPI	'0'
	JC	CKEXAC		; If less, not a function key
	CPI	'9'+1
	JNC	CKEXAC		; If more, not a function key
	XRA	A
	STA	EXACFLG		; Just in case both use same character
	MOV	A,B		; Get the character back
	ANI	0FH		; Make 0..9
	JMP	SNDFK
;
CKEXAC:	LDA	EXACFLG		; External flag set yet?
	ORA	A
	JZ	NTEXAFLG	; If not, proceed normally
;
	XRA	A		; Reset the flag
	STA	EXACFLG
	MOV	A,B		; Get the character back
	ANI	5FH		; Make sure it is upper case
	MOV	B,A		; Save for comparison
	CALL	EXITTST1	; Want to exit to menu?
;
	LDA	CLEARS		; ESC-Z to clear screen, terminal mode
	CMP	B
	JZ	CLRCRT
	LDA	FILESND		; Output text file to remote?
	CMP	B
	JZ	SNDFILE
	LDA	LOGCHR		; Send logon?
	CMP	B
	JZ	SNDLOG
	LDA	LSTCHR		; Get the printer control-character
	CMP	B		; Did we just ask for printer control?
	JNZ	NOLST		; If not, exit
	LDA	LISTFLG		; Otherwise reset the printer toggle
	CMA
	STA	LISTFLG		; And store
	CALL	CRLF
	CALL	CRLF
	CALL	LSTMS		; Tell if printer is on or off now
	CALL	CRLF
	JMP	TERML		; Back to the terminal mode again
;...
;
;
NOLST:	LDA	BRKCHR		; Want to send a break tone?
	CMP	B
	JZ	SBREAK
	LDA	NOCONCT		; Want to disconnect from line?
	CMP	B
	JZ	DONETD		; If yes go disconnect
	LDA	UNSAVCH		; Close input buffer?
	CMP	B
	JZ	NOLST1		; If yes, disable copy
	LDA	SAVECHR		; Open input buffer?
	CMP	B
	JNZ	NTOG
	LDA	NFILFLG		; Do not allow save if flag is set
	ORA	A
	JZ	TERML
	JMP	NOLST2
;
NOLST1:	XRA	A		; Stop copy into file
;
NOLST2:	STA	SAVEFLG
	CALL	BUFMS
	JMP	TERM		; Get next character
;.....
;
;
NTEXAFLG:
	LDA	EXTCHR		; Treat next character in special way?
	CMP	B		; Check against this control character
	JNZ	NOF
	STA	EXACFLG		; Set the flag
;
	LDA	INTCPT		; See if INTCPT is same as EXTCHR
	CMP	B		; (If it is, is ok - it uses 0-9)
	JNZ	TERML		; If not, all set with EXACFLG flag set
	STA	FNKFLG		; If yes, set FNKFLG also
	JMP	TERML		; Do not send, get next character
;.....
;
;
NOF:	LDA	INTCPT		; Check intercept character
	CMP	B
	JNZ	NTOG		; If not send this character to modem
	STA	FNKFLG		; Set the function flag
	JMP	TERML		; Do not send the intercept character
;.....
;
;
; Clears the CRT screen with "ESC-Z"
;
CLRCRT:	CALL	CLRTST
	JMP	TERML		; Back to work
;.....
;
;
;***********************************************************************
;
;			 SND A CP/M FILE
;
;***********************************************************************
;
;
SNDFL:	CALL	CKCHAR		; Catch any garbage characters
	XRA	A		; Indicate using send batch mode
	STA	SNDFLG
	LDA	BATCHFLG	; Check if multiple file mode is set
	ORA	A
	JNZ	SNDFL4		; If not using batch mode, exit
;
	CALL	ILPRT
	DB	'Ready to send in batch mode',CR,LF,0
;
SNDFL1:	LDA	FSTFLG		; First time through?
	ORA	A
	JNZ	SNDFL2		; If not, exit
	CALL	TNMBUF		; Get and store batch file names
	LDA	FILECT		; Get the number of files to send
	ORA	A
	JNZ	SNDFL2		; Exit if something to send
	CALL	ILPRTQ
	DB	CR,LF,'++ Ask again, file not found ++',0
;
SNDFL2:	CALL	SNDFN		; Sends file name to receive
	JNC	SNDFL3		; More files if carry is not set
;
	MVI	A,'B'		; Stop batch mode
	STA	BATCHFLG
	LDA	GOTONE		; Was a file actually transferred?
	ORA	A
	JZ	ABORT		; If not, don't say it was
	JMP	DONE
;
SNDFL3:	CALL	CRLF		; Extra line before file name
	CALL	SHOWFIL		; Display the file name
	CALL	CRLF
;
SNDFL4:	LDA	FCB+1
	CPI	' '
	JZ	BLKFILE
	CALL	CNREC		; Get number of records
	CALL	OPENFIL
	CALL	RDBLK1		; Read some of the file into the buffer
	CALL	CKCHAR		; Catch any garbage characters
	LDA	KKMD		; See if operator typed "SK"
	ORA	A
	JNZ	SNDFL5		; If not, exit
	INR	A		; Else set the manual 1k flag
	STA	KFLG
;
SNDFL5:	MVI	E,60		; Wait up to 1 minute for a start signal
	CALL	WAITNAK
	CALL	SETFLG		; Switch to 128 size if under 8 records
;
SNDLP:	CALL	GTRATIO		; Check the ACK ratio if using 1k blocks
	CALL	RDRECD		; Read a record
	JC	SNDEOF		; If finished, exit
	CALL	INCRNO		; Increment the record number
	MVI	A,1
	STA	ERRCT		; Reset the error count to normal
;
SNDRPT:	CALL	CKABORT		; Want to quit at this time?
	CALL	SNDHDR		; Send a header group
	CALL	SNDREC		; Send the record number
	CALL	SNDCHK		; Send CRC or Checksum
	CALL	GTACK		; Wait for an 'ACK' for this record
	JC	SNDRPT		; Repeat same record if no 'ACK'
;
	CALL	SETPTR		; Successful record so increase pointers
	JMP	SNDLP		; Send next record
;.....
;
;
SNDEOF:	MVI	A,EOT		; Send an End of Transmission character
	CALL	SEND
	LDA	CHKEOT		; Did not get an 'ACK', try again
	INR	A
	STA	CHKEOT		; Limit number of retries to 4
	CPI	4
	JNC	DONE		; If four or more, assume he got one
	CALL	GTACK		; Wait for an 'ACK' that it was received
	JC	SNDEOF		; Try again, they didn't get it
	JMP	DONE		; Else got a good ACK, so finished
;.....
;
;
;***********************************************************************
;
;		       RECEIVE A CP/M FILE
;
;***********************************************************************
;
;
RCVFL:	LDA	XMODEM		; "RX", insures receiving blocks of 128
	STA	KFLG		; Set the 1k block flag similar
	LDA	CRCDFLT		; Get mode requested by operator
	STA	CRCFLG		; Store it, resets 1k blocks if needed
	ORA	A
	JNZ	RCVFL1		; Skip next line if requesting CRC
	STA	KFLG		; Can't have 1k blocks with checksum
;
RCVFL1:	LDA	BATCHFLG	; Check if multiple file mode
	ORA	A
	JNZ	RCVFL2		; If not, exit
	MVI	A,1		; Indicate using receive batch mode
	STA	SNDFLG		; For next file transfer
	CALL	GETFN		; Get the file name
	JNC	RCVFL3		; Carry not set means more files yet
;
	MVI	A,'B'		; Stop batch
	STA	BATCHFLG	; Mode option
	LDA	GOTONE		; Indicates a batch file was transferred
	ORA	A
	JZ	ABORT		; If not, don't indicate it was
	JMP	DONE
;
RCVFL2:	LDA	FCB+1		; Make sure file is named
	CPI	' '
	JZ	BLKFILE
	JMP	RCVFL5
;
RCVFL3:	LDA	KMDODE		; Using Yam batch?
	ORA	A
	JZ	RCVFL4		; Yes, skip showfil as already done
	CALL	SHOWFIL		; Show the file name
	MVI	A,' '
	CALL	TYPE
	CALL	SNDPRG		; Get progress and wait for quiet line
;
RCVFL4:	CALL	CKCPM2
	LDA	KMDODE
	ORA	A
	JZ	RCVFL5		; Skip CRLF if in Yam batch
	CALL	CRLF
;
RCVFL5:	CALL	ERASF
	CALL	MAKEFIL
	CALL	WAITQ1
	LDA	BATCHFLG	; Do not print message if in batch mode
	ORA	A
	JZ	RCVFL6		; Exit if in batch mode
	CALL	FILNAM
	CALL	ILPRTQ
	DB	CR,LF,'File open, ready to receive',CR,LF,0
;
RCVFL6:	LDA	CRCFLG
	ORA	A
	JZ	RCVFCHK		; Exit if in checksum mode
	LDA	BATCHFLG	; In batch mode?
	ORA	A
	JNZ	RCVFLC		; Exit if not
	LDA	KMDODE		; Yam batch?
	ORA	A
	JZ	RCVFL7		; Yes, skip CRC message and KFLG
;
RCVFLC:	CALL	ILPRTQ		; Then say so
	DB	'CRC in effect',CR,LF,0
;
RCVFL7:	MVI	A,CRC		; Else request 128 size with CRC
	JMP	RCVLF8
;
RCVFCHK:CALL	ILPRTQ		; Else say 'CHECKSUM' mode
	DB	'Checksum in effect',CR,LF,0
	MVI	A,NAK
;
RCVLF8:	PUSH	PSW
	CALL	ILPRT
	DB	'Waiting.....',0
	POP	PSW
	CALL	SEND
	LDA	KFLG		; Requesting 1k blocks?
	ORA	A
	JZ	RCVLP
	MVI	A,KSND		; 1k block request
	CALL	SEND
;
;
; This is the acutal receive loop
;
RCVLP:	CALL	RCVRECD
	JC	RCVEOT
	CALL	INCRNO
	CALL	REPORT		; Show record received if not in quiet
	CALL	WRRECD
	CALL	SNDACK
	JMP	RCVLP		; Loop for next incoming record
;
;
; Got an EOT, erase an empty file, else write to disk and close the file
;
RCVEOT:	LHLD	RECNO		; Check for zero length file
	MOV	A,H		; If no records, no file
	ORA	L
	JZ	ABORT		; Abort and erase the zero-length file
	CALL	WRBLOCK
	CALL	CLOSFIL
	CALL	SNDACK
	JMP	DONE
;.....
;
;
SNDACK:	MVI	A,ACK
	JMP	SEND
;.....
;
;
;===================== SEND FILE IN T-MODE =============================
;
;
; Send file routine - called with (special character F) when in terminal
; mode.  Sending may be cancelled by using CTL-X (cancel) key.
;
SNDFILE:LXI	H,FCB4
	CALL	INITFCB		; Initializes FCBs
	LXI	H,FCB+16
	CALL	INITFCB
;
;
; Get name of file to send in "T" (terminal) mode
;
GET:	CALL	ILPRT
	DB	CR,LF,'File name to send? (CR to abort): ',0
	LXI	D,CMDBUF
	CALL	INBUF
	LDA	CMDBUF+2	; Was file entered?
	CPI	' '
	JZ	RETRN		; If not probably wanted to quit
	LXI	D,CMDBUF
	LXI	H,FCB4
	CALL	CMDLINE
	LXI	D,FCB4
	MVI	C,OPEN
	CALL	BDOS
	CPI	0FFH		; Return with 0FFH means 'NO SUCH FILE'
	JZ	SNDMSG
;
;
; Choice of normal speed or delays between characters / lines
;
	CALL	ILPRT
	DB	'Want to include time delays? (Y/N): ',0
	CALL	KBDCHR
	CPI	'N'		; If 'N' send normal speed
	JZ	DLYSAV
	XRA	A		; Otherwise use character/line delays
;
DLYSAV:	STA	DLYFLG		; Store the decision
	CALL	CRLF
	LXI	D,CMDBUF+2	; Make sure CMDBUF has been selected
	MVI	C,STDMA
	CALL	BDOS
;
;
; Get 128-byte record
;
READM:	LXI	D,FCB4
	MVI	C,READ
	CALL	BDOS
	ORA	A		; Check for a good read
	JZ	READM1
	DCR	A		; Check for end of file to send
	JZ	RETRNS
	CALL	ERXIT		; Neither of those, was a read error
	DB	'++ DISK READ ERROR ++','$'
;
;
; Successful read, so send the record
;
READM1:	CALL	SND80C		; Send one 128-char record
	CPI	EOFCHAR		; End of file - omit if object
	JZ	RETRNS		;   code is to be sent.
	CPI	CANCEL		; Want to quit?
	JNZ	READM
;
RETRN:	CALL	ILPRT
	DB	CR,LF,LF,'(in Terminal-mode now)',CR,LF,LF,0
	CALL	SNDNOW		; Insures last character is finished
	CALL	CKCHAR		; Catch any echo character on line
	JMP	TERM		; Finished, back to Terminal-mode
;.....
;
;
RETRNS:	CALL	ILPRT
	DB	CR,LF,'[Transfer completed]',0
	JMP	RETRN
;.....
;
;
SNDMSG:	CALL	ILPRT
	DB	CR,LF,BELL,'++ FILE NAME ERROR ++ ',CR,LF,0
	JMP	GET
;.....
;
;
; Send one 128-byte record
;
SND80C:	MVI	B,128		; Will send a maximum of 128 character
	LXI	H,CMDBUF+2	; They are in the CMDBUF area
;
SNDCH1:	MOV	A,M		; Get the character to send
	ANI	7FH		; Strip off any high bits set
	CPI	EOFCHAR
	RZ
	CALL	MDOUT		; Send the character to modem
	CALL	STAT		; Want to terminate sending?
	ORA	A
	JZ	SKIP1
	CALL	KEYIN
	CPI	CANCEL
	RZ
;
SKIP1:	INX	H
	DCR	B
	JNZ	SNDCH1
	RET
;.....
;
;
; Send the character to the output
;
MDOUT:	PUSH	PSW		; Save the character so can use 'A' reg.
	CPI	LF
	JNZ	MDOUTL
	LDA	ADDLFD		; Going to send the line feed to modem?
	ORA	A
	JNZ	MDOUTL		; If yes, go to normal routine
	POP	PSW		; Get the character back (a line feed)
	CALL	TYPE		; Show on CRT, do not send to modem
	RET
;...
;
;
MDOUTL:	CALL	TXOFF		; Check for Xoff
	LDA	DLYFLG		; Going to include delays?
	ORA	A
	JNZ	MDOUTL2		; If not, check normal flag
;
MDOUTL1:CALL	SNDTXE		; See if TxE output buffer is empty yet
	JNZ	MDOUTL1		; If not, wait
	CALL	SPDCHR		; When ready, kick in requested delay
	JMP	MDOUTL3		; Go send the character
;
MDOUTL2:CALL	SNDRDY		; Wait until modem is ready to send
	JNZ	MDOUTL
;
MDOUTL3:POP	PSW		; Get the character back
	CALL	TYPE		; Send character to CRT
	CALL	O$MDDATP	; Send character to modem
	CPI	CR		; Was it an end of line?
	RNZ			; If yes, see if any delay is needed
;
;
; Delay to allow slow BBS systems (most use BASIC) to enter the line.
; Choice of 0-9 for 100 ms. each, maximum of 900 ms.
;
	LDA	DLYFLG		; Going to send a delay each line?
	ORA	A
	JZ	SPDLIN		; If yes send the delay
	RET
;.....
;
;
; Add from 0 to 9 ms. delay between characters for slow bulletin board
; systems (most use 'C' or 'MBASIC').
;
SPDCHR:	LDA	BYTDLY		; Get delay between characters (0-9)
	ORA	A
	RZ			; Don't bother if set to zero
	PUSH	B
	ADD	A		; Double the value for 1 ms. loops
	ADD	A		; Double again for the 1 ms. loops
	MOV	B,A		; Main number of loops
	CALL	SPEED
	POP	B		; Restore the BC values
	RET
;.....
;
;
; Sends 0-900 ms between lines
;
SPDLIN:	LDA	CRDLY		; Get delay between lines (0-90)
	ORA	A
	RZ			; Don't bother if set to zero
	PUSH	B
	ADD	A		; Double the value for 1 ms. loops
	ADD	A		; Double again for the 1 ms. loops
	MOV	C,A		; Store
	MVI	D,100		; 100 loops for 100 ms. each
;
SPDLIN1:MOV	B,C		; Get the original value again
	CALL	SPEED
	DCR	D		; One less main loop to go
	JNZ	SPDLIN1		; If not zero, keep delaying
	POP	B		; Restore the BC values
	RET
;...
;
;
; For 1/2 ms delay
;
SPEED:	LDA	CLOCK		; Secondary number of loops
;
SPEED1:	XCHG			; Waste some time
	XCHG			; Restore HL & DE, a little more time
	DCR	A		; Decrement inner loop
	JNZ	SPEED1		; If not zero, keep going
	DCR	B		; Decrement outer loop
	JNZ	SPEED		; If not zero, reset inner loop
	RET
;.....
;
;
TXOFF:	CALL	RCVRDY
	RNZ
	CALL	I$MDDATP
	ANI	7FH
	CPI	XOFF
	CZ	WAITXON
	RET
;.....
;
;
WAITXON:CALL	RCVRDY		; Have a character? (like X-on)
	JNZ	WTXON1		; If no character see if want to abort
	CALL	I$MDDATP
	ANI	7FH		; Strip off any parity
	CPI	XON		; See if character was X-on
	RZ			; If yes, keep going
;
WTXON1:	CALL	STAT		; Test to see if requesting cancellation
	JZ	WAITXON		; Nothing typed, wait for X-on
	CALL	KEYIN		; Can abort if the X-on never comes
	CPI	CANCEL		; CTL-X to abort?
	JNZ	WAITXON		; If not, keep going
	RET
;.....
;
;
;=================== END OF FILE SEND IN T-MODE ========================
;
;
;***********************************************************************
;
;			   SUBROUTINES
;
;***********************************************************************
;
;
; Show the file name as stored in the FCB but in CP/M format
;
SHOWFIL:LDA	QFLG		; Can type it if no 'QFLG'
	ORA	A
	RZ
	LXI	H,FCB+1
	XRA	A
	STA	FTYCNT
	MVI	C,11
;
PRNAM:	CALL	FTYTST
	INX	H
	DCR	C
	JNZ	PRNAM
	RET
;.....
;
;
; Give report of received records as they occur
;
REPORT:	LDA	QFLG
	ORA	A
	RZ
	LHLD	RECNO		; Get record number
	CALL	ILPRT
	DB	CR,'Received # ',0
	CALL	DECOUT		; Print record number in decimal
	CALL	ILPRT
	DB	' ',0
	RET
;.....
;
;
FTYTST:	LDA	FTYCNT
	INR	A
	STA	FTYCNT
	CPI	9		; Are we at the file type?
	JZ	SPCTST		; Go if so
;
ENDSPT:	MOV	A,M
	CPI	' '		; Test for space
	CNZ	TYPE		; Type if not
	RET
;.....
;
;
; See if enough records in file to use 1k protocol if requested
;
SETFLG:	LHLD	RCNT
	MOV	A,H		; Anything in the 'H' register?
	ORA	A
	RNZ
	MOV	A,L		; Get number of records in 'L' register
	CPI	8		; At least 8 yet?
	RNC			; If 8 or more, keep going
	XRA	A		; Reset the 'K' flag
	STA	KFLG
	RET
;.....
;
;
SPCTST:	MOV	A,M
	CPI	' '		; Test for space in 1st file type byte
	RZ			; Do not output period if space
	MVI	A,'.'
	CALL	TYPE
	JMP	ENDSPT		; Output 1st file type byte
;.....
;
;
; Get sender's progress report if it is present and wait for line to get
; quiet
;
SNDPRG:	MVI	B,1		; Wait up to 1 second
	CALL	RECV
	CALL	TYPE		; Show the progress report from sender
	JNC	SNDPRG
	RET
;.....
;
;
SNDFN:	LDA	KMDODE		; Using Yam batch?
	ORA	A
	JZ	SNDKMD		; If so, skip following routine
;
	CALL	ILPRTQ
	DB	CR,LF,'Awaiting name NAK',0
	CALL	GTACK
	CC	SNDACK
	LXI	H,FILECT
	DCR	M
	JM	NOMRN
	LHLD	NBSAVE		; Get file name..
	LXI	D,FCB		; In FCB
	MVI	B,12
	CALL	MOVE
	SHLD	NBSAVE
	CALL	SNDNM		; Send it
	ORA	A		; Clear carry
	RET
;.....
;
;
NOMRN:	MVI	A,EOT
	CALL	SEND
	STC
	RET
;.....
;
;
;-----------------------------------------------------------------------
;		       KMD send batch mode
;
SNDKMD:	CALL	CATCH		; Clear the decks for action
	XRA	A
	STA	ERRCT		; Initialize the error counter
	MVI	A,1
	STA	CRCFLG		; Make sure in CRC mode
	LDA	FILECT		; Any files to send?
	ORA	A
	JZ	CCHECK		; If not exit and wait for 'C'
;
	LHLD	NBSAVE		; Get current file name
	LXI	D,FCB		; Move it into the FCB
	MVI	B,12
	CALL	MOVE
	SHLD	NBSAVE
	LHLD	RECPTR		; Where to load the 0 block
	XCHG			; Put into DE
	LXI	H,FCB+1
	MVI	B,8
;
SKMD0:	MOV	A,M
	ANI	7FH		; Strip any high bit set
	ORA	A
	JZ	SKMD5		; Null pathname
	CPI	' '
	JZ	SKMD2
;
SKMD1:	CALL	LCASE		; Put file name in lower case for UNIX
	STAX	D
	INX	H
	INX	D
	DCR	B
	JNZ	SKMD0
	JMP	SKMD3
;
SKMD2:	INX	H		; Skip over spaces is short name
	DCR	B
	JNZ	SKMD2
;
SKMD3:	MOV	A,M
	CPI	' '
	JZ	SKMD5		; Missing file type field
	MVI	A,'.'		; Send name-type seperator
	STAX	D
	INX	D
	MVI	B,3
;
SKMD4:	MOV	A,M
	ANI	7FH		; Strip any high bit set
	CPI	' '
	JZ	SKMD5
	CALL	LCASE		; Put extent in lower case for UNIX
	STAX	D
	INX	H
	INX	D
	DCR	B
	JNZ	SKMD4
;
SKMD5:	XCHG			; Get the address back to HL
;
SKMD6:	MVI	M,0		; Fill rest of block with zeroes
	INR	L
	JNZ	SKMD6
;
	MVI	C,FILSIZ
	LXI	D,FCB
	CALL	BDOS
	LHLD	FCB+33
	SHLD	BUFSTR		; Store the file length at end of block
	XRA	A
	STA	RCDCNT		; Special header starts with 0
;
;
; Wait for a 'C' from remote system
;
CCHECK:	MVI	E,60
;
CCHECK1:CALL	CKABORT
	MVI	B,1
	CALL	RECV
	JC	CCHECK2		; No character, decrement counter
	CPI	CANCEL
	CZ	CKCAN		; Check for cancel
	CPI	CRC
	JZ	SKMD7
	JMP	CCHECK1
;
CCHECK2:DCR	E		; One less loop to go
	JNZ	CCHECK
	JMP	ABORTX
;
;
; Got a 'C' so either send the file or terminate batch, if no more files
;
SKMD7:	LDA	FILECT		; Any files to send?
	ORA	A
	JZ	KMDEND		; If not, terminate batch send
	DCR	A		; Else decrement count for this file
	STA	FILECT
	LXI	H,FILECT
;
;
; Now send the 128-byte file name record
;
SKMD8:	XRA	A
	STA	KFLG
	MVI	A,SOH		; Send SOH
	CALL	SEND
	CALL	SNDHNM		; Send header (record number, inverse)
	CALL	SNDREC		; Send a 128 byte record
	CALL	SNDCRC		; Send a two byte CRC
	CALL	GTACK		; Get the ACK
	CPI	ACK		; Was it an 'ACK'?
	JNZ	SKMD8		; If not, send the header block again
	LDA	XMODEM		; User want's 128 byte blocks?
	ORA	A
	JZ	SKMD9		; Yes
	MVI	A,1
	STA	KFLG		; Use 1k blocks in batch
;
SKMD9:	XRA	A		; Clear the carry flag
	STA	ERRCT		; Start fresh for the main file
	RET
;.....
;
;
KMDEND:	XRA	A
	LHLD	RECPTR
	MOV	M,A
	STA	RCDCNT
	STA	KFLG
	MVI	A,SOH
	CALL	SEND
	CALL	SNDHNM
	CALL	SNDREC
	CALL	SNDCRC
	STC
	RET
;.....
;
;
; Wait for line to get quiet and gobble characters
;
WAITQ1:	MVI	B,1
	CALL	RECV
	JNC	WAITQ1
	RET
;.....
;
;
; Send the MODEM7 batch file name
;
SNDNM:	PUSH	H
;
SNDNM1:	MVI	D,11		; Count characters in name
	MVI	C,0		; Initialize checksum
	LXI	H,FCB+1		; Address name
;
NAMLPS:	MOV	A,M		; Send name
	ANI	7FH		; Strip high order bit so CP/M2
	CALL	SEND		;   will not send R/O file designation.
;
ACKLP:	PUSH	B		; Save checksum
	MVI	B,5		; Wait for receiver to acknowledge
	CALL	RECV		;   getting the character
	POP	B
	JC	SCKSER
	CPI	ACK
	JNZ	ACKLP
	INX	H		; Next character
	DCR	D
	JNZ	NAMLPS
	MVI	A,EOFCHAR	; Tell receiver the end of name
	CALL	SEND
	MOV	D,C		; Save checksum
	MVI	B,5		; Wait up to 5 seconds
	CALL	RECV		; Get checksum
	CMP	D
	JNZ	SCKSER		; Exit if bad name
	MVI	A,OKNMCH	; Good name-tell receiver
	CALL	SEND
	POP	H
	RET
;.....
;
;
SCKSER:	MVI	A,BDNMCH	; Bad name-tell receiver
	CALL	SEND
	CALL	ILPRT
	DB	CR,LF,'++ ERROR sending name  ++',CR,LF,0
	MVI	E,60		; Do handshaking over (2 minutes maximum)
	CALL	WAITNAK		; See what protocol the user has
	CALL	SNDACK
	JMP	SNDNM1
;.....
;
;
GETFN:	LXI	H,FCB
	CALL	INITFCB1	; Does not initialize drive
	LDA	KMDODE		; Yam batch supported?
	ORA	A
	JZ	RCVKMD		; Yes, go to alternate routine
;
	CALL	ILPRTQ
	DB	CR,LF,'Awaiting file name',CR,LF,0
	CALL	HSNAK
	CALL	GETNM		; Get the name
	CPI	EOT		; If EOT, then no more files
	JZ	GETFN1
	ORA	A		; Clear carry
	RET
;
GETFN1:	STC			; Set carry to show no more files
	RET
;.....
;
;
;-----------------------------------------------------------------------
;		     KMD receive batch mode
;
RCVKMD:	XRA	A		; Initialize the error counter
	STA	RCVTRY
	CALL	CATCH		; Clear the decks for action
;
RKMD1:	CALL	CKABORT		; Check for user abort
	MVI	B,3		; Wait up to 3 sec. for SOH from remote
	CALL	RECV
	JC	RKMD2		; No character, decrement counter
	CPI	CANCEL		; Was it a CTL-X for cancel?
	CZ	CKCAN		; Abort if yes
	CPI	SOH		; SOH is all we are interested in
	JZ	RKMD4
	JMP	RKMD1		; Anything else, ignore
;
RKMD2:	MVI	A,CRC		; Send a 'C'
	CALL	SEND
;
RKMD3:	LDA	RCVTRY		; Increment the "try" counter
	INR	A
	STA	RCVTRY
	CPI	20		; Tried 1 minute yet?
	JC	RKMD1
	JMP	ABORT		; Quit and try to force him to quit
;
RKMD4:	MVI	B,5		; 5 seconds to get sector number
	CALL	RECV
	JC	KMDTOT		; No character, exit
	MOV	D,A		; Save sector number in D
	ORA	A
	JNZ	KMDHDR		; Must be a 0 if sending batch header
	MVI	B,5		; 5 seconds to get reciprocal
	CALL	RECV
	JC	KMDTOT		; No character, exit
	CMA			; Invert it and compare to sector #
	CMP	D
	JNZ	KMDCRC		; Bad match
	LXI	H,0
	SHLD	CRCVAL		; Clear CRC counter
	MVI	E,128
	LHLD	RECPTR		; Get buffer address
;
RKMD5:	MVI	B,5		; 5 seconds to get 128 byte header block
	CALL	RECV
	JC	KMDTOT		; No character, exit
	MOV	M,A		; Store the character in the buffer
	INX	H		; Next buffer address
	DCR	E		; One less to go
	JNZ	RKMD5		; If not, room for another character
	MVI	E,2
;
RKMD6:	MVI	B,5
	CALL	RECV		; Get CRC bytes
	JC	KMDTOT		; No character, exit
	DCR	E		; Done?
	JNZ	RKMD6		; No
	CALL	CRCCHK		; Compare CRC received against ours
	ORA	A		; Ok?
	JNZ	KMDCRC		; No
	CALL	SNDACK		; Yes, acknowledge to remote
;
;
; Decode pathname into CPM format
;
	LXI	D,FCB+1		; Where to put it
	LHLD	RECPTR		; Where to get it
	MVI	B,8		; Filename length
;
RKMD7:	MOV	A,M		; Get the character from the buffer
	ORA	A		; Was it a zero?
	JZ	RKMD12		; If yes, all done
	CPI	'.'		; Was it a delimiter?
	JZ	RKMD9
	CPI	'_'		; Unix can't handle this properly
	JNZ	RKMD8
	MVI	A,'/'		; Change it to a slash
;
RKMD8:	CALL	UCASE		; Insure name is in upper case
	STAX	D		; Store filename character in FCB
	INX	D		; Increment pointers
	INX	H
	DCR	B		; One less to go
	JNZ	RKMD7		; If not 8, keep going
;
	MOV	A,M		; Get the character back
	ORA	A		; We had 8, was there an extent?
	JZ	RKMD11		; If zero, was all done
	JMP	RKMD10		; Else must be a '.'
;
RKMD9:	MVI	A,' '		; Spaces to make up 8 spaces for name
	STAX	D		; Store space character in FCB
	INX	D		; Increment pointers
	DCR	B		; One less to go
	JNZ	RKMD9		; Keep going until in extent area
;
RKMD10:	INX	H		; Skip the '.' position
	MVI	B,3		; Extent length

RKMD11:	MOV	A,M		; Get the character from the buffer
	ORA	A		; Was it a zero?
	JZ	RKMD12		; If yes, all done
	CALL	UCASE		; Insure extent is in upper case
	STAX	D		; Store extent character
	INX	D		; Increment pointers
	INX	H
	DCR	B		; One less to go
	JNZ	RKMD11		; Keep going until finished
;
RKMD12:	LDA	FCB+1		; See if there was any filename at all
	CPI	' '
	STC
	RZ			; No - end of batch
;
	LDA	QFLG
	ORA	A
	RZ
;
	CALL	ILPRTQ
	DB	CR,LF,'File name: ',0
	LHLD	RECPTR		; Print filename
;
RKMD13:	MOV	A,M
	ORA	A
	JZ	RKMD14		; If zero, end of filename
	CALL	UCASE
	CALL	TYPE
	INX	H
	JMP	RKMD13
;
RKMD14:	LHLD	BUFSTR		; Get the file length, if provided
	MOV	A,H
	ORA	L
	JZ	RKMD15		; If both zero, length not provided
;
	SHLD	RCNT		; Store the file length
	CALL	CRLF		; Start a new line
	CALL	SNDTM
;
	CALL	ILPRTQ
	DB	'k)',CR,LF,'Recv time: ',0
	LXI	H,KECTBL
	SHLD	RECTBL+1
	CALL	KTIM
	CALL	SNDTM1
;
RKMD15:	CALL	CRLF		; Finish the filename line
	XRA	A		; Reset the carry flag
	STA	RCVTRY		; Reset the error counter
	RET
;.....
;
;
KMDCRC:	CALL	ILPRTQ
	DB	'++ CRC error ++',CR,LF,0
	JMP	KMDXFR
;.....
;
;
KMDHDR:	CALL	ILPRTQ
	DB	'++ Wrong header type ++',CR,LF,0
	JMP	KMDXFR

;.....
;
;
KMDTOT:	CALL	ILPRTQ
	DB	'++ Time out receiving filename ++',CR,LF,0
;...
;
;
KMDXFR:	MVI	B,1		; Make sure sender has stopped
	CALL	RECV
	JNC	KMDXFR		; If not, wait until all sending stops
	MVI	A,NAK		; Tell sender it was not successful
	CALL	SEND
	LDA	RCVTRY		; Increment the error counter
	INR	A
	STA	RCVTRY
	CPI	33		; Same as value in RKMD2
	JC	RKMD3		; Send a NAK and tell him to try again
	JMP	ABORT		; Else abort
;.....
;
;		  end of KMD get batch file name
;-----------------------------------------------------------------------
;		    MODEM7 geta batch file name
;
GETNM:	PUSH	H
;
GETNM1:	MVI	A,0FFH
	STA	FLTRFLG
	MVI	C,0		; Initialize checksum
	LXI	H,FCB+1
;
NAMELPG:MVI	B,5
	CALL	RECV		; Get the character
	PUSH	B
	PUSH	PSW
;
	MVI	A,0FFH		; Set the TIMFLG
	STA	TIMFLG
;
	MVI	B,1
	CALL	RECV
;
	XRA	A
	STA	TIMFLG
;
	POP	PSW
	POP	B
	JNC	GETNM3
	CALL	ILPRTQ
	DB	'Time out receiving filename',CR,LF,0
	JMP	GCKSER
;
GETNM3:	CPI	EOT		; If EOT, then no more files
	JZ	GNRET
	CPI	EOFCHAR		; Got end of name
	JZ	ENDNAME
	PUSH	PSW
	PUSH	B
	CALL	SNDACK
	POP	B
	POP	PSW
	MOV	M,A		; Put name in FCB
	INX	H		; Get next character
	MOV	A,L		; Don not let noise cause overflow..
	CPI	7FH		; Into the program area.
	JZ	GCKSER
	JMP	NAMELPG
;
ENDNAME:XRA	A
	STA	FLTRFLG
	MOV	A,C		; Send checksum
	MOV	D,C
	CALL	SEND
;
NMLP1:	MVI	B,5		; Wait up to 5 second to see if..
	CALL	RECV		; The checksum is good
	CPI	OKNMCH		; Yes if 'OKNMCH' sent
	JZ	GNRET
	CMP	D
	JZ	NMLP1		; In case it is echo of send
	CPI	CR
	JZ	NMLP1
	CPI	LF
	JZ	NMLP1
;
GCKSER:	LXI	H,FCB		; Clear FCB (except drive) since it..
	CALL	INITFCB1	; Might be damaged.
	CALL	ILPRTQ
	DB	CR,LF,'**  Checksum error  **',CR,LF,0
	XRA	A
	STA	FLTRFLG
	CALL	HSNAK		; Do handshaking over
	JMP	GETNM1
;
GNRET:	PUSH	PSW
	XRA	A
	STA	FLTRFLG
	POP	PSW
	POP	H
	RET
;
HSNAK:	MVI	E,180		; 3 minute wait for file name
	XRA	A
	STA	FLTRFLG
;
HSNAK1:	CALL	CKABORT		; Want to abort?
	MVI	A,NAK		; Send 'NAK' until receiving 'ACK'
	CALL	SEND
	MVI	B,1		; Wait up to 1 second for a character
	CALL	RECV
	CPI	ACK		; 'ACK' is what we were waiting for
	RZ
	DCR	E
	JNZ	HSNAK1
	JMP	ABORT		; Back to command line
;.....
;
;
TNMBUF:	MVI	A,1		; Call from 'SNDFL' only once.
	STA	FSTFLG
	XRA	A
	STA	FILECT
	CALL	SCAN
	LXI	H,NAMEBUF
	SHLD	NBSAVE		; Save address of 1st name
;
TNLP1:	CALL	TRTOBUF
	LXI	H,FCB
	LXI	D,FCBBUF
	CALL	CMDLINE		; Parse name to CP/M format
;
TNLP2:	CALL	MFNAM		; Search for names (wildcard format)
	JC	NEXTNM
	MVI	C,FILSIZ
	LXI	D,FCB
	CALL	BDOS
	LHLD	FCB+33		; Get number of records
	MOV	A,H
	ORA	L
	JZ	TNLP2		; If no records, don't copy this file
	LDA	FCB+10		; If CP/M 2 $sys file..
	ANI	80H		; Do not send
	JNZ	TNLP2
	LHLD	NBSAVE		; Get name
	LXI	D,FCB		; Move it to FCB
	XCHG
	MVI	B,12
	CALL	MOVE
	XCHG
	SHLD	NBSAVE		; Addressof next name
	LXI	H,FILECT	; Count files found
	INR	M
	JMP	TNLP2
;.....
;
;
NEXTNM:	LXI	H,NAMECT	; Count names found
	DCR	M
	JNZ	TNLP1
	LXI	H,NAMEBUF	; Save start of buffer
	SHLD	NBSAVE

;~this limit is an antique.  allow up to FFh (256 files) by deleting
; this routine
;	LDA	FILECT
;	CPI	64+1		; No more than 64 transfers
;	RC
;	MVI	A,64		; Only transfer first 64
;	STA	FILECT
	RET
;.....
;
;
; Tells when buffer is opened/closed for memory save to write on disk
;
BUFMS:	CALL	ILPRT
	DB	CR,LF,'** Memory buffer ',0
	LDA	SAVEFLG
	ORA	A
	JZ	BUFMS1
	CALL	ILPRT
	DB	'open **',CR,LF,LF,';',0
	RET
;
BUFMS1:	CALL	ILPRT
	DB	'closed **',CR,LF,LF,0
	RET
;
BUFMS2:	CALL	ILPRT
	DB	CR,LF,'** Memory buffer available **',CR,LF,0
	RET
;.....
;
;
; Checks to see if the modem has a character ready
;
RCVRDY:	CALL	I$MDCTL1	; Get the status register
	CALL	A$MDRCV		; AND it with the receive ready flag
	JMP	C$MDRCV		; Compare to see if it has a character
;.....
;
;
; Checks to see if the modem is ready to receive a character
;
SNDRDY:	CALL	I$MDCTL1
	CALL	A$MDSND		; Isolate the
	JMP	C$MDSND
;.....
;
;
SNDNOW:	CALL	EXITTEST	; See if want to quit now
	CALL	SNDRDY		; Ready to send a character?
	JNZ	SNDNOW		; If not ready wait some more
	RET			; Exit if ready
;.....
;
;
; Checks to see if the modem TxE output buffer is empty
;
SNDTXE:	CALL	I$MDTXE		; Get the status register with TxE flag
	CALL	A$MDTXE		; Isolate the TxE flag
	JMP	C$MDTXE		; Compare to see if it is empty

;.....
;
;
; Send the log-on message when requested
;
SNDLOG:	LHLD	LOGPTR		; 'HL' points to start of logon message
	CALL	LOGLP
	JMP	TERML
;...
;
;
LOGLP:	CALL	SNDNOW		; Wait until modem is ready
	MOV	A,M		; Get logon byte
	ORA	A		; Last character in string is '0'
	RZ			; Return if finished
	CALL	O$MDDATP	; Otherwise send the character
	CALL	LOGLP1		; Check for echo character and display it
	INX	H		; Next location in message
	JMP	LOGLP		; Get next character
;.....
;
;
LOGLP1:	CALL	J$INMDM		; Get the echo character
	RC			; If no character don't try to print
	ANI	7FH		; Strip off any parity
	JMP	TYPE		; Display the character, then return
;.....
;
;
; Check for exit character
;
EXITTEST:
	CALL	STAT		; Anything on keyboard?
	RZ
	CALL	KEYIN		; Get it, then
	MOV	B,A		; Save to protect the 'A' reg.
;
EXITTST1:
	LDA	EXITCHR		; Exit character
	CMP	B		; Asking to exit to menu?
	RNZ			; If not, back to work
	POP	H		; Clear the stack from 'CALL'
	CALL	CRLF
	JMP	MENU0
;.....
;
;
LSTMS:	CALL	ILPRT
	DB	'Printer buffer is ',0
	LDA	LISTFLG		; See if printer should be on or off
	ORA	A
	JZ	LSTMS1
	CALL	ILPRT
	DB	'ON',CR,LF,0
	RET
;...
;
;
LSTMS1:	CALL	ILPRT
	DB	'OFF',CR,LF,0
	RET
;.....
;
;
; Special function key handler.  This routine is entered with the
; function key number (0..9) in A.  The corresponding function key is
; then transmitted.
;
SNDFK:	PUSH	H		; Save register
	LXI	H,FNCTBL	; Point to function key codes
	DCR	A		; Table is 1-0 rather than 0-9
	CPI	0FFH
	JNZ	SFK1
	MVI	A,9
;
SFK1:	CMP	M		; This the one?
	INX	H		; Point to next byte
	JNZ	SFK1		; Loop until found
	CALL	LOGLP		; Send the character
	POP	H
	XRA	A		; Reset the function flag
	STA	FNKFLG
	JMP	TERML
;.....
;
;
; Send keyboard character to modem, also to console if "E" or "L".  If
; "E", include a LF after a CR, if either, include a LF if toggle is set.
;
NTOG:	CALL	J$SNDCHR	; Send char. in 'B' to modem
	LDA	LOCFLG		; Using the local mode?
	ORA	A
	JNZ	LTYPE		; If yes, show the character
	LDA	ECHOFLG		; In echo mode?
	ORA	A
	JZ	TERML		; If not, see if it was a 'CR'
;
LTYPE:	MOV	A,B		; Get the character back
	CALL	TYPE		; Show on the local CRT
	CALL	CKSAV		; To store local if buffer open
	CALL	CHKPRNT		; Put on printer if running
;
CHKCR:	MVI	A,CR
	CMP	B
	JNZ	TERML		; If not CR, all done
	LDA	ECHOFLG		; In echo mode now?
	ORA	A
	JNZ	CHKLF		; If yes add a line feed
	LDA	ADDLFD		; Going to add a line feed in 'L' mode?
	ORA	A
	JZ	TERM		; If not, exit
;
CHKLF:	MVI	B,LF
	JMP	NTOG		; Send locally and to remote
;.....
;
;
TERML:	CALL	RCVRDY		; Character on the receive-ready line?
	JNZ	TERM		; If not, exit
	CALL	I$MDDATP	; Get the character
	ANI	7FH		; Strip parity
	JZ	TERM		; Don't bother with nulls
	CPI	RUB
	JZ	TERM		; Don't bother with rubouts for fill
	MOV	B,A		; Store temporarily
	LDA	IGNRCTL		; Ignoring all but necessary CTL-chars?
	ORA	A
	JZ	GIVLF		; If zero, display them all
	MOV	A,B
	CPI	' '
	JNC	GIVLF		; Display all printing characters
	CPI	'G'-40H		; ^g for bell
	JC	TERM		; Ignore ctl-characters less than ^g
	CPI	CR+1
	JNC	TERM		; Ignore ctl-characters more than ^m
;
GIVLF:	MOV	A,B		; Get the character back
	CALL	TYPE		; Show it on the CRT
	CALL	CKSAV		; Saving for disk file?
	CALL	CHKPRNT		; Printer running?
	LDA	ECHOFLG		; Going to echo the character?
	ORA	A
	JZ	NOECH		; If not, do not resend
	CALL	J$SNDCHR	; Send char. in 'B' to modem
;
NOECH:	MVI	A,CR
	CMP	B		; Was it a 'CR' just now?
	JNZ	TERM		; If not, all done so exit
	LDA	ECHOFLG		; In the echo mode?
	ORA	A
	JZ	TERM
	CALL	SNDNOW		; Modem ready for a character?
	MVI	B,LF
	JMP	GIVLF		; Send lf
;.....
;
;
; See if putting character into memory for a disk file
;
CKSAV:	LDA	SAVEFLG		; Saving to disk?
	ORA	A
	RZ			; If not, exit
	LHLD	HLSAV		; Get last address
	MOV	M,B		; Store this character
	INX	H		; Increment for next character
	SHLD	HLSAV		; Remember that location
	MVI	A,LF
	CMP	B		; This character a line feed?
	JNZ	CKSAV1		; Type ";" after each line feed..
	MVI	A,CR		; Insure at left column with a lf
	CALL	TYPE
	CALL	TYPESCLN	; Show a ';' on CRT
;
CKSAV1:	MOV	A,H
	LXI	H,BUFTOP	; Get the address at top of buffer
	CMP	H
	CZ	DCTLS		; If different, buffer is not full
	RET
;.....
;
;
; Memory buffer is full, send a X-OFF (CTL-S, DC3), save any extra in-
; coming characters, then dump to disk, reset buffer to include those
; characters.
;
DCTLS:	CALL	SNDNOW		; Modem ready for a character?
	MVI	A,XOFF		; Send a ctl-s to stop remote computer
	CALL	O$MDDATP
	CALL	CHKPRNT		; Insure character gets to the printer
	LXI	H,BUFFDSK	; Address of aux. buffer
	CALL	GTDSK		; Put any extra chars. into aux. buffer
	PUSH	D		; Save the number of aux. chars.
	MVI	A,1		; Show we put something in the buffer..
	STA	WRFLG		; To protect erasing an empty file
	LHLD	HLSAV		; Find current end of buffer
	CALL	WRDSK1		; Write the records
	POP	D		; Get aux. char. count back
	LXI	H,BUFFER	; Start again at bottom of buffer
	XRA	A		; Set 'A' to zero
	CMP	D		; See if any count in 'D'
	JZ	DCTLQ		; If nothing, exit and continue
	LXI	B,BUFFDSK	; Address of aux. buffer
;
;
; Move the characters from the auxiliary buffer to the main buffer and
; display
;
DCTLS1:	LDAX	B		; Get the character there
	MOV	M,A		; Store in main buffer
	CALL	TYPE		; Show on CRT
	PUSH	H
	PUSH	D
	PUSH	B
	PUSH	PSW
	MOV	B,A
	CALL	CHKPRNT
	POP	PSW		; Get the character again
	POP	B
	POP	D
	POP	H
	CPI	LF
	CZ	TYPESCLN
	INX	H		; Next buffer position
	INX	B		; Next aux. buffer position
	DCR	D		; One less to go
	JNZ	DCTLS1		; If not zero, keep going
	MVI	B,0		; Falls through to 'CHKPRNT' next
;
DCTLQ:	SHLD	HLSAV		; Next position to store in buffer
	CALL	SNDNOW
	MVI	A,XON		; Allow remote input to continue
	JMP	O$MDDATP
;.....
;
;
; Gets any incoming characters after sending an XOFF and stores at HL.
; Returns with number of characters stored in D-reg.
;
GTDSK:	MVI	D,0		; Character count in buffer
	MVI	E,128		; Maximum for buffer length
;
GTDSK1:	CALL	J$INMDM		; Get any character
	RC			; If none, finished
	CPI	' '
	JNC	GTDSK2		; If greater, handle normally
	CPI	CR+1		; Ignore ctl-chars. > cr
	JNC	GTDSK1
;
GTDSK2:	MOV	M,A		; Store
	INX	H		; Next buffer location to use
	INR	D		; Increment character count
	DCR	E		; Room for one less
	JNZ	GTDSK1		; If room in buffer, keep going
	RET			; If buffer is filled, exit
;.....
;
;
; See if printing the character, if yes, put into buffer
;
CHKPRNT:LDA	LISTFLG		; Printer in use?
	ORA	A
	RZ			; Return if not
	LHLD	HLSAV1		; Get input address
	MOV	M,B		; Save this character there
	INX	H		; Increment the buffer location
	SHLD	HLSAV1		; Store for next character
	LDA	MAXRAM		; See if at top of buffer yet
	CMP	H
	CZ	PCTLS		; If different, buffer is not full
	RET
;.....
;
;
; Memory buffer is full, send a X-OFF (CTL-S, DC3), save any extra in-
; coming characters, then dump to disk, reset buffer to include those
; characters.
;
PCTLS:	CALL	SNDNOW		; Wait until modem is ready
	MVI	A,XOFF		; Send a ctl-s to stop remote computer
	CALL	O$MDDATP
	LXI	H,BUFFPNT	; Address of aux. buffer
	CALL	GTDSK		; Put any extra chars. into aux. buffer
	MOV	A,D		; Get the aux. buffer char. count
	STA	DSTORE		; Save for later
	RET
;.....
;
;
; Output has now caught up to the input and both are at top of buffer
;
PCTLS1:	LDA	DSTORE		; Get the aux. buffer char. count
	MOV	D,A		; Put into 'D' reg.
	XRA	A		; Set 'A' to zero
	CMP	D		; See if any count in 'D'
	LXI	H,PBUFF		; Address at start of printer buffer
	JZ	PCTLQ		; If nothing, exit and continue
	LXI	B,BUFFPNT	; Address of aux. buffer
;
;
; Move the characters from the auxiliary buffer to the main buffer and
; display.
;
PCTLS2:	LDAX	B		; Get the character there
	MOV	M,A		; Store in main buffer
	CALL	TYPE		; Show on CRT
	PUSH	H
	PUSH	D
	PUSH	B
	PUSH	PSW
	MOV	B,A
	CALL	CKSAV
	POP	PSW
	POP	B
	POP	D
	POP	H
	CPI	LF
	CZ	TYPESCLN
	INX	H		; Next buffer position
	INX	B		; Next aux. buffer position
	DCR	D		; One less to go
	JNZ	PCTLS2		; If not zero, keep going
;
PCTLQ:	SHLD	HLSAV1		; Next position to store in buffer
	LXI	H,PBUFF		; Start of buffer location
	SHLD	HLSAV2		; Output to start of buffer
	CALL	SNDNOW		; Wait until modem is ready
	MVI	A,XON		; Send start character..
	JMP	O$MDDATP	; To remote computer, back to work
;.....
;
;
; List the character on the printer if it is ready, then see if at the
; top of the buffer.
;
GOLIST:	CALL	$-$		; Get the printer status - filled in..
	ORA	A		; By 'INITADR' routine
	RZ			; Return if printer not ready
;
;
; Compare input and output pointers.  If at same address, nothing to
; print.
;
	CALL	CMP$I$O		; If the same, nothing to print
	RZ
;
;
; If not the same, print the character
;
	PUSH	H		; Save current buffer address
	MOV	E,M		; Get the character to display
	MVI	C,LIST		; List rutine
	CALL	BDOS
	POP	H		; Restore current buffer address
	INX	H		; Increment pointer for next position
	SHLD	HLSAV2		; Store for next time through here
;
;
; See if the output is at the end of the buffer now.  If yes, go put
; the auxiliary characters into the start of the buffer.
;
	LDA	MAXRAM		; Check for end of buffer area
	CMP	H
	JZ	PCTLS1		; If at end, restore aux. buffer
;
;
; See if the output has caught up with the input - if so, reset the
; pointers to the start of the buffer
;
	CALL	CMP$I$O
	RNZ			; If not, back to work
	LXI	H,PBUFF		; If output caught input, reset both..
	SHLD	HLSAV1		; To bottom of buffer to start over
	SHLD	HLSAV2
	RET
;.....
;
;
; Compare the input and output pointers to see if the same address
;
CMP$I$O:LHLD	HLSAV1		; Get input pointer address
	XCHG			; Put in 'DE'
	LHLD	HLSAV2		; Get output pointer address
	MOV	A,H
	CMP	D
	RNZ			; Return if different
	MOV	A,L
	CMP	E
	RET
;.....
;
;
GTMAX:	LDA	BDOS+2		; 'MSP' of 'BDOS' address
	SBI	8		; 'CCP' is 2k or 8 pages
	STA	MAXRAM		; Save
	RET
;.....
;
;
; This subroutine will loop until the modem receives a character or 100
; milliseconds.  It returns with a character in 'A' reg. but if no char-
; acter was recieved it returns after a timeout with carry set.
;
INMDM:	PUSH	H
	LXI	H,63		; About 100 milliseconds
	CALL	FIXCNT
	MOV	B,H		; Delay is in 'HL'
	MOV	C,L		; Transfer to 'BC'
	POP	H		; Get original value of 'HL' back
;
INMDM1:	CALL	RCVRDY		; See if there is a character ready
	JNZ	INMDM2		; If no character, exit
	CALL	I$MDDATP	; Get the character
	ANI	7FH		; Strip off any parity
	RET			; Return with character in 'A' reg.
;
INMDM2:	DCX	B		; Otherwise keep timing
	MOV	A,B
	ORA	C
	JNZ	INMDM1		; Loop until timeout if needed
	STC			; Shows a timeout occured
	RET
;.....
;
;
;=======================================================================
;		     WRITE BUFFER TO DISK
;
; Make sure this record is included in the count.
;
WRDSK:	LHLD	HLSAV
	MVI	M,EOFCHAR	; Ascii file, store end-of-file char.
	LXI	D,127
	DAD	D
;
WRDSK1:	LXI	D,-(BUFFER)	; Subtract the start of the buffer..
	DAD	D		; By adding a minus number to buffer end
	MOV	A,L		; Divide hl by 128..
	ORA	A
	RAL			; To get the..
	MOV	L,H		; Number of records
	MVI	H,0
	PUSH	PSW
	DAD	H
	POP	PSW
	MVI	A,0
	ADC	L
	MOV	L,A		; Number of records in 'HL'
;
;
; See if buffer is empty.  If yes, see if we need to erase an empty
; file or have already written something.
;
	LXI	D,BUFFER
	LDAX	D
	CPI	EOFCHAR		; 'EOF' in first address means..
	JNZ	WRDSK2		; Nothing in buffer to write
	LDA	WRFLG		; First time by this way?
	ORA	A
	JZ	NOWRITE		; If yes, show erasing file
	RET			; Otherwise go close file
;.....
;
;
; Write to disk.  Start from BUFFER (in 'DE').	Number of records to
; write in 'HL'.
;
WRDSK2:	MVI	C,STDMA
	CALL	BDOSRT
	PUSH	D
	MVI	C,WRITE
	LXI	D,FCB3		; Location of filename to write to
	CALL	BDOSRT
	POP	D
	ORA	A
	JNZ	WRERRSP		; Error if disk is full ** special patch
	XCHG			; Put the current address in 'HL'..
	PUSH	D		; And number of records left in..
	LXI	D,128		; For now
	DAD	D		; Add for next record write, now in 'HL'
	POP	D		; Restore number of records left
	XCHG			; Records to 'HL' again, address to 'DE'
	DCX	H		; One less record left
	MOV	A,H
	ORA	L		; Done writing when 'H' and 'H' both zero
	JNZ	WRDSK2		; Otherwise do another disk write
	RET
;.....
;
;
; Error while writing a record, show why it is aborting
;
WRERR:	CALL	CLOSFIL		; Close the current file
	MVI	C,CANCEL	; Send cancel char. to sending station
	CALL	SEND		; First cancel character
	CALL	SEND		; Second cancel character
	CALL	SEND		; Third, to help them cancel too
;
WRERR1:	CALL	ERXIT		; Also will reset stack
	DB	'++ DISK FULL, SAVING PARTIAL FILE ++','$'
;.....
;
;
; Patch to close FCB3 instead of FCB when in disk-capture mode.
;
WRERRSP:CALL	WRFIL2		; Close FCB3 file
	JMP	WRERR1		; Go write 'DISK FULL' message and quit
;.....
;
;
; If no data to store on the disk, close the empty file and erase it
;
NOWRITE:CALL	WRFIL2		; Close the empty file
	CALL	NOASK		; Erase the empty file
	CALL	ILPRT
	DB	CR,LF,'++ Nothing to save, erasing file ++'
	DB	CR,LF,BELL,0
	LDA	DONEFLG		; Is the exit flag set?
	ORA	A
	JNZ	EXIT2		; If yes, all done now
	MVI	A,1		; Set the flag
	STA	ABORTFLG	; Insures returning to command mode
	JMP	DONETA		; Reset any flags, return to menu
;.....
;
;
; Show you are in memory-save for disk write
;
TYPESCLN:
	MVI	A,';'
	JMP	TYPE		; Show on CRT, return
;.....
;
;
; Save the registers, call BDOS then restore the registers
;
BDOSRT:	PUSH	B
	PUSH	D
	PUSH	H
	CALL	BDOS
	POP	H
	POP	D
	POP	B
	RET
;.....
;
;
INITFCB:MVI	M,0		; Zeroes the drive to the 'A' drive
;
INITFCB1:			; Does not alter disk drive
	INX	H
	MVI	B,11		; Spaces out filename area
;
LOOP11:	MVI	M,' '
	INX	H
	DCR	B
	JNZ	LOOP11		; Nulls out the data area with zeroes
	MVI	B,21
;
LOOP21:	MVI	M,0
	INX	H
	DCR	B
	JNZ	LOOP21
	RET
;.....
;
;
; Scans CMDBUF counting names and putting delimiter (space) after last
; name
;
SCAN:	PUSH	H
	LXI	H,NAMECT
	MVI	M,0
	LXI	H,CMDBUF+1	; Find end of cmd line..
	MOV	C,M		; And put space there.
	MVI	B,0
	LXI	H,CMDBUF+2
	DAD	B
	MVI	M,' '
	LXI	H,CMDBUF+1
	MOV	B,M
	INR	B
	INR	B
;
SCANL1:	INX	H
	DCR	B
	JZ	DNSCAN
	MOV	A,M
	CPI	' '
	JNZ	SCANL1
;
SCANL2:	INX	H		; Eat extra spaces
	DCR	B
	JZ	DNSCAN
	MOV	A,M
	CPI	' '
	JZ	SCANL2
	SHLD	BGNMS		; Save start of names in cmdbuf
	INR	B
	DCX	H
;
SCANL3:	INX	H
	DCR	B
	JZ	DNSCAN
	MOV	A,M
	CPI	' '
	JNZ	SCANL3
	LDA	NAMECT		; Counts names
	INR	A
	STA	NAMECT
;
SCANL4:	INX	H		; Eat spaces
	DCR	B
	JZ	DNSCAN
	MOV	A,M
	CPI	' '
	JZ	SCANL4
	JMP	SCANL3
;.....
;
;
DNSCAN:	MVI	M,' '		; Space after last char
	POP	H
	RET
;.....
;
;
; Places next name in buffer so 'CMDLINE' may parse it
;
TRTOBUF:LHLD	BGNMS
	MVI	B,0
	LXI	D,FCBBUF+2
;
TBLP:	MOV	A,M
	CPI	' '
	JZ	TRBFEND
	STAX	D
	INX	H
	INX	D
	INR	B		; Count chars in name
	JMP	TBLP
;.....
;
;
TRBFEND:INX	H
	MOV	A,M		; Eat extra spaces
	CPI	' '
	JZ	TRBFEND
	SHLD	BGNMS
	LXI	H,FCBBUF+1	; Put # chars before name
	MOV	M,B
	RET
;.....
;
;
CKCPM2:	MVI	C,CPMVER	; Bdos 12 -- version number -- cp/m 2.2?
	CALL	BDOS
	ORA	A
	RZ
	MVI	C,STDMA
	LXI	D,TBUF
	CALL	BDOS
	MVI	C,SRCHF
	LXI	D,FCB
	CALL	BDOS
	CPI	0FFH
	RZ
;
	CALL	GETADD
	LXI	D,9
	DAD	D		; Point to R/O attribute byte
	MOV	A,M
	ANI	80H		; Test most significant byte
	JNZ	MKCHG		; If set, make change
	INX	H		; Check system attribute byte
	MOV	A,M
	ANI	80H
	RZ			; Not $SYS or $R/O attribute
	DCX	H
;
MKCHG:	LXI	D,-8
	DAD	D		; Point HL to filename + 1
	LXI	D,FCB+1		; Move directory name to FCB..
	MVI	B,11		; Without changing drive.
	CALL	MOVE
	LXI	H,FCB+9		; R/O attribute
	MOV	A,M
	ANI	7FH		; Strip R/O attribute
	MOV	M,A
	INX	H		; System attribute
	MOV	A,M
	ANI	7FH
	MOV	M,A
	LXI	D,FCB
	MVI	C,30		; Set new attributes in directory
	CALL	BDOS
	LXI	H,FCB		; Change name to type "BAK"
	LXI	D,FCB2
	MVI	B,9		; Move drive and name (not type)
	CALL	MOVE
	LXI	H,75H		; Start of type in FCB2
	MVI	M,'B'
	INX	H
	MVI	M,'A'
	INX	H
	MVI	M,'K'
	LXI	D,FCB2
	MVI	C,ERASE		; Erase any previous backups
	CALL	BDOS
	LXI	H,FCB2		; FCB2 drive field should..
	MVI	M,0		; 0 for rename.
	LXI	D,FCB
	MVI	C,23		; Rename
	JMP	BDOS
;.....
;
;
;***********************************************************************
;
;	    RECEIVE A RECORD FROM SENDING STATION
;
;***********************************************************************
;
; If CRC is in effect, there is a 10-second timeout to the first SOH.
; It then tries six more times to let the sender know the system is
; capable of receiving a 'CRC' check.  At the end of that time a NAK is
; sent which tells the sender to use CHECKSUM checking instead of CRC.
; This allows automatic compatability with systems implementing CRC -
; (Cyclic Redundancy Checking).  The search for SOH will cycle through
; one record interval and ignore noise or characters sent by the remote
; for any purpose (such as progress reporting).  So extraneous characters
; that are sometimes sent by remote-end protocol will be gobbled up until
; the first SOH.  EOT is tested only as the first returned character af-
; ter each sector.
;
SRCHSOH	EQU	160		; Number of times to loop search for SOH
;
RCVRECD:MVI	A,1
	STA	ERRCT		; Initialize the error count
;
RCVSQ:	CALL	CKABORT		; Want to quit now?
	MVI	B,10-1		; 10 seconds allowed to receive 1st char.
	LXI	D,SRCHSOH	; Initialize loop for up to 160 secs.
	CALL	RECV		; Get the 1st character
	JC	RCVSTOT		; Timeout error if not rcvd in 10 seconds
	MOV	C,A		; Save the character for now
	CPI	EOT		; See if end of transmission
	STC			; Set carry
	RZ			; Return with carry set
;
SOHLUP:	MVI	A,0FFH
	STA	CHRFLG
	STA	TIMFLG
	MOV	A,E		; Get search count-down value
	CPI	SRCHSOH		; See if it is the 1st returned character
	MOV	A,C		; Get the first character now
	JZ	NORECV		; Skip RECV routine if 1st character
	MVI	B,1
	CALL	RECV
	MOV	B,A		; Store the character again, for a bit
	JNC	TSTSOH
;
NORECV:	MOV	B,A
	XRA	A		; Else set the value that forces timeout
	STA	CHRFLG
;
TSTSOH:	XRA	A
	STA	TIMFLG
	MOV	A,B		; Get the character back
;
	CPI	SOH		; See if it is SOH
	JZ	RCVSOH		; Got SOH, get rcd # and its complement
	CPI	STX		; See if it is STX for 1k blocks
	JZ	RCVSTX		; Got STR, get rec # and its complement
	CPI	CANCEL
	CZ	CKCAN		; Check to see if 1st or 2nd one
;
	MOV	A,D
	ORA	E		; See if counted-down to zero
	DCX	D
	JNZ	SOHLUP		; Go around again if not
;
	LDA	CHRFLG		; See if timeout needs to be forced
	ORA	A
	JZ	RCVSTOT		; Go do timeout and count them
;
	LDA	QFLG
	ORA	A
	JZ	RCVSR
;
	CALL	CRLF
	MOV	A,B		; Get the character back
	CALL	HEXO		; And display it
	CALL	ILPRT
	DB	'H received not SOH - ',0
;
RCVPRN:	CALL	SHOWERR		; Display error count
;
RCVSR:	CALL	WAITQ1		; Clear any characters from the input
	CALL	CKABORT		; Want to stop receiving now?
	LDA	FRSTIM		; Get first time switch
	ORA	A		; Has first 'SOH' been received?
	MVI	A,NAK		; Put 'NAK' in 'A' reg.
	JNZ	RCVSR1		; Yes, then send 'NAK'
;
	LDA	CRCFLG		; Get 'CRC' flag
	ORA	A		; 'CRC' in effect?
	MVI	A,NAK		; Put 'NAK' in 'A' reg.
	JZ	RCVSR1		; No, send the 'NAK'
;
	MVI	A,CRC		; Else tell sender 'CRC' is in effect
	CALL	SEND
	LDA	KFLG		; Capable of 1k blocks?
	ORA	A
	JZ	RCVSR1		; If yes, start with 1k request
	MVI	A,KSND		; Tell sender we can use 1k blocks
;
RCVSR1:	CALL	SEND		; The 'NAK' or 'CRC' request
	LDA	ERRCT		; Abort if we have reached error limit
	INR	A
	STA	ERRCT		; Store for next time
	CPI	ERRLIM		; See if at limit yet
	JC	RCVSQ		; If not, keep going
	JMP	ABORT
;.....
;
;
; Aborts with 1 CTL-X if first time flage is not set, two otherwise
;
CKCAN:	LDA	FRSTIM		; First time through?
	ORA	A
	JZ	CKCAN1		; If first time, abort and close file
	MVI	B,2		; Maximum of 2 seconds for extra CTL-X
	CALL	RECV
	RC			; No additional character, ignore CTL-X
	CPI	CANCEL		; If a 2nd CTL-X, wait for 3rd
	RNZ			; If not CTL-X, ignore
	MVI	B,2		; Maximum of 2 seconds for extra CTL-X
	CALL	RECV
	RC			; No additional character, ignore CTL-X
	CPI	CANCEL		; If a 3rd CTL-X, abort and close file
	RNZ			; If not CTL-X, ignore
;
CKCAN1:	POP	H		; Reset stack for  CALL  CKCAN
	JMP	ABORT		; Go abort
;.....
;
;
; Abort and cancel any partially received file
;
RCVSABT:LXI	SP,STACK	; Reset the stack just in case
	CALL	CLOSFIL		; Close the partial file
	CALL	NOASK		; Delete partial file
	CALL	ILPRT
	DB	CR,LF,LF
	DB	'++ RECEIVED FILE CANCELLED ++',CR,LF,BELL
	DB	'++ UNFINISHED FILE DELETED ++',CR,LF,0
	JMP	DONETA
;.....
;
;
RCVSTOT:LDA	QFLG		; Quiet flag in use?
	ORA	A
	JZ	RCVSCC		; If yes, don't show message
	LDA	FRSTIM		; If first time, do not show as error
	ORA	A
	JZ	RCVSCC
	CALL	ILPRT
	DB	'++ Timeout ',0
	CALL	SHOWERR
;
RCVSCC:	CALL	RCVSCC2
	JMP	RCVSR
;.....
;
;
; Routine will switch from 'CRC' to Checksum if 'ERCNT' reaches 'ERRCRC'
; and 'FIRSTIME' is false
;
RCVSCC2:LDA	FRSTIM		; First time flag set yet?
	ORA	A
	RNZ			; If yes, already underway so exit
;
	LDA	ERRCT
	CPI	ERRCRC		; Up to enough errors to go to checksum?
	RNZ			; If not, exit
	LDA	CRCFLG		; See if checksum already in use
	ORA	A
	RZ			; If yes, exit
	XRA	A		; Else set flags for checksum
	STA	CRCFLG
	STA	CRCDFLT
	CALL	ILPRTQ
	DB	CR,LF,'** Switching to Checksum mode **',CR,BELL,LF,0
	RET
;.....
;
;
; Got STX - set the KFLG for 1k blocks
;
RCVSTX:	STA	KFLG		; Set flag for 1k blocks
	JMP	RCVS1
;
;
; Got SOH - get block #, block # complemented
;
RCVSOH:	XRA	A		; Clear 1k block flag, will be using 128
	STA	KFLG
;
RCVS1:	MVI	B,5		; Timeout = 5 seconds
	MOV	A,B		; Get something to store
	STA	FRSTIM		; Indicate first 'SOH' received
	CALL	RECV		; Get record
	JC	RCVSTOT		; Got a timeout
	MOV	D,A		; Save the record number for now
	MVI	B,5		; Timeout = 5 seconds
	CALL	RECV		; Get complemented record number
	JC	RCVSTOT		; Got a timeout
	CMA			; "Uncomplement" to get original value
	CMP	D		; Compare with first bytee
	JZ	RCVDATA		; If both the same, received ok
;
	LDA	QFLG		; See if in quiet mode
	ORA	A
	JZ	RCVSR		; If yes just add up the error
	CALL	ILPRT		; Else show bad header received
	DB	CR,LF,'++ Bad record # in header ',0
	JMP	RCVPRN
;...
;
;
; Got a good header, save the record number, inirialize cheksum and CRC
;
RCVDATA:MOV	A,D		; Get the record number again
	STA	RCVCNT		; Save it
	MVI	A,1		; Insures only data displayed visually
	STA	DATAFLG
	MVI	C,0		; Clear the checksum value
	LXI	H,0		; Clear the CRC value
	SHLD	CRCVAL
;
;
; Copy either 128 or 1024 characters into the buffer starting at address
; pointed to by RCVPTR.
;
	LXI	D,128		; For 128 character blocks
	LDA	KFLG		; Using 1k blocks?
	ORA	A
	JZ	$+6		; If not, skip next line
	LXI	D,1024		; If using 1k blocks
	LHLD	RECPTR		; Get buffer address
;
RCVCHR:	MVI	B,5		; Wait up to 5 seconds for a character
	CALL	RECV
	JC	RCVSTOT		; Got a timeout
	MOV	M,A		; Store the character in buffer
	INX	H		; Next buffer address
	DCX	D		; One less to go
	MOV	A,D		; See if 'D' and 'E' are both zero
	ORA	E
	JNZ	RCVCHR		; If not, room for another character
	XRA	A
	STA	DATAFLG
	LDA	CRCFLG		; Sending CRC?
	ORA	A
	JNZ	RCVCR		; If yes get the CRC bytes
;
;
; Verify checksum
;
	MOV	D,C		; Otherwise put the checksum in 'D'
	MVI	B,5		; Wait up to 5 seconds for an answer
	CALL	RECV		; Get the checksum value
	JC	RCVSTOT		; Exit if nothing
	CMP	D		; Compare sender's checksum with ours
	JNZ	RCVCER		; Show an error if not ok
;
;
; Got a record, it's a duplicate if equal to the previous number, it's
; OK if previous + 1 record
;
CHKSNUM:LDA	RCVCNT		; Get received record number
	MOV	B,A		; Save it
	LDA	RCDCNT		; Get previous record number
	CMP	B		; Rrevious record repeated?
	JZ	RCVACK		; If yes 'ACK' to catch up
	INR	A		; Increment by 1 for 120 character block
	CMP	B		; Match this one we just got?
	JNZ	ABORT		; No match, stop the sender, exit
	RET			; Else return with carry not set, was ok
;.....
;
;
; Get the CRC bytes
;
RCVCR:	MVI	E,2		; Number of 'CRC' bytes
;
RCVCR2:	MVI	B,5		; Wait up to 5 seconds for a character
	CALL	RECV
	JC	RCVSTOT
	DCR	E		; Started out with 2 characters needed
	JNZ	RCVCR2		; If not zero, need 1 more yet
	CALL	CRCCHK		; Check incoming two against our two
	ORA	A
	JZ	CHKSNUM		; If ok, exit
;
	LDA	QFLG		; Else show an error
	ORA	A
	JZ	RCVSR
	CALL	ILPRT
	DB	'++ CRC error ',0
	JMP	RCVPRN
;.....
;
;
RCVCER:	LDA	QFLG
	ORA	A
	JZ	RCVSR
	CALL	ILPRT
	DB	'++ checksum error ',0
	JMP	RCVPRN
;.....
;
;
RCVACK:	CALL	SNDACK
	JMP	RCVRECD
;.....
;
;
; Get the error count and display on CRT
;
SHOWERR:PUSH	H
	LHLD	ERRCT
	MVI	H,0
	CALL	DECOUT
	POP	H
	CALL	ILPRT
	DB	' ++',CR,LF,0
	LDA	ERRCT
	CPI	ERRLIM
	JNC	ABORT
	RET
;.....
;
;
; Send SOH (or STX), record number and complemented record number.  Put
; the display after the first character to add any delay at that point.
;
SNDHDR:	LDA	KFLG		; Sending 1k blocks?
	ORA	A
	MVI	A,STX		; If yes, send a 'STX' rather than 'SOH'
	JNZ	$+5
	MVI	A,SOH		; Send 'SOH' character to the output
	CALL	SEND
	LDA	QFLG
	ORA	A
	JZ	SNDHNM
	CALL	ILPRT
	DB	CR,'Sending: # ',0
	PUSH	H		; Store current address
	LHLD	RECNO		; Get record number
	CALL	DECOUT		; Print it in decimal
	CALL	ILPRT
	DB	' ',0		; Just spaces the cursor one extra
	POP	H		; Restore current address
;
SNDHNM:	LDA	RCDCNT		; Send the current transmission number
	CALL	SEND
	LDA	RCDCNT
	CMA			; Complement the transmission number
	JMP	SEND		; Send this value to the output
;.....
;
;
SNDREC:	MVI	A,1		; Used for video display while sending
	STA	DATAFLG
	MVI	C,0
	LXI	H,0		; New record, clear 'CHECKSUM' value
	SHLD	CRCVAL		; New record, clear 'CRC' value
	LDA	KFLG		; Sending 1k blocks?
	ORA	A
	LXI	D,1024		; For 1k blocks
	JNZ	$+6		; If yes, skip next line
	LXI	D,128		; For 128 character blocks
	LHLD	RECPTR		; Find buffer location for storage
;
SENDC:	MOV	A,M		; Get character from buffer
	CALL	SEND		; Send to modem
	INX	H		; Next character locatiuon
	DCX	D		; One less to go
	MOV	A,E		; Compare 'E' with 'D'
	ORA	D		; Are both zero yet?
	JNZ	SENDC		; If not, go do another
	XRA	A		; Else finished
	STA	DATAFLG		; Used for video display while sending
	RET
;.....
;
;
; Send the checksum or CRC bytes
;
SNDCHK:	LDA	CRCFLG		; Check if using CRC or checksum
	ORA	A
	JNZ	SNDCRC		; Exit and send CRC bytes
;...
;
;
; Send the checksum
;
SNDCKS:	MOV	A,C		; Get the checksum value
	JMP	SEND		; Send to modem
;.....
;
;
; Send the two CRC (Cyclic Redundancy Check) characters
;
SNDCRC:	PUSH	H
	LHLD	CRCVAL		; Get the two CRC bytes
	MOV	A,H
	CALL	SEND		; Send the first
	MOV	A,L
	CALL	SEND		; Send the second
	POP	H
	XRA	A		; Reset the carry bit
	RET
;.....
;
;
; After a record has been sent, and accepted, move the pointers forward
; 128 or 1024 characters for the next record.
;
SETPTR:	LXI	D,128		; For 128 character blocks
	LDA	KFLG		; See if using 1k blocks
	ORA	A
	JZ	$+6		; If not, skip next line
	LXI	D,1024		; Else set for 1024 character blocks
	LHLD	RECPTR		; Get the buffer pointer
	DAD	D		; Increment for the record just sent
	SHLD	RECPTR		; New buffer address for next block
	RET
;.....
;
;
; After a record is sent, a character is returned telling if it was re-
; ceived properly or not.  An ACK allows the next record to be sent.  A
; NAK causes the current record to be resent.  If no character (or any
; character other than ACK or NAK) is received after a short wait (10
; to 12 seconds), a timeout error message is shown and the record will
; be resent.  The GTACK routine can gobble up a string of up to 191
; characters while searching for an 'ACK' or a 'NAK'.
;
GTACK:	MVI	E,192		; Number of characters to gobble
;
ACKLUP:	MVI	A,0FFH
	STA	CHRFLG		; Set the character flag
	STA	TIMFLG		; Set the time flag
	MVI	B,1
	CALL	RECV
	MOV	B,A		; Save the character
	JNC	ACKTST
	XRA	A
	STA	CHRFLG		; Reset the character flag, was none
;
ACKTST:	XRA	A
	STA	TIMFLG		; Reset the time flag
	MOV	A,B		; Get the character back
	CPI	ACK
	RZ
	CPI	NAK
	JZ	GTACK1
	CPI	CANCEL		; Was this a CTL-X to cancel?
	CZ	CKCAN		; Check for abort
	DCR	E		; One less to go
	JNZ	ACKLUP		; Loop around again if not zero
	LDA	CHRFLG
	ORA	A
	JZ	GETATOT
;
GTACK1:	LDA	QFLG
	ORA	A
	JZ	ACKER
	LDA	CHKEOT		; Waiting for ACK after EOT?
	ORA	A
	JNZ	ACKER		; If yes, ignore message
	CALL	ILPRT
	DB	'++ ',0
	MOV	A,B
	CPI	NAK
	JZ	GTACK3
	CALL	HEXO
	CALL	ILPRT
	DB	'H',0
	JMP	GTACK4
;
GTACK3:	CALL	ILPRT
	DB	'NAK',0
;
GTACK4:	CALL	ILPRT
	DB	' received not ACK - ',0
	CALL	SHOWERR
;
ACKER:	LDA	ERRCT
	INR	A
	STA	ERRCT
	CPI	ERRLIM+1	; At error limit yet?
	RC			; If not, return
;
ACKMSG:	CALL	ERXIT
	DB	CR,LF,LF,'++ FILE TRANSFER ABORTED ++','$'
;.....
;
;
; Reached error limit
;
GETATOT:CALL	ILPRT
	DB	CR,'++ TIMEOUT - no ACK - ',0
	CALL	SHOWERR		; Display error count
	JMP	ACKER
;.....
;
;
; Check the total error count vs. records sent, switch from 1k to 128
; character transmissions if higher than operator selected value.
;
GTRATIO:LDA	KFLG		; Using 1k blocks?
	ORA	A
	RZ			; If not, skip this routine
;
	LDA	ERRCT		; See if we got any errors last record
	CPI	4+1		; If under 4 consecutive errors, exit
	JNC	GTRATIO1	; (ERRCT is set to 1 initially, below)
	LDA	ACCERR		; See if up to minimum errors yet
	CPI	3		; Had as many as three errors yet?
	RC			; If not, don't get excited too quickly
;
	LHLD	RECNO		; Get current record number increment
	LXI	D,-8		; Have not successfully sent this 1k yet
	DAD	D		; Subtract the current increment, then
	XCHG			; Put in DE for now
	LHLD	ACCERR		; Number of non-'ACK' errors in HL
	XCHG			; Back to normal
	CALL	DVHLDE		; Get ratio in BC of records/hit
	LDA	MSPEED		; Get current speed
	CPI	5		; 1200 baud?
	MVI	A,71-1		; For 1200 bps	(78 ms delay)
	JZ	$+5		; If 1200, skip next line
	MVI	A,43-1		; For 2400 bps	(78 ms delay)
	CMP	C		; Compare with actual ratio
	RC			; Return if less hits than allowed
;
GTRATIO1:
	XRA	A		; Else reset the system to 128
	STA	KFLG
	CALL	ILPRTQ
	DB	CR,LF,'Aborting 1k blocks, too many ACK errors',CR,LF,0
	RET
;.....
;
;
CKABORT:LDA	QFLG
	ORA	A
	RZ
	CALL	STAT
	ORA	A
	RZ
	CALL	KEYIN
	CPI	CANCEL
	RNZ
;
;
; Aborts send or receive routines and returns to command line
;
ABORT:	LXI	SP,STACK
;
ABORTL:	MVI	B,1		; 1-second delay to clear input
	CALL	RECV
	JNC	ABORTL
	MVI	A,CANCEL	; Show you are cancelling
	CALL	SEND		; They may quit also with enough CTL-X
	CALL	SEND
	CALL	SEND
;
ABORTW:	MVI	B,1		; 1-second delay to clear input
	CALL	RECV
	JNC	ABORTW
	MVI	A,BKSP		; Remove the three CTL-X's if needed
	CALL	SEND
	CALL	SEND
	CALL	SEND
	MVI	A,'B'		; Clear the batch mode flag
	STA	BATCHFLG
	STA	ABORTFLG	; Shows an abort was made
	XRA	A
	STA	NFILFLG		; Stop copy into memory for disk file
;
ABORTX:	LDA	OPTION		; Receiving a file now?
	CPI	'R'
	JZ	RCVSABT		; If yes, delete the unfinished file
;
	CALL	ILPRT
	DB	CR,LF,LF,'++ FILE CANCELLED ++',CR,LF,BELL,0
	JMP	DONETA
;.....
;
;
; Increment the record count
;
INCRNO:	PUSH	H
	PUSH	D
	LHLD	RCDCNT		; Increment the transmission count
	INX	H
	SHLD	RCDCNT
	LXI	D,1		; Increment by 1 for 128 char. blocks
	LDA	KFLG		; Sending 1k blocks?
	ORA	A
	JZ	$+6		; If not, skip next line
	LXI	D,8		; If yes, increment count by 8
	LHLD	RECNO		; Get record number
	DAD	D
	SHLD	RECNO		; Store it
	POP	D
	POP	H
	RET
;.....
;
;
; First check for any wild cards and disallow, just to be safe.  Do not
; want a group of files being accidently erased.
;
ERASF:	LXI	H,FCB		; File name is stored here
	MVI	B,11		; Maximum of 11 chars for filename, ext.
;
ERASF1:	INX	H		; Next location in file name
	MOV	A,M		; Get the character
	CPI	'?'		; Check for any wild card characters
	JZ	ERRORW		; Error if one is found
	DCR	B		; Number of tries left
	JNZ	ERASF1		; If not zero, keep checking
;
	LDA	BATCHFLG	; Batch mode?
	ORA	A
	JZ	NOASK		; Exit if set (will be zero)
;
	LXI	D,FCB
	MVI	C,SRCHF
	CALL	BDOS
	INR	A
	RZ			; File erased ok, return
	CALL	ILPRT		; Otherwise make sure it'S OK
	DB	'File exists - erase?  (Y/N): ',BELL,0
	CALL	KBDCHR
	PUSH	PSW		; Save the answer for a moment
	CALL	CRLF		; Turn up a line
	POP	PSW		; Get the character back now
	CPI	'Y'
	JNZ	MENU		; If not a 'Y' do not erase
;
NOASK:	LXI	D,FCB		; Else erase the file
	MVI	C,ERASE
	JMP	BDOS		; Return from ERASF
;.....
;
;
ERRORW:	POP	H		; Restore stack from "call ERASF"
	CALL	ILPRT
	DB	'++ NO WILDCARDS ALLOWED FOR TEXT FILES ++'
	DB	CR,LF,BELL,0
	JMP	MENU
;.....
;
;
BLKFILE:CALL	ILPRT		; No file named for send or receive
	DB	'++ NO FILE SPECIFIED ++',CR,LF,BELL,0
	JMP	MENU
;.....
;
;
MAKEFIL:LXI	D,FCB
	MVI	C,MAKE
	CALL	BDOS
	INR	A
	RNZ
	CALL	ERXIT
	DB	'++ ERROR -- Can''t open file ++',CR,LF
	DB	'++ Directory is perhaps full ++','$'
;
CNREC:	MVI	C,FILSIZ	; Compute file size function in cp/m 2.x
	LXI	D,FCB		; Point to file control block
	CALL	BDOS
	LHLD	FCB+33		; Get record count
	SHLD	RCNT		; Store it
	LXI	H,0		; Zero 'HL'
	SHLD	FCB+33		; Reset random record in FCB
	RET
;.....
;
;
OPENFIL:XRA	A
	STA	FCBEXT
	LXI	D,FCB
	MVI	C,OPEN
	CALL	BDOS
	INR	A
	JZ	OPENF1		; Exit if no file
	LHLD	RCNT		; See if anything in the file first
	MOV	A,H
	ORA	L
	JNZ	SNDTM		; If yes send transfer time, etc.
	CALL	ERXIT
	DB	'++ File is zero-length ++','$'
;
OPENF1:	CALL	ERXIT		; File did not open
	DB	'++ FILE NOT FOUND ++','$'
;.....
;
;
CLOSFIL:LXI	D,FCB		; Get the file name
	MVI	C,CLOSE
	CALL	BDOS		; Close the file
	INR	A
	RNZ
	JMP	ERXIT1		; No file to close, exit
;.....
;
;
;-----------------------------------------------------------------------
;		read a record, refill buffer if empty
;
; Update record read
;
RDRECD:	LDA	RECNBF		; Get number of records in buffer
	ORA	A
	JZ	RDBLOCK		; If none, go get some
	LDA	KFLG		; Using 1k blocks?
	ORA	A
	JZ	RDREC1		; If not, exit
;
;
; Using 1k blocks, switch to 128 if less than 8 records left
;
	LDA	RECNBF		; See how many records in buffer
	CPI	8
	JNC	RDREC2		; If 8 or more stay in 1k blocks
	XRA	A		; Else there are 1-7 records left
	STA	KFLG		; Reset the 1k flag for 128
;
RDREC1:	LDA	RECNBF		; Decrement 'RECORDS IN BUFFER' count
	DCR	A
	STA	RECNBF
	RET
;...
;
;
; Using 1k blocks, get set to send another one
;
RDREC2:	SUI	8		; Subtract 1k worth
	STA	RECNBF
	RET
;.....
;
;
; Buffer empty so read in another block from the disk
;
RDBLOCK:LDA	EOFLG
	CPI	1
	STC
	RZ
;
	CALL	RDBLK1
	JMP	RDRECD
;.....
;
;
; Read up to 16k of the file from disk to buffer, ready to send
;
RDBLK1:	MVI	C,0
	LXI	D,BUFFER
;
RDRECLP:PUSH	B
	PUSH	D
	MVI	C,STDMA		; Use the 'DE' address to store file
	CALL	BDOS
;
	LXI	D,FCB
	MVI	C,READ		; Read a record from the file and store
	CALL	BDOS
;
	POP	D
	POP	B
	ORA	A		; Read ok?
	JNZ	REOF		; If not, error or end of file
;
	LXI	H,128		; Add length of one record
	DAD	D		; To next buffer address
	XCHG			; Buffer address for next record to DE
	INR	C		; Increment records in buffer count
	CALL	DSKSIZ		; See if buffer is full yet
	JNZ	RDRECLP		; If not full, do another
;...
;
;
; Buffer full or received "End Of File (EOF)"
;
RDBFULL:STA	RECNBF		; Store the number records in buffer
	LXI	H,BUFFER	; Start at beginning of buffer
	SHLD	RECPTR		; Initialize buffer poninters
	MVI	C,STDMA		; Reset file storage to default area
	LXI	D,TBUF
	JMP	BDOS		; Have something to read, now
;.....
;
;
REOF:	DCR	A		; 'EOF' yet?
	JNZ	RDERR		; If not, was an error
	MVI	A,1
	STA	EOFLG		; Set EOF flag
	MOV	A,C
	JMP	RDBFULL
;.....
;
;
RDERR:	CALL	ERXIT
	DB	'++ FILE READ ERROR ++','$'
;
;
;
;
; If the 128 or 1024 byte record was received ok by RCVDATA and passed
; the CRC (or checksum) test, then we aleady have the infomration in the
; buffer and just move the RECPTR pointers 128 or 1024 bytes for the
; next record's location.  If this puts us up to the limit of records,
; we dump to disk and reset everything.
;
WRRECD:	LHLD	RECPTR		; Get buffer address
	LXI	D,128		; 128 characters/record
	LDA	KFLG		; Using 1k blocks?
	ORA	A
	JZ	$+6		; If not skip next line
	LXI	D,1024		; 1k characters/record
	DAD	D		; To next buffer
	SHLD	RECPTR		; Save buffer address
	LDA	KFLG		; Using 1k blocks?
	ORA	A
	JZ	WRREC1		; If not, exit
	LDA	RECNBF		; Get number of records in buffer
	ADI	8		; Increment it 8 records for 1k block
	JMP	WRREC2
;
WRREC1:	LDA	RECNBF		; Get number of records in buffer
	INR	A		; Increment it for one 128 char. record
;
WRREC2:	STA	RECNBF		; Store the new value
	MOV	C,A		; Store the record count for now
	CALL	DSKSIZ		; Establish buffer size
	RNZ			; Buffer not full, return
;
;
; Write a block to disk
;
WRBLOCK:LDA	RECNBF		; Get the number of records in the buffer
	ORA	A
	RZ			; If zero, don't try to move to disk
	MOV	C,A		; Otherwise store in 'C' reg.
	LXI	D,BUFFER	; Start of buffer to move to disk
;
DSKWRT:	PUSH	B
	PUSH	D
	PUSH	H
;
	MVI	C,STDMA
	CALL	BDOS
;
	MVI	C,WRITE
	LXI	D,FCB
	CALL	BDOS
;
	POP	H
	POP	D
	POP	B
	ORA	A
	JNZ	WRERR		; Error if disk is full
	LXI	H,128		; Add in another record
	DAD	D		; Increment the current buffer address
	XCHG			; Put in DE for new buffer address
	DCR	C		; One less record left to move to disk
	JNZ	DSKWRT		; If not finished, write another record
	XRA	A		; Else all done, zero the pointers
	STA	RECNBF		; Zero the 'RECORDS IN BUFFER' count
	LXI	H,BUFFER	; Reset location to next buffer start
	SHLD	RECPTR		; Now at start of buffer again
	RET
;.....
;
;
; Determine if the buffer size is for file transfer or for ASCII capture
; to disk then compare with current record length
;
DSKSIZ:	LDA	XFLG		; See if transferring files now
	ORA	A
	MOV	A,C		; Get the current record count
	JZ	DSKSIZ1		; If yes, exit
	MOV	A,C
	CPI	BUFSIZ*8	; Buffer size for ASCII capture to disk
	RET			; Return with flag set for the compare
;...
;
;
DSKSIZ1:LDA	SAVSIZ		; Get the file transfer buffer size..
	CMP	C		; From special storage area and compare
	RET			; Return with flag set for the compare
;.....
;
;
; Timeout time is in B, in seconds.  Entry via 'RECVDG' deletes garbage
; characters on the line.  For example, having just sent a record, cal-
; ling RECVDG will delete any line noise induced characters LONG before
; the ACK/NAK would be received.
;
RECVDG:	CALL	CKCHAR		; Catch any garbage characters
;
RECV:	PUSH	D
;
;
; Get back quickly to gobble 2nd character if TIMFLG is set by the GETNM
; routine - or just step through quickly after the first wait for 'SOH'
; in the 'SOHLUP' routine.
;
MSEC:	PUSH	H
	LXI	H,TIMFLG
	MOV	E,M
	INR	E
	LHLD	QUIKTIM
	JZ	DOQUIK
	LHLD	TIMVAL
;
DOQUIK:	XCHG
	POP	H
;
MWTI:	CALL	RCVRDY
	JZ	MCHAR
	MOV	A,D
	ORA	E
	DCX	D
	JNZ	MWTI
	DCR	B
	JNZ	MSEC
	POP	D
	CALL	CKABORT
	STC
	RET
;.....
;
;
; Get the character from the modem, but filter out 'ACK' and '.' chars.
; if recieving a file name.  ('FILTRFLG' is set by the 'GETNM' routine.)
;
MCHAR:	CALL	I$MDDATP	; Get the character that is waiting
	POP	D
	PUSH	PSW		; Save the character for later use also
	CPI	ACK		; See if it is 'ACK'
	JZ	ISACK
	CPI	'.'		; See if it is a period
	JNZ	DOUPD		; Neither, so update 'CRC'
;
ISACK:	PUSH	H
	PUSH	D
	LXI	H,FLTRFLG	; See if need to each 'ACK' or period
	MOV	E,M
	INR	E
	POP	D
	POP	H
	JZ	MWTI		; Yes, so do it
;
DOUPD:	CALL	CRCUPD		; Calculate 'CRC'
	ADD	C
	MOV	C,A
	LDA	RSEEFLG
	ORA	A
	JZ	MONIN
	LDA	VSEEFLG
	ORA	A
	JNZ	NOMONIN
	LDA	DATAFLG
	ORA	A
	JZ	NOMONIN
;
MONIN:	POP	PSW		; Get the character again
	PUSH	PSW		; Resave it for later use also
	CALL	SHOW		; Show the character on the CRT
;
NOMONIN:CALL	CKABORT
	POP	PSW		; Get the character back once more
	ORA	A		; Reset the carry flag
	RET			; Return with the character and flag set
;.....
;
;
; Send a character to the modem
;
SEND:	PUSH	PSW
	LDA	SSEEFLG
	ORA	A
	JZ	MONOUT
	LDA	VSEEFLG
	ORA	A
	JNZ	NOMONOT
	LDA	DATAFLG
	ORA	A
	JZ	NOMONOT
;
MONOUT:	POP	PSW
	PUSH	PSW
	CALL	SHOW
;
NOMONOT:POP	PSW
	PUSH	PSW
	CALL	CRCUPD		; Update the 'CRC' calcuation
	ADD	C
	MOV	C,A
;
SENDW:	CALL	SNDRDY		; See if modem is ready for new char.
	JNZ	SENDW		; If not, wait until modem is ready
	POP	PSW		; Get the character back
	JMP	O$MDDATP	; Send character to modem, done
;.....
;
;
; Waits for the first character received while waiting to send a file.
; If a character is not received in one second, it loops again until a
; char. is received or it times out.  The count is set for two minutes
; before timeout.  This gives the receiving station ample time to name
; a file, etc.
;
WAITNAK:CALL	CKABORT
	MVI	B,1		; Wait up to 1 second for a character
	CALL	RECV		; Clear the buffer first then get char.
	JC	WAITN2		; No character this time
	CPI	CANCEL		; Want to quit?
	CZ	CKCAN		; If yes, check for a trailing CTL-X
;
WAITN1:	CPI	CRC		; 'CRC' request?
	JZ	WAITK		; Yes, see if there will be a trailing K
	CPI	KSND		; Request for 1k blocks?
	JZ	WAIKST		; Yes, go set the 1k flag
	CPI	NAK
	JZ	WAICKSM
	mov	b,a		; Save the character for now
	lda	batchflg	; In batch mode now?
	ora	a
	jnz	waitn2		; if not, exit
	mov	a,b		; Get the character back
	cpi	EOT		; See if file exists on host
	jz	exists		; Exit if batch file already exists
;
WAITN2:	DCR	E
	JNZ	WAITNAK
	JMP	ABORT
;...
;
;
WAITK:	MVI	B,1		; Got a 'C', wait up to 1 second for 'K'
	CALL	RECV
	JC	WAITCRC		; Didn't get anything, so not using 1k
	ANI	7FH
	CPI	'{'
	JZ	WAITK		; Disregard noisy lines
	CPI	KSND		; Requesting 1k?
	JZ	WAIKST		; Exit if yes, otherwise set CRC
	JMP	WAITCRC
;.....
;
;
WAICKSM:LDA	BATCHFLG	; In batch mode?
	ORA	A
	JZ	WAICKSN		; If yes, exit
	XRA	A
	STA	CRCFLG		; Make sure in checksum mode
	STA	KFLG		; Cancel any 1k block request
	CALL	ILPRTQ
	DB	'Got checksum request',CR,LF,0
	RET
;...
;
;
WAICKSN:CALL	ILPRTQ
	DB	'Checksum not used for batch mode',CR,LF,0
	JMP	WAITNAK		; Keep waiting for CRC value
;.....
;
;
WAITCRC:LDA	KFLG
	ORA	A
	JNZ	WAIKST1
	CALL	ILPRTQ
	DB	'CRC request received',CR,LF,0
	MVI	A,1
	STA	CRCFLG		; Make sure in 'CRC' mode then
	XRA	A
	STA	KFLG		; Cancel any 1k blocks request
	RET
;.....
;
;
; If a 'K' was received set for 1k blocks, unless we typed a 'SX' to
; force XMODEM protocol with 128 character blocks, intentionall.
;
WAIKST:	LDA	XMODEM		; Get the value of XMODEM flag
	ORA	A
	JZ	WAITCRC
;
WAIKST1:STA	CRCFLG		; Set the CRC flag
	STA	KFLG		; Set the flag for 1k blocks
	CALL	ILPRTQ
	DB	'1k request received',CR,LF,0
	RET
;.....
;
;
; File exists we were trying to send via batch mode, so abort
;
exists:	call	erxit
	db	CR,LF,'++ File exists on host, aborting transfer ++','$'
;.....
;
;
; Finished with the file transfer
;
DONE:	LDA	BATCHFLG	; In batch mode?
	ORA	A
	JNZ	DONET		; Exit if not
;
	LDA	QFLG
	ORA	A
	JZ	NMSTRNS
	MVI	B,12		; Zero out FTRNM
	LXI	H,FTRNM
	MVI	A,0
;
ZEROLP:	MOV	M,A
	INX	H
	DCR	B
	JNZ	ZEROLP
	MVI	B,12		; Put file name in FTRNM
	LXI	H,FCB+1
	LXI	D,FTRNM
;
LOADMSG:MVI	A,4		; Start of file type?
	CMP	B
	JZ	PERIOD		; Put in period if so
	MOV	A,M
	CPI	' '		; Don't put in space
	JZ	SKPSP
	STAX	D		; Store in FTRNM
	INX	D
;
SKPSP:	INX	H
	DCR	B
	MOV	A,B
	ORA	A		; End of file name?
	JZ	FTRNM0		; Display file name
	JMP	LOADMSG		; Loop for another character
;.....
;
;
PERIOD:	MOV	A,M
	CPI	' '		; Is file type empty?
	JZ	FTRNM0		; Go if so
	MVI	A,'.'		; Else put period in message
	STAX	D
	INX	D
	DCR	B
	JMP	LOADMSG
;.....
;
;
FTRNM0:	CALL	ILPRT
	DB	CR,LF
;
FTRNM:	DB	0,0,0,0,0,0,0
	DB	0,0,0,0,0,0
	CALL	ILPRT
	DB	' Transferred',CR,LF,0
;
NMSTRNS:LXI	H,FCB		; Blank out file control blocks
	CALL	INITFCB1
	LXI	H,RESTSN	; Restore record numbers
	LXI	D,RECNOB	; For new file transfer
	MVI	B,RECNOE-RECNOB	; Routine also done in menu
	CALL	MOVE
	CALL	SNDNOW		; Insures last character is finished
	CALL	CKCHAR		; Catch any echo characters on line
	MVI	A,1
	STA	GOTONE		; Indicates a batch file was handled
	LDA	SNDFLG		; Check batch flag
	ORA	A
	JNZ	RCVFL		; Receiving batch, if set
	JMP	SNDFL1		; Sending batch if not set
;.....
;
;
DONET:	CALL	CKABORT		; Slight delay for next message
	CALL	ILPRT
	DB	CR,LF,'[Transfer completed]',CR,LF,BELL,0
;
DONETA:	LDA	XITFLG		; Special 'Z' flag set?
	ORA	A
	JZ	BYEBYE		; If yes, disconnect and reboot
	LDA	DISCFLG		; Normal 'D' flag set?
	ORA	A
	JZ	DONETD		; If yes, disconnect, get next command
;
DONETB:	XRA	A
	STA	CRCFLG		; Reset back to checksum
	STA	FRSTIM		; Reset first-time 'SOH' flag
	STA	FSTFLG		; Reset multi-file transmission
	STA	NFILFLG		; Turn off the memory save for disk file
	STA	SAVEFLG		; Stop memory save in term routine.
	LDA	VSEEFLG		; View flag set?
	ORA	A
	JNZ	DONETC		; If not, exit
	CMA
	STA	QFLG		; VSEEFLG also sets the QFLG
	STA	VSEEFLG		; Reset the flag
;
DONETC:	LXI	H,QFLG		; In quiet mode?
	MOV	A,M
	ORA	A
	MVI	M,'Q'		; Reset the flag to normal
	JZ	MENU		; If yes, go back to command line
	LDA	ABORTFLG	; Come here from a timeout?
	ORA	A
	JNZ	MENU		; If yes, go to command mode
	JMP	TERM		; Otherwise return to terminal mode
;.....
;
;
DONETD:	CALL	ILPRT
	DB	CR,LF,'  wait... ',0
	CALL	STPCHR		; Try to stop any incoming characters
	LDA	NODTR		; Able to disconnect by dropping DTR?
	ORA	A
	JNZ	DONETE		; If not, exit
	CALL	J$GOODBYE	; Disconect with ATH0 string
	JMP	DONETF
;
DONETE:	CALL	J$DSCONT	; Disconnect with ATH0 string	
;
DONETF:	CALL	ILPRT
	DB	CR,'<< Disconnected >>',BELL,CR,LF,0
	JMP	MENU0		; Back to command line
;.....
;
;
; Sends a break tone for 300 ms
;
SBREAK:	LDA	J$BREAK
	CPI	0C3H		; See if overlay has "J$BREAK" installed
	JNZ	TERM		; If not, get next character/command
	CALL	STPCHR		; Stop any incoming characters
	CALL	J$BREAK		; Send the break tone
;
	JMP	TERM		; Get next character/command
;.....
;
;
; This routine stops any incoming characters if possible
;
STPCHR:	CALL	J$INMDM		; See if any incoming characters
	JC	STPCHR1		; If no incoming, exit
	MVI	B,'S'-40H	; X-off to stop host if possible
	CALL	J$SNDCHR	; Send to host		
	MVI	B,1		; Delay 100 ms to take effect
	CALL	J$TIMER
	JMP	STPCHR		; See if characters have stopped now
;
STPCHR1:RET			; Done
;.....
;
;
SHOW:	CPI	LF
	JZ	CTYPE
	CPI	CR
	JZ	CTYPE
	CPI	9
	JZ	CTYPE
	CPI	' '
	JC	SEEHEX
	CPI	7FH
	JC	CTYPE
;
SEEHEX:	PUSH	PSW
	MVI	A,'('
	CALL	CTYPE
	POP	PSW
	CALL	HEXO
	MVI	A,')'
	JMP	CTYPE
;.....
;
;
CTYPE:	PUSH	B
	PUSH	D
	PUSH	H
	MOV	E,A
	MVI	C,WRCON
	CALL	BDOS
	POP	H
	POP	D
	POP	B
	RET
;.....
;
;
CRLF:	PUSH	PSW
	MVI	A,CR
	CALL	TYPE
	MVI	A,LF
	CALL	TYPE
	POP	PSW
	RET
;.....
;
;
STAT:	PUSH	B
	PUSH	D
	PUSH	H
;
VSTAT:	CALL	$-$		; BIOS constat address, filled in..
	POP	H		; By 'INITADR' routine
	POP	D
	POP	B
	ORA	A
	RET
;.....
;
;
KEYIN:	PUSH	B
	PUSH	D
	PUSH	H
;
VKEYIN:	CALL	$-$		; BIOS 'CONIN' address, filled in..
	POP	H		; By 'INITADR' routine
	POP	D
	POP	B
	RET
;.....
;
;
TYPE:	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	MOV	C,A
;
VTYPE:	CALL	$-$		; BIOS 'CONOUT' address, filled in..
	POP	H		; By 'INITADR' routine
	POP	D
	POP	B
	POP	PSW
	RET
;.....
;
;
; Catch any extra keyboard characters coming through BDOS
;
CKCON:	MVI	C,CONST		; See if any characters waiting
	CALL	BDOS
	ORA	A
	RZ			; If not, exit
	MVI	C,RDCON		; Otherwise get the character
	CALL	BDOS
	XRA	A		; Discard the character
	JMP	CKCON		; See if any others
;.....
;
;
; Used in overlay area to permit saying "SET 2400", etc.
;
CMDSPL:	LXI	D,CMDBUF+6
	LDAX	D
	CPI	'0'
	RET
;.....
;
;
DECOUT:	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	LXI	B,-10
	LXI	D,-1
;
DECOU1:	DAD	B
	INX	D
	JC	DECOU1
	LXI	B,10
	DAD	B
	XCHG
	MOV	A,H
	ORA	L
	CNZ	DECOUT
	MOV	A,E
	ADI	'0'
	CALL	CTYPE
	POP	H
	POP	D
	POP	B
	POP	PSW
	RET
;.....
;
;
; Displays error statement then resturns to command mode
;
ERXIT:	POP	D
	CALL	PRTMSG
	MVI	A,BELL
	CALL	TYPE
	CALL	CRLF
;
ERXIT1:	MVI	A,1
	STA	ABORTFLG	; Shows an unintentional abort
	LDA	BATCHFLG	; In batch mode?
	ORA	A
	JNZ	DONETB		; If not, exit
	JMP	ABORT		; Abort other computer
;.....
;
;
; Exits directly to CP/M, with no reboot unless you have selected pos-
; sible overwriting of 'CCP'
;
EXIT:	LDA	OLDUSER		; Get original user number back
	MOV	E,A
	CALL	STUSER
	MVI	C,STDMA
	LXI	D,TBUF		; Restore original buffer area
	CALL	BDOS
	LXI	B,1A00H		; A little delay timer
;
EXIT1:	DCX	B		; One less loop to make
	MOV	A,B
	ORA	C
	JNZ	EXIT1		; Loop again till both are zero
	CALL	CKCON		; Catch any extra keyboard characters
	LDA	NFILFLG		; Saving for a disk file?
	ORA	A
	STA	DONEFLG		; Set the flag
	CNZ	WRFIL1		; If yes, close the file
	LDA	MSPEED		; Get the current modem speed
	STA	STRSPD		; Store in case we come right back
;
EXIT2:	CALL	J$EXITVEC	; See if overlay needs to do anything
	XRA	A		; Clear the 'A' reg. and all flags
	LHLD	STACK		; Get the original stack pointer back
	SPHL			; Set the stack pointer to that address
	RET
;.....
;
;
; Include the filename when transferring a file.  Check to see if from
; an .ARC, .ARK or .LBR group first.
;
FILNAM:	CALL	ILPRTQ
	DB	'File name: ',0
	LXI	H,93
	MVI	B,8		; Maximum size of file name
	CALL	FILN1
	MOV	A,M		; Get the next character
	CPI	32		; Any file extent?
	RZ			; If not, finished
;
	MVI	A,46
	CALL	TYPE
	MVI	B,3		; Maximum size of file extent
;
FILN1:	MOV	A,M		; Get FCB FILENAME/EXT character
	CPI	32		; Skip any blanks
	CNZ	TYPE
	INX	H		; Next FCB position
	DCR	B		; One less to go
	JNZ	FILN1		; If not done, get next one
	RET
;.....
;
;
; Adjusts loop counter for the selected clock speed.  Returns with delay
; in 'HL'.
;
FIXCNT:	LDA	CLOCK		; Get the user's clock speed
	PUSH	D		; Save the current 'DE' value
	PUSH	H
	POP	D		; Get same value into 'DE' as in 'HL'
;
CNTMUL:	DAD	D		; Add 'DE' to 'HL'
	DCR	A		; One less to go
	JNZ	CNTMUL
	POP	D		; Restore current 'DE', delay in 'HL'
	RET
;.....
;
;
; Special routine to let overlays substitute their own printer routines.
; Returns with GOLIST+1 and GOLIST+15 addresses.
;
GOLST:	LXI	H,GOLIST+1
	LXI	D,GOLIST+15
	RET
;.....
;
;
; Prints a hex value in 'A' on the CRT
;
HEXO:	PUSH	PSW
	RAR
	RAR
	RAR
	RAR
	CALL	NIBBL
	POP	PSW
;
NIBBL:	ANI	0FH
	CPI	10
	JC	ISNUM
	ADI	7
;
ISNUM:	ADI	'0'		; Add in ASCII bias
	JMP	CTYPE
;.....
;
;
; Write a string of characters to the CRT
;
ILPRT:	XTHL
;
ILPRT1:	MOV	A,M		; Get the character
	ORA	A		; See if a "0" for end of string
	JZ	ILPRT2		; If yes, all done
	CALL	CTYPE		; Show on CRT
	INX	H		; Get the next location in the string
	JMP	ILPRT1
;
ILPRT2:	XTHL			; Restore the address
	RET
;.....
;
;
; Write a string of characters unless in the Quiet mode
;
ILPRTQ:	XTHL
;
ILPRTQ1:MOV	A,M		; Get the character
	ORA	A		; See if a "0" for end of string
	JZ	ILPRTQ2		; If yes, all done
	LDA	QFLG
	ORA	A
	MOV	A,M
	CNZ	CTYPE		; Show on CRT if not in quiet mode
	INX	H		; Get the next location in the string
	JMP	ILPRTQ1
;
ILPRTQ2:XTHL			; Restore the address
	RET
;.....
;
;
MOVE128:MVI	B,128
;
MOVE:	MOV	A,M
	STAX	D
	INX	H
	INX	D
	DCR	B
	JNZ	MOVE
	RET
;.....
;
;
MOVEFCB:LXI	H,FCB+16
	LXI	D,FCB
	MVI	B,16
	CALL	MOVNAM
	XRA	A
	STA	FCBSNO
	STA	FCBEXT
	RET
;.....
;
;
; Prevents accidently including an "ESC" character in a file name
;
MOVNAM:	MOV	A,M
	CPI	'['-40H		; ESC character?
	JNZ	$+5		; If yes, store normally
	MVI	A,' '
	STAX	D
	INX	D
	INX	H
	DCR	B
	JNZ	MOVNAM
	RET
;.....
;
;
; Initializes speed to that last used, if any, from 03CH MSPEED storage
; and restores DTR.
;
SETSPD:	LDA	STRSPD		; Location of MSPEED from memory
	ORA	A		; See if it has been used
	JZ	SETSP1		; If not, use normal speed
	CPI	9+1		; Takes us up to MSPEED = 19200 bps
	JNC	SETSP1		; If more, was not a valid baudrate
	STA	MSPEED		; Set former speed, then
;
SETSP1:	JMP	J$INITMOD	; Go set the speed, done
;.....
;
;
; Get a character from the keyboard, convert to upper-case if needed,
; and show on CRT
;
KBDCHR:	CALL	KEYIN		; Get a keyboard character
	CALL	UCASE		; Convert to upper case if needed
	CALL	TYPE		; Show on CRT
	RET
;.....
;
;
LCASE:	CPI	41H		; Ignore if less than upper case 'A'
	RC
	CPI	5AH+1		; Ignore if more than upper case 'Z'
	RNC
	ORI	20H		; Change to lower case
	RET
;.....
;
;
UCASE:	CPI	61H		; Ignore if less than lower case 'a'
	RC
	CPI	7AH+1		; Ignore if more than lower case 'z'
	RNC
	ANI	5FH		; Else change lower ASCII to upper case
	RET
;.....
;
;
; Displays a string of chracters on the screen
;
PRTMSG:	MVI	C,PRINT		; Print the string
	JMP	BDOS
;.....
;
;
; Allows the TeleVideo 803 to use the RCVRDY routine for its special
; receive-only status register.
;
RCVRSP:	LXI	H,RCVRDY+1
	RET
;.....
;
;
; Displays the control-characters shown in the menu
;
SHFTYPE:PUSH	PSW
	CALL	ILPRT
	DB	'ESC-',0
	POP	PSW
	CALL	TYPE		; Show on the CRT
	JMP	ILPRT
;.....
;
;
; Sends the character in 'A' to the modem
;
SNDCHR:	CALL	SNDNOW		; Wait until modem is ready for char.
	MOV	A,B		; Get the original character back
	JMP	O$MDDATP	; Send the character to modem, return
;.....
;
;
; Initializes CP/M file control blocks AT 5CH and 6CH
;
STFCB:	LXI	D,CMDBUF
	LXI	H,FCB
	JMP	CMDLINE
;.....
;
;
; Timer routine.  Waits 0.1 seconds for each unit in 'B' reg.
;
TIMER:	PUSH	H
;
TIMER1:	PUSH	B
;
TIMER2:	CALL	J$INMDM		; 100 ms. delay per loop
	JNC	TIMER2
	POP	B
	DCR	B
	JNZ	TIMER1
	POP	H
	RET
;.....
;
;
;=======================================================================
;
; Loads a command line addressed by 'DE' registers (max # characters in
; line in 'DE', number of characters in line in DE+1, line starts in
; DE+2) into FCB addressed by 'HL' registers.  The FCB should be at
; least 33 bytes in length.  The command line buffer must have a maxi-
; mum length at least one more than the greatest number of characters
; that will be needed.

CMDLINE:PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	CALL	INITIAL		; Fills FCBs with blanks and nulls
	XCHG			; Get start of command line in HL
	INX	H		; Address # bytes in command line
	MOV	E,M		; Load DE pair with # bytes
	MVI	D,0
	INX	H
	DAD	D		; Point to byte after last character
	MVI	M,CR		; In command line and store delimiter
	POP	H		; Restore HL and DE
	POP	D
	PUSH	D
	PUSH	H
	INX	D		; Address start of command
	INX	D
	CALL	DRIVE
;
	MVI	C,8		; Transfer first filename to FCB
	CALL	TRANS
	CPI	CR
	JZ	DONEL
	CPI	' '		; If space, then start of 2nd filename
	JZ	NAME1
	POP	H		; Filetype starts after 8th byte
	PUSH	H
	LXI	B,9
	DAD	B
	MVI	C,3		; Transfer type of first file
	CALL	TRANS
	CPI	CR
	JZ	DONEL
;
NAME1:	LDAX	D		; Eat multiple spaces between names
	CPI	' '
	JNZ	NAME2
	INX	D
	JMP	NAME1
;
NAME2:	POP	H		; Second name starts in 16th byte
	PUSH	H		; Point HL to this byte
	LXI	B,16
	DAD	B
	CALL	DRIVE
	MVI	C,8
	CALL	TRANS
	CPI	CR
	JZ	DONEL
	POP	H		; Second file type starts in 25th byte
	PUSH	H
	LXI	B,25
	DAD	B
	MVI	C,3
	CALL	TRANS
;
DONEL:	POP	H
	PUSH	H
	INX	H		; Point to 1st char of 1st name in FCB
	CALL	SCANL		; Check for * (ambiguous names)
	POP	H
	PUSH	H
	LXI	B,17		; To 1st character of second name in FCB
	DAD	B
	CALL	SCANL
	POP	H
	POP	D
	POP	B
	POP	PSW
	RET
;.....
;
;
; Subroutines for CMDLINE section
;
INITIAL:PUSH	H		; Initializes FCB with 1 null for first
	PUSH	B		; Drive with 11 blanks, 4 nulls, 1
	MVI	M,0		; Null for second drive with 11 blanks
	INX	H		; And 4 nulls
	MVI	B,11
	MVI	A,' '
	CALL	INITFILL
	MVI	B,5
	XRA	A
	CALL	INITFILL
	MVI	B,11
	MVI	A,' '
	CALL	INITFILL
	MVI	B,4
	XRA	A
	CALL	INITFILL
	POP	B
	POP	H
	RET
;.....
;
;
INITFILL:
	MOV	M,A
	INX	H
	DCR	B
	JNZ	INITFILL
	RET
;.....
;
;
DRIVE:	INX	D		; Check 2nd byte of filename.  if it..
	LDAX	D		; Is a ":", then drive was specified..
	DCX	D
	CPI	':'
	JNZ	DEFDR		; Else zero for default drive
	LDAX	D		; ('INIT' put zero)
	ANI	5FH
	SUI	40H		; Calculate drive (A=1, B=2,...)
	MOV	M,A		; Place it in FCB
	INX	D		; Address first byte in command line
	INX	D
;
DEFDR:	INX	H		; And name field in FCB
	RET
;.....
;
;
TRANS:	LDAX	D		; Transfer from command line to FCB
	INX	D		; Up to number of chars specified
	CPI	CR		; By 'C' reg.	Keep scanning field
	RZ			; Without transfer until a delimiting
	CPI	'.'		; Field char such as '.', blank, or
	RZ			; CR (for end of commmand line).
	CPI	' '
	RZ
	DCR	C
	JM	TRANS		; Once C-reg is less than zero, keep
	MOV	M,A		; Reading command line but do not
	INX	H		; Transfer to FCB.
	JMP	TRANS
;...
;
;
SCANL:	MVI	B,8		; Scan file name addressed by HL
;
TSTNAM:	MOV	A,M
	CPI	'*'		; If '*' found, fill in rest of field
	JZ	FILL1		; With '?' for ambiguous name.
	INX	H
	DCR	B
	JNZ	TSTNAM
	JMP	TSTTYP
;...
;
;
FILL1:	CALL	FILL
;
TSTTYP:	MVI	B,3		; Scan and fill type field for name
;
TSTTYPL:MOV	A,M
	CPI	'*'
	JZ	FILL2
	INX	H
	DCR	B
	JNZ	TSTTYPL
	RET
;.....
;
;
FILL2:	CALL	FILL
	RET
;.....
;
;
FILL:	MVI	M,'?'		; Routine transfers '?'
	INX	H
	DCR	B
	JNZ	FILL
	RET

;=======================================================================
;
; LISTS DIRECTORY AND GIVES FREE SPACE REMAINING ON THE REQUESTED DRIVE.
;
;
; Disk system reset - currently bypassed, if you wish this feature, put
;	JMP DRLST2 instead of JMP DRLST3 in the eighth line.  The
;	current disk (plus the A: drive) will then reset each DIR re-
;	quest.	You can also reset the disk with the LOG command when
;	when inserting a different one.  This saves a reset each time
;	DIR might be requested.
;
DRLST:	CALL	GETDISK
	ADI	'A'		; Change to ASCII
	STA	DRNAME		; Show for drive name
	STA	ACTDRV		; Show for space remaining on drive
	JMP	DRLST1
	MVI	C,RESET		; 13 reset disk system (resetdk)
	CALL	BDOS
;
;
; Directory list routine
;
DRLST1:	LXI	D,CMDBUF	; Put command line in FCB
	LXI	H,FCB
	CALL	CMDLINE
	LXI	H,FCB4
	CALL	INITFCB
	LDA	FCB2		; Get drive number
	STA	FCB4
	LDA	FCB2+1
	CPI	' '		; If a space (blank) get all names
	PUSH	PSW
	CZ	QSTMARK
	POP	PSW
	CNZ	MOVNAME		; Else move name into FCB
	CALL	DRIVEL
	MVI	C,STDMA
	LXI	D,TBUF
	CALL	BDOS
	LDA	NOFCOL		; Number of columns into 'A' register
	STA	NAMECT		; CRLF after 'NOFCOL' number of columns
	LXI	D,FCB4
	MVI	C,SRCHF		; Do first search
	CALL	BDOS
	INR	A		; 0FFH --> 0 if no file(s) found
	JNZ	DIRLOOP
	CALL	ILPRT
	DB	'++ FILE NOT FOUND ++',0
	JMP	STORAGE		; Still show storage on default drive
;
DIRLOOP:CALL	GETADD
	INX	H		; Point to first letter of filename
	LXI	D,PRTNAME
	LXI	B,8
	CALL	MOVER
	INX	D
	LXI	B,3
	CALL	MOVER
	CALL	ILPRT
;
PRTNAME:DB	'        ','.','   ',0 ; 8 spaces, period, 3 spaces
;
NEXTSR:	LXI	D,FCB4
	MVI	C,SRCHN		; Do next search
	CALL	BDOS
	INR	A		; If 0FFH --> 0 directory read is done
	JZ	STORAGE
	PUSH	PSW
	PUSH	D
	PUSH	H
	LDA	NAMECT
	DCR	A
	STA	NAMECT		; Name count updated
	ORA	A
	CZ	CRLF		; Terminate line of file names
	JNZ	FENCE
	LDA	NOFCOL		; Restart columns-per-line count
	STA	NAMECT
	JMP	NOFENCE		; Fence not needed
;
FENCE:	CALL	ILPRT
	DB	' : ',0		; Fence if not at end of line or
;				;   last filename
NOFENCE:POP	H
	POP	D
	POP	PSW
	JMP	DIRLOOP
;.....
;
;
; Determine storage remaining on default drive
;
STORAGE:CALL	CKCPM3
	MVI	C,DSKPAR	; Current disk parameter block
	CALL	BDOS
	INX	H
	INX	H
	MOV	A,M		; Get block shift factor
	STA	BSHIFTF
	INX	H		; Bump to block mask
	MOV	A,M		; Get it
	STA	BMASK
	INX	H
	INX	H
	MOV	E,M		; Get maximum block number
	INX	H
	MOV	D,M
	XCHG
	SHLD	BMAX		; Put it away
	MVI	C,DSKALL	; Address of CP/M allocation vector
	CALL	BDOS
	XCHG			; Get its length
	LHLD	BMAX
	INX	H
	LXI	B,0		; Initialize block count to zero
;
GSPBYT:	PUSH	D		; Save allocation address
	LDAX	D
	MVI	E,8		; Set to process 8 blocks
;
GSPLUP:	RAL			; Test bit
	JC	NOTFRE
	INX	B
;
NOTFRE:	MOV	D,A		; Save bits
	DCX	H
	MOV	A,L
	ORA	H
	JZ	ENDALC		; Quit if out of blocks
	MOV	A,D		; Restore bits
	DCR	E		; Count down 8 bits
	JNZ	GSPLUP		; Do another bit
	POP	D		; Next count of allocation vector
	INX	D
	JMP	GSPBYT		; Process it
;
ENDALC:	POP	D		; Clear alloc vector pointer from stack
	MOV	L,C		; Copy block to HL
	MOV	H,B
	LDA	BSHIFTF		; Get block shift factor
	SUI	3		; Convert from records to thousands (k)
	JZ	PRTFREE		; Skip shifts if 1k blocks
;
FREKLP:	DAD	H		; Multiply blocks by 'k' per block
	DCR	A
	JNZ	FREKLP
;
PRTFREE:CALL	DECOUT		; (number of free 'k' bytes now in 'HL')
	LXI	D,FREEMSG
	JMP	PRTMSG
;.....
;
;
; Subroutines for 'DRLST' section
;
QSTMARK:MVI	A,'?'		; If blank in FCB, put in 11 ?'S
	MVI	B,11
	LXI	H,FCB4+1
;
QSTLP:	MOV	M,A
	INX	H
	DCR	B
	JNZ	QSTLP
	RET
;.....
;
;
MOVNAME:LXI	H,FCB2+1
	LXI	D,FCB4+1
	LXI	B,11
	CALL	MOVER
	RET
;.....
;
;
GETADD:	DCR	A		; Undo the INR above
	ADD	A		; Times 32
	ADD	A
	ADD	A
	ADD	A
	ADD	A
	ADI	TBUF		; Add buffer offset
	MOV	L,A
	MVI	H,0
	RET
;.....
;
;
DRIVEL:	LDA	FCB4		; Use default drive in DRNAME
	ORA	A
	JZ	PRNTHD
	PUSH	PSW
	DCR	A
	MOV	E,A
	MVI	C,SELDSK
	CALL	BDOS
	POP	PSW
	ADI	40H		; Make 1=A, 2=B, etc.
	STA	DRNAME		; Overwrite default stored below
	STA	ACTDRV
;
PRNTHD:	CALL	ILPRT
	DB	'Drive '
;
DRNAME:	DB	' :',CR,LF,0
	RET
;.....
;
;
; Initialized storage
;
FREEMSG:DB	'k bytes free on drive '
ACTDRV:	DB	' :',CR,LF,'$'
;
;
; Uninitialized storage
;
BMAX:	DB	0,0		; Highest block number on drive
BMASK:	DB	0		; Rec/blk - 1
BSHIFTF:DB	0		; # of shifts to multiply by rec/blk
;.....
;
;
; CALCULATES DISK SPACE REMAINING IF CP/M+
;
CKCPM3:	CALL	CRLF
	MVI	C,CPMVER	; Check version #
	CALL	BDOS
	MOV	A,L
	CPI	30H		; Version 3.0?
	RC			; Use normal method if not CP/M+
	POP	H		; Remove "call CKCPM3" from stack
	MVI	C,CURDSK
	CALL	BDOS
	MOV	E,A
	MVI	C,46		; CP/M+ compute free space call
	CALL	BDOS
	MVI	C,3		; Answer is 3 bytes long (24 bits)
;
FREE30:	LXI	H,TBUF+2	; Answer is located here
	MVI	B,3		; Convert to 'k' length
	ORA	A
;
FREE31:	MOV	A,M
	RAR
	MOV	M,A
	DCX	H
	DCR	B
	JNZ	FREE31		; Loop for 3 bytes
	DCR	C
	JNZ	FREE30		; Shift 3 times
	LHLD	TBUF		; Get result in 'k'
	JMP	PRTFREE		; Display result
;.....
;
;		    end of directory routine
;=======================================================================
;
; Duplicates 'READ BUFFER' routine same as CP/M function 10, but does
; not use CTL-C (reason for the routine).  Does allow controls U, R and
; H (BACKSPACE).  Outputs bell if the input is greater than the buffer.
;
INBUF:	PUSH	PSW
	PUSH	H
	PUSH	B
	PUSH	D		; 'DE' registers must be pushed last
;
INBUFA:	CALL	CLEARBUF	; Clear the buffer area
	POP	D		; Get address of buffer on retries
	PUSH	D		; Restore stack
	XRA	A
	INX	D		; Address count field
	STAX	D		; Initialize with a zero in count byte
	INX	D
	XCHG			; Address first buffer byte with 'HL'
;
INBUFB:	CALL	KEYIN		; Waits for a charcter
	CALL	UCASE		; Convert to upper case if needed
	CPI	CR		; Is it <return> (enter command)?
	JZ	INBUFR		; If so, then return
	CPI	'H'-40H		; CTL-H backspaces over deleted char.
	JZ	DELETE
	CPI	7FH		; Is it a delete?
	JZ	DELETE
	CPI	'U'-40H		; Is it a CTL-U?
	JZ	INBUFO		; Output #, CR, LF, and start over
	CPI	'R'-40H		; CTL-R retypes line
	JZ	RETYPE
	CPI	CLEARSC		; Want to clear CRT?
	JZ	CLRS		; If yes, go clear screen
;
	MOV	B,A		; Save inputted character
	XCHG			; Save 'HL' in 'DE'
	POP	H		; Get address of buffer in 'HL'
	PUSH	H		; Restore stack
	INX	H		; Address count byte
	INR	M		; Increase count byte
	DCX	H		; Address maximum
	MOV	A,M		; Put maximum in 'A'
	INX	H		; Address count
	CMP	M		; Compare count to maximum
	JC	ALERTL		; If maximum, ring bell and wait for CR
	XCHG			; Restore buffer pointer to 'HL'
	MOV	M,B		; Put inputted character in buffer
	MOV	A,B		; Output it
	CPI	20H		; Printing character?
	CNC	TYPE		; If yes, print it
	INX	H		; Bump pointer
	JMP	INBUFB		; Get next character
;...
;
;
DELETE:	XCHG			; Save buffer pointer in 'DE'
	POP	H		; Address beginning of buffer
	PUSH	H		; Restore stack
	INX	H		; Address count field
	MOV	A,M
	SUI	1		; Decrease count
	MOV	M,A
	JC	NODEL		; Don't delete past beginning of buffer
	XCHG			; Restore buffer pointer to 'HL'
	DCX	H		; Point to last byte inputted
	MOV	A,M		; Get the character being deleted
	MVI	M,' '		; Restore blank
	CPI	' '		; See if a non-printing character
	JC	INBUFB		; If yes, skip the CRT backup
	MVI	A,BKSP
	CALL	TYPE		; True erase if 08H
	MVI	A,' '
	CALL	TYPE
	MVI	A,BKSP
	CALL	TYPE
	JMP	INBUFB
;.....
;
;
NODEL:	INR	M		; Don't leave count negative
	XCHG			; Restore pointer to 'HL'
	MVI	A,BELL		; Says can go no further
	CALL	TYPE
	JMP	INBUFB
;.....
;
;
INBUFO:	MVI	A,'#'		; Announces the line has been removed
	CALL	TYPE
	CALL	CRLF
	JMP	INBUFA
;.....
;
;
RETYPE:	POP	D
	PUSH	D
	INX	D		; Point to current number of characters
	LDAX	D
	MOV	B,A
	MVI	A,'#'
	CALL	TYPE
	CALL	CRLF
	MOV	A,B		; Test if zero input
	ORA	A
	JZ	INBUFB
;...
;
;
CTLRLP:	INX	D
	LDAX	D
	CALL	TYPE
	DCR	B
	JNZ	CTLRLP
	JMP	INBUFB
;.....
;
;
ALERTL:	MVI	A,BELL		; Alarm for full buffer
	CALL	TYPE
	DCR	M
	XCHG
	JMP	INBUFB
;.....
;
;
INBUFR:	CALL	CRLF		; 1st new line after a command character
	POP	D
	POP	B
	POP	H
	POP	PSW
	RET
;.....
;
;
CLEARBUF:
	POP	D		; Accounts for call
	POP	H		; Address buffer in 'HL'
	PUSH	H		; Restore stack
	PUSH	D
	MOV	B,M		; Save maximum in 'B'
	INX	H		; Point to first buffer byte
	INX	H
	MVI	A,' '
;
CLEARL:	MOV	M,A
	INX	H
	DCR	B
	JNZ	CLEARL
	RET
;.....
;
;
;=======================================================================
;
; In-line compare.  Compares string addressed by 'DE' to string after
; call (ends with zero).  Return with carry set means strings not the
; same.  All registers except 'A'-reg are unaffected.
;
INLNCP:	XTHL			; Point 'HL' to 1st character
	PUSH	D
;
ILCOMPL:MOV	A,M		; 'HL' points to in-line string
	ORA	A		; End of string if zero
	JZ	SAME
	LDAX	D
	CMP	M
	JNZ	NOTSAME
	INX	H
	INX	D
	JMP	ILCOMPL
;...
;
;
NOTSAME:XRA	A
;
NSLP:	INX	H
	CMP	M
	JNZ	NSLP
	STC
;
SAME:	POP	D
	INX	H		; Avoids a NOP instruction when done
	XTHL
	RET
;.....
;
;
;=======================================================================
;		  MULTI-FILE ACCESS ROUTINE
;
; Multi-file access subroutine.  Allows processing of multiple files
; (i.e., *.ASM) from disk.  Builds the correct name in the FCB each time
; it is called.  The command is used in programs to process single or
; multiple files.  The FCB is set up with the next name, ready to do
; normal processing (open, read, etc.) when routine is called.	Carry is
; set if no more names are found.

MFNAM:	PUSH	B
	PUSH	D
	PUSH	H
	MVI	C,STDMA
	LXI	D,TBUF
	CALL	BDOS
	POP	H
	POP	D
	POP	B
	XRA	A
	STA	FCBEXT
	LDA	MFFLG1
	ORA	A
	JNZ	MFNAM1
	MVI	A,1
	STA	MFFLG1
	LXI	H,FCB
	LXI	D,MFNAM5
	LXI	B,12
	CALL	MOVER
	LDA	FCB
	STA	MFNAM6		; Save disk in current FCB
	LXI	H,MFNAM5
	LXI	D,FCB
	LXI	B,12
	CALL	MOVER
	PUSH	B
	PUSH	D
	PUSH	H
	MVI	C,SRCHF
	LXI	D,FCB
	CALL	BDOS
	POP	H
	POP	D
	POP	B
	JMP	MFNAM2
;...
;
;
MFNAM1:	LXI	H,MFNAM6
	LXI	D,FCB
	LXI	B,12
	CALL	MOVER
	PUSH	B
	PUSH	D
	PUSH	H
	MVI	C,SRCHF
	LXI	D,FCB
	CALL	BDOS
	POP	H
	POP	D
	POP	B
	LXI	H,MFNAM5
	LXI	D,FCB
	LXI	B,12
	CALL	MOVER
	PUSH	B
	PUSH	D
	PUSH	H
	MVI	C,SRCHN
	LXI	D,FCB
	CALL	BDOS
	POP	H
	POP	D
	POP	B
;
MFNAM2:	INR	A
	STC
	JNZ	MFNAM3
	STA	MFFLG1
	RET
;.....
;
;
MFNAM3:	DCR	A
	ANI	3
	ADD	A
	ADD	A
	ADD	A
	ADD	A
	ADD	A
	ADI	81H
	MOV	L,A
	MVI	H,0
	PUSH	H		; Save name pointer
	LXI	D,MFNAM6+1
	LXI	B,11
	CALL	MOVER
	POP	H
	LXI	D,FCB+1
	LXI	B,11
	CALL	MOVER
	XRA	A
	STA	FCBEXT
	STA	FCBRNO
	RET
;.....
;
;
MOVER:	MVI	A,2
	INR	A
	JPE	MFNAM4
	DB	0EDH,0B0H	; Z-80 'LDIR' instruction
	RET
;.....
;
;
MFNAM4:	MOV	A,M		; Used if an 8080 CPU is active
	STAX	D
	INX	H
	INX	D
	DCX	B
	MOV	A,B
	ORA	C
	JNZ	MFNAM4
	RET
;.....
;
;		(END OF MULTI-FILE ACCESS ROUTINE)
;=======================================================================
;		 CALCULATE FILE TRANSFER TIME
;
;
; Shows the time to transfer a file at various baud rates.  (110-19200)
;
SNDTM:	CALL	ILPRT
	DB	'File open: ',0
	LHLD	RCNT		; Get record count
	CALL	DECOUT		; Print decimal number of records
	PUSH	H
	CALL	ILPRT
	DB	' records (',0
	POP	H		; Get # of 128 byte records
	LXI	D,8		; Divide by 8
	CALL	DVHLDE		; To get # of 1024 byte blocks
	MOV	A,H
	ORA	L		; Check if remainder
	MOV	H,B		; Get quotient
	MOV	L,C
	JZ	$+4		; If 0 remainder, exact kilobytes
	INX	H		; Else, increment to next 'k'
	CALL	DECOUT		; Show # of kilobytes
	LDA	SNDFLG		; Receiving batch mode now?
	ORA	A
	RNZ			; If yes, all done
;
;
; Show transfer time, first for 1k blocks, then for 128 (skip the 1k
; times for slower than 1200 bps.)for 1200 bps
;
	CALL	ILPRT
	DB	'k)',CR,LF,'Send time: ',0
;
	LDA	MSPEED
	CPI	5		; 1200 bps
	JC	XMDSPD		; Skip KMD speed if less than 1200 bps
;
KMDSPD:	LXI	H,KECTBL
	SHLD	RECTBL+1
	CALL	KTIM		; Get file transfer time in BC (minutes)
	CALL	SNDTM1
	CALL	ILPRT
	DB	' - 1k size',CR,LF,'Send time: ',0
;
XMDSPD:	LXI	H,XECTBL
	SHLD	RECTBL+1
	CALL	XTIM		; Get file transfer time in BC (minutes)
	CALL	SNDTM1
	CALL	ILPRT
	DB	' - 128 size',CR,LF,CR,LF,0
	CALL	FILNAM
	CALL	ILPRT
	DB	CR,LF,'File open, ready to send',CR,LF,0
	RET
;.....
;
;
SNDTM1:	PUSH	H		; Save seconds in 'L'
	MOV	L,C
	MOV	H,B
	CALL	DECOUT		; Print decimal number of minutes
	CALL	ILPRT
	DB	':',0
	POP	H		; Get seconds
;
	CALL	ZERO		; See if 10 or more seconds
	CALL	DECOUT		; Print the seconds portion
	CALL	ILPRT
	DB	' at ',0
	CALL	PRTBAUD
	RET
;.....
;
;
PRTBAUD:LXI	H,SPTBL		; Start of baud rate speeds
	MVI	D,0		; Zero the 'D' register
	LDA	MSPEED		; Get speed indicator
	ADD	A		; Index into the baud rate table
	ADD	A
	MOV	E,A		; Now have the index factor in 'DE'
	DAD	D		; Add to 'HL'
	XCHG			; Put address in 'DE' regs.
	MVI	C,PRINT		; Show the baud
	CALL	BDOS
	LDA	MSPEED
	CPI	5
	JC	PRTBD1		; Adds a zero for 2400, 4800, 9600 bps
	CALL	ILPRT
	DB	'0',0
	LDA	MSPEED
	CPI	9
	JC	PRTBD1		; Adds a zero for 19200, 38400, 57600
	CALL	ILPRT
	DB	'0',0
;
PRTBD1:	CALL	ILPRT
	DB	' bps',0
	RET
;.....
;
;
KTABLE:	 IF	NOT STOPBIT	; One stop bit
	DW	5,14,21,27,32,54,101,190,330,525,0
	 ENDIF			; NOT STOPBIT
;
	 IF	STOPBIT		; Two stop bits
	DW	5,13,19,25,29,49,92,173,300,477,0
	 ENDIF			; STOPBIT

KECTBL:	 IF	NOT STOPBIT	; One stop bit
	DB	192,69,46,36,30,18,9,5,3,2,0
	 ENDIF			; NOT STOPBIT
;
	 IF	STOPBIT		; Two stop bits
	DB	192,74,51,38,33,20,10,6,3,2,0
	 ENDIF			; STOPBIT
;
;
XTABLE:	 IF	NOT STOPBIT	; One stop bit
	DW	5,13,19,25,30,48,86,141,210,280,0
	 ENDIF			; NOT STOPBIT
;
	 IF	STOPBIT		; Two stop bits
	DW	5,12,18,23,27,44,79,128,191,255,0
	 ENDIF			; STOPBIT

XECTBL:	 IF	NOT STOPBIT	; One stop bit
	DB	192,74,51,38,32,20,11,8,5,3,0
	 ENDIF			; NOT STOPBIT
;
	 IF	STOPBIT		; Two stop bits
	DB	192,80,53,42,36,22,12,7,5,4,0
	 ENDIF			; STOPBIT
;
SPTBL:	DB	'110$','300$','450$','600$','710$','120$','240$'
	DB	'480$','960$','192$', '384$', '576$'
;.....
;
;
; Pass record count in RCNT: returns file's approximate download/upload
; time in minutes in BC, seconds in 'L', also stuffs the # of mins/secs
; values in PGSIZE if LOGCAL is YES.
;
KTIM:	LXI	H,KTABLE
	JMP	FILTIM
;
XTIM:	LXI	H,XTABLE	; Point to baud factor table
;
FILTIM:	LDA	MSPEED		; Get speed indicator
	MVI	D,0
	MOV	E,A		; Set up for table access
	DAD	D		; Index to proper factor
	DAD	D
	MOV	E,M
	INX	H
	MOV	D,M
	LHLD	RCNT		; Get number of records
	CALL	DVHLDE		; Divide HL by value in DE (records/min)
	PUSH	H		; Save remainder
;
RECTBL:	LXI	H,KECTBL	; Point to divisors for seconds calc.
	MVI	D,0
	LDA	MSPEED		; Get speed indicator
	MOV	E,A
	DAD	D		; Index into table
	MOV	A,M		; Get multiplier
	POP	H		; Get remainder
	CALL	MULHLA		; Multiply 'H' by 'A'
	CALL	SHFTHL
	CALL	SHFTHL
	CALL	SHFTHL
	CALL	SHFTHL
	MVI	H,0		; HL now = seconds (L=secs,H=0)
	MOV	A,L		; See if 59 or less seconds
	CPI	60
	RC			; If yes, all done
	SUI	60		; Otherwise subtract 60 seconds
	MOV	L,A		; Store what is left
	INR	C		; Increments the minutes count
	RET			; End of SNDTM routine
;.....
;
;
ZERO:	MOV	A,L		; Get the number of seconds
	CPI	9+1		; 10 seconds or more?
	RNC			; If yes, disregard
	CALL	ILPRT
	DB	'0',0
	RET
;.....
;
;
;---->	DVHLDE: Divides 'HL' by value in 'DE',
;	Upon exit: 'BC'=quotient,'L'=remainder
;
DVHLDE:	PUSH	D		; Save divisor
	MOV	A,E
	CMA			; Negate divisor
	MOV	E,A
	MOV	A,D
	CMA
	MOV	D,A
	INX	D		; 'DE' is now two's complemented
	LXI	B,0		; Init quotient
;
DIVL1:	DAD	D		; Subtract divisor from dividend
	INX	B		; Bump quotient
	JC	DIVL1		; Loop till sign changes
	DCX	B		; Adjust quotient
	POP	D		; Retrieve divisor
	DAD	D		; Adjust remainder
	RET
;.....
;
;
;---->	MULHLA:  Multiply the value in 'HL' by the value in 'A'
;		 Return with answer in 'HL'
;
MULHLA:	XCHG			; Multiplicand to 'DE'
	LXI	H,0		; Init product
	INR	A		; Adjust multiplier for zero test
;
MULLP:	DCR	A
	RZ
	DAD	D
	JMP	MULLP
;.....
;
;
; Shift 'HL' register pair one bit to the right
;
SHFTHL:	MOV	A,L
	RAR
	MOV	L,A
	ORA	A		; Clear the carry
	MOV	A,H
	RAR
	MOV	H,A
	RNC
	MVI	A,128
	ORA	L
	MOV	L,A
	RET
;.....
;
;		(END OF FILE TRANSFER TIME ROUTINE)
;=======================================================================
;			 CRC SUBROUTINES
;
;
; Check 'CRC' bytes of record just received
;
CRCCHK:	PUSH	H
	LHLD	CRCVAL
	MOV	A,H
	ORA	L
	POP	H
	RZ
	MVI	A,0FFH
	RET
;.....
;
;
; Generate the CRC tables for fast calculations
;
CRCGN:	LXI	H,CRCTBL	; Address at start of 'CRC' lookup table
	MVI	C,0
;
CRCGN1:	XCHG			; Store table location into 'DE'
	LXI	H,0		; Clear 'HL' pair
	MOV	A,C
	PUSH	B
	MVI	B,8
	XRA	H
	MOV	H,A
;
CRCGN2:	DAD	H		; Index into the table
	JNC	CRCGN3
	MVI	A,16		; Using x^ 16 + x^12 + x^5 + 1 algorithm
	XRA	H
	MOV	H,A
	MVI	A,32+1
	XRA	L
	MOV	L,A
;
CRCGN3:	DCR	B
	JNZ	CRCGN2		; Make 8 loops, one for each bit
;
;
; Value now in 'HL', table address still stored in 'DE'.  Exchange, and
; store the 'CRC' value in the two tables after splitting.
;
	POP	B		; Finished borrowing the 'B' reg.
	XCHG			; Address back in 'HL', 'CRC' in 'DE'
	MOV	M,D		; Store 1st part of 'CRC' value
	INR	H		; Move up 256 bytes
	MOV	M,E		; Store 2nd part of 'CRC' value
	DCR	H		; Move back 256 bytes
	INX	H		; Increment to next location
	INR	C		; Done when 'C' reg. turns zero again
	JNZ	CRCGN1		; Now go do the next location
	RET
;.....
;
;
; Update the CRC value from a character in the 'A' register
;
CRCUPD:	PUSH	PSW		; Save all registers just in case
	PUSH	B
	PUSH	D
	PUSH	H
	LHLD	CRCVAL		; Get current value
	XCHG			; Put in 'DE' for now
	MVI	B,0
	XRA	D
	MOV	C,A		; Now have the character in 'BC' pair
	LXI	H,CRCTBL	; Start of 'CRC' lookup-table
	DAD	B		; Index into the 'CRC' table
	MOV	A,M		; Get the value from the table
	XRA	E
	MOV	D,A
	INR	H		; Move 256 bytes for 2nd table location
	MOV	E,M		; Put value there into 'E' register
	XCHG			; Put 'DE' into 'HL'
	SHLD	CRCVAL		; Updated 'CRC' value with this character
	POP	H		; Restore all registers
	POP	D
	POP	B
	POP	PSW
	RET
;.....
;
;
;==================== END OF CRC SUBROUTINE ============================
;
;
;=========================START OF MENU ================================
;
;
MENU0:	LDA	NFILFLG
	ORA	A
	JZ	MENU		; Exit if not saving memory for disk file
	CALL	ILPRT		; Else print message
	DB	CR,LF,'** File still open, use DEL, DIR, WRT, E, L '
	DB	'or T ** ',CR,LF,BELL,0
	JMP	MENU1
;
MENU:	XRA	A
	STA	ABORTFLG	; Null the flag
;
MENU1:	LXI	H,RESTSN	; Restore record numbers..
	LXI	D,RECNOB	; For new file transfer.
	MVI	B,RECNOE-RECNOB
	CALL	MOVE
	LXI	H,RESTROPT	; Restore option table
	LXI	D,OPTBL
	MVI	B,OPTBE-OPTBL
	CALL	MOVE
	XRA	A
	STA	FLTRFLG		; Reset multi-file trans
	STA	FSTFLG
	STA	MFFLG1		; Reset MFACCESS routine
	STA	TIMFLG
	JMP	XPRT
;.....
;
;
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;
;		       MENU OF COMMANDS
;
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;
MENU2:	CALL	CLRTST
	CALL	ILPRT
	DB	'                  Single Letter Commands',CR,LF,LF
	DB	' ?  - Display current settings',CR,LF
MENU3:	DB	' ^  - Function key intercept character, '
	DB	'then (0-9)',CR,LF
	DB	' M  - Display the menu',CR,LF
	DB	' E  - Terminal mode with echo',CR,LF
	DB	' L  - Terminal mode with local echo',CR,LF
	DB	' T  - Terminal mode',CR,LF
	DB	'^Z  - Clears screen (command mode only)',CR,LF
	DB	' R  - Receive an 8-bit binary CP/M file',CR,LF
	DB	' S  - Send an 8-bit binary CP/M file',CR,LF,CR,LF
	DB	'         COMMAND: R (or S) FILENAME.TYP',CR,LF
	DB	'         R and S can use the following subcommands:'
	DB	CR,LF
	DB	'            B  - Batch transfer, can use wildcards '
	DB	'(e.g., *.*)',CR,LF
	DB	'            D  - Disconnect when done'
	DB	CR,LF
	DB	'            K  - Manual request for 1k transmissions'
	DB	CR,LF
	DB	'            Q  - Quiet mode (no messages to console)'
	DB	CR,LF
	DB	'            V  - View ASCII files on CRT during a '
	DB	'file transfer',CR,LF
	DB	'            X  - Inhibits auto 1k request to sender'
	DB	CR,LF
	DB	'            Z  - When done, disconnect, go to CP/M'
	DB	CR,LF,CR,LF
	DB	'         For copying text to disk use T (E or L) '
	DB	'FILENAME.TYP',CR,LF,0
;
	CALL	NXTSCR		; Wait at end of 1nd page
;
;
; Start of 2nd menu page
;
	CALL	ILPRT
	DB	'                Three Letter Commands',CR,LF,LF
	DB	'BYE - Disconnect, then return to CP/M',CR,LF
	DB	'CAL - Dial number',CR,LF
	DB	'CPM - Exit from this program to CP/M',CR,LF
	DB	'DIR - List directory and space free (may specify '
	DB	'drive)',CR,LF
	DB	'DSC - Disconnect from the phone line',CR,LF
	DB	'ERA - Erase file (may specify drive)',CR,LF
	DB	'LOG - Change default drive/user no. (specify '
	DB	'drive/user)',CR,LF
	DB	'         and reset disks i.e., LOG A0: or LOG B:  '
	DB	'(user # unchanged)',CR,LF
	DB	'SET - Set modem baud rate',CR,LF
	DB	'SPD - Set file output speed in terminal mode',CR,LF
	DB	'TBM - Toggle MODEM7/KMD batch mode selection',CR,LF
	DB	'TCC - Toggle CRC/Checksum mode on receive',CR,LF
	DB	'TIG - Toggle ''ignore CTL characters'' on/off',CR,LF
	DB	'TLF - Toggle LF after CR in "L" or "T" mode for '
	DB	'a disk file',CR,LF
	DB	'TRB - Toggle rubout to backspace conversion',CR,LF,LF
	DB	'      The following are terminal text buffer '
	DB	'commands:',CR,LF,LF
	DB	'DEL - Delete memory buffer and file',CR,LF
	DB	'WRT - Write memory buffer to disk file'
	DB	CR,LF,LF,0
;
	CALL	NXTSCR		; Wait at end of 2nd page
;
;
; Write 3rd (and last) menu screen
;
	CALL	ILPRT
	DB	'        Local Commands while in Terminal Mode'
	DB	CR,LF,LF,0
	LDA	EXITCHR
	CALL	SHFTYPE
	DB	'  - Exit to command mode',CR,LF,0
	LDA	FILESND
	CALL	SHFTYPE
	DB	'  - Send file to remote system',CR,LF,0
	LDA	LOGCHR
	CALL	SHFTYPE
	DB	'  - Send log-on message',CR,LF,0
	LDA	NOCONCT
	CALL	SHFTYPE
	DB	'  - Disconnect from the phone line',CR,LF,0
	LDA	LSTCHR
	CALL	SHFTYPE
	DB	'  - Turn printer on (or off)',CR,LF,0
	LDA	BRKCHR
	CALL	SHFTYPE
	DB	'  - Send break tone',CR,LF,0
	LDA	CLEARS
	CALL	SHFTYPE
	DB	'  - Clears screen, terminal mode',CR,LF,LF,0
	LDA	UNSAVCH
	CALL	SHFTYPE
	DB	'  - Stop copy into buffer',CR,LF,0
	LDA	SAVECHR
	CALL	SHFTYPE
	DB	'  - Start copy into buffer',CR,LF,LF
	DB	'             Start and stop may be toggled as often '
	DB	'as desired.',CR,LF
	DB	'             A ";" at start of line indicates buffer '
	DB	'is copying.',CR,LF
	DB	'             X-off automatically used to stop input '
	DB	'when writing',CR,LF
	DB	'                   full buffer to disk, X-on sent to '
	DB	'resume.'
	DB	CR,LF,LF,LF,LF,LF,LF,0 ; Falls on through to "XPRT"
;
;			 (END OF COMMAND MENU)
;=======================================================================
;		    START OF COMMAND LINE HANDLING
;
;
; Check first to see if a file was opened for copying incoming to disk
;
XPRT:	CALL	CRLF		; Turn up a blank line to look nice
	LDA	NFILFLG		; Have a file open for text mode copy?
	ORA	A
	JZ	XPRT1		; If not, exit
;
	CALL	GETSPC		; Otherwise show remaining space
	CALL	ILPRT
	DB	' Bytes of buffer free',CR,LF,LF,0
;
;
; Show disk drive and user number, then command line
;
XPRT1:	MVI	C,CURDSK	; Current disk function
	CALL	BDOS
	ADI	'A'		; Make ASCII
	CALL	TYPE
	CALL	GETUSER		; Get current user number
	ORA	A
	JZ	XPRT2		; Skip if user 0
	MVI	H,0
	MOV	L,A
	CALL	DECOUT		; Show current user area
;
XPRT2:	CALL	ILPRT
	DB	'>>COMMAND: ',0
	XRA	A
	STA	XFLG		; Null the buffer-length flag
;
;
; Get the command line parameters
;
GTCMD:	LXI	D,CMDBUF	; Enter command
	CALL	INBUF		; Get keyboard-entered command
	LDA	CMDBUF+2	; Check first command character
;
GTCMD1:	CPI	'^'		; Function key intercept character
	JZ	FUNCT		; (supplied from 'INTCPT' table)
	CPI	'?'		; Want to see current parameters?
	JZ	CURPAR
	CPI	' '		; If a space, ask again
	JZ	XPRT+3		; Skip the extra line feed
	CALL	STDRV		; See if request for new drive/user
	LXI	D,CMDBUF+2	; Point to command
	CALL	INLNCP		; Compare request with available commands
	DB	'BYE',0
	JNC	BYEBYE
	CALL	INLNCP
	DB	'CPM',0
	JNC	EXIT
	CALL	INLNCP
	DB	'LOG',0
	JNC	LOGNW
	CALL	INLNCP
	DB	'WRT',0
	JNC	WRFIL
	CALL	CRLF		; (1st CR/LF at 'INBUFR')
	CALL	INLNCP
	DB	'DIR',0
	JNC	DIR
	CALL	INLNCP
	DB	'ERA',0
	JNC	ERASEF
	CALL	INLNCP
	DB	'SPD',0
	JNC	STSPD
	CALL	INLNCP
	DB	'TBM',0
	JNC	TGBAT
	CALL	INLNCP
	DB	'TCC',0
	JNC	TGCRC
	CALL	INLNCP
	DB	'TIG',0
	JNC	TIGNR
	CALL	INLNCP
	DB	'TRB',0
	JNC	TGRUB
	CALL	INLNCP
	DB	'TLF',0
	JNC	TGLF
	CALL	INLNCP
	DB	'SET',0
	JNC	STUPENT
	CALL	INLNCP
	DB	'DEL',0
	JNC	NEWFILE
	CALL	INLNCP
	DB	'DSC',0
	JNC	DONETD
	CALL	INLNCP		; 'DE' set from 1st 'INLNCP' call
	DB	'CALL',0
	JNC	NOTVLD
	CALL	INLNCP
	DB	'CAL',0
	JNC	J$DIAL
;
;
; If none of these, compare single characters with the table
;
	LDA	CMDBUF+2
	LXI	H,COMPLIST
	CALL	COMPARE		; Compares list pointed to by HL..
	JC	NOTVLD		; Carry set = no match
	CALL	STFCB		; Loads command buffer into FCB
	CALL	PROCOPT		; Check out the options
	JMP	RSTRT		; Go to work
;.....
;
;
NOTVLD:	CALL	NTVLDMSG
	JMP	XPRT
;.....
;
;
NTVLDMSG:
	CALL	ILPRT
	DB	'++ Invalid command ++',CR,LF,BELL,0
	RET
;.....
;
;
; Clears the screen with a "Z" as first character of the command line
;
CLRS:	CALL	CLRTST		; Clear the CRT
	LXI	SP,STACK	; Cancel all the INBUF PUSHes
	JMP	XPRT1		; Show the command line again
;.....
;
;
; Displays the function key table
;
FUNCT:	LDA	INTCPT		; Get the function key intercept char.
	ANI	07FH		; Strip off any parity
	PUSH	PSW		; Save the character for now
	CALL	CLRTST
	CALL	ILPRT
	DB	'         SPECIAL FUNCTION KEY TABLE'
	DB	CR,LF,LF,0
	POP	PSW		; Get the character back
	CPI	' '		; See if a printing character
	JNC	FUNCT2		; If a printing character, show it
	CPI	ESC
	JNZ	FUNCT1
	MVI	A,'E'
	CALL	TYPE
	MVI	A,'S'
	CALL	TYPE
	MVI	A,'C'
	JMP	FUNCT2
;
FUNCT1:	PUSH	PSW
	CALL	ILPRT
	DB	'CTL-',0
	POP	PSW
	ADI	40H		; Convert binary to ASCII character
;
FUNCT2:	CALL	TYPE		; Show on the CRT
	CALL	ILPRT
	DB	' current function key intercept character',CR,LF,LF,0
;
;
; Shows the functions of the (0-9) keys
;
	LXI	H,FNCTBL-1	; Index into the function key table
	MVI	B,10		; Has ten entries
;
FUNCT3:	INX	H		; Next table location
	MOV	A,M		; Get the binary function number
	ADI	'1'		; Convert binary to ASCII digits
	CPI	'9'+1
	JNZ	FUNCT4
	MVI	A,'0'
;
FUNCT4:	CALL	TYPE
	MVI	A,' '
	CALL	TYPE
;
FUNCT5:	INX	H		; Next table location
	MOV	A,M
	ORA	A		; See if a binary zero
	JZ	FUNCT7
	CPI	CR
	JNZ	FUNCT6
	CALL	ILPRT
	DB	'<CR>',0
	JMP	FUNCT5
;
FUNCT6:	CALL	TYPE
	JMP	FUNCT5
;
FUNCT7:	CALL	CRLF
	DCR	B
	JNZ	FUNCT3
	CALL	J$ILPRT
	DB	CR,LF,LF,LF,LF,LF,LF,0
	JMP	XPRT
;.....
;
;
BYEBYE:	CALL	ILPRT
	DB	CR,LF,'  wait... ',0
	CALL	STPCHR		; Stop any incoming if possible
	LDA	NODTR		; Support DTR?
	ORA	A
	JNZ	$+9		; If not, call J$DSCONT
	CALL	J$GOODBYE	; Else disconnect normally with DTR
	JMP	$+6
	CALL	J$DSCONT
	CALL	ILPRT
	DB	CR,'<< Disconnected, exit to CP/M >>',CR,LF,0
	JMP	EXIT		; Return to CP/M
;.....
;
;
DIR:	MVI	C,CURDSK
	CALL	BDOS
	STA	DISKSAV
	CALL	DRLST
	LDA	DISKSAV
	MOV	E,A
	MVI	C,SELDSK
	CALL	BDOS
	JMP	XPRT
;.....
;
;
ERASEF:	LXI	D,CMDBUF	; Put command line into FCB at 'HL'
	LXI	H,FCB
	CALL	CMDLINE
	CALL	MOVEFCB		; Move FCB+16 to FCB
	LDA	FCB+1
	CPI	' '
	JZ	NOTVLD		; Go if no file specified
	LXI	D,FCB
	MVI	C,SRCHF
	CALL	BDOS
	INR	A		; 0 if file not found
	JNZ	ERAFILE		; Ok, go erase
	CALL	ILPRT
	DB	'++ File not found ++',CR,LF,BELL,0
	JMP	XPRT
;.....
;
;
ERAFILE:LXI	D,FCB
	MVI	C,ERASE
	CALL	BDOS
	CALL	ILPRT
	DB	'File erased',CR,LF,0
	JMP	XPRT
;.....
;
;
LOGNW:	LDA	NFILFLG		; File open for memory save to disk?
	ORA	A
	JNZ	NORESET		; If yes, do not reset disk drive now
	LDA	CMDBUF+6	; Any disk drive specified?
	CPI	' '
	JNZ	LOGNW1		; If not a blank, exit
	CALL	GETDISK		; If not, use current drive
	ADI	'A'		; To compensate for next line
;
LOGNW1:	SUI	'A'
	CPI	15+1		; For drives 0-15
	JNC	NOTVLD		; If more than 15, display error message
	STA	DISKSAV		; Store requested drive
	CALL	GETUSER		; Pick up current user number
	MOV	B,A		; Save it
	LDA	CMDBUF+7	; Get new user number
	CALL	CHRCK		; Check the character
	CALL	FINDUSER
	LDA	CMDBUF+8	; Get 2nd digit
	CALL	CHRCK		; Check the character
	CALL	FINDUSER+2
;
LOGNW2:	CALL	SAVEUSER
	MVI	C,RESET
	CALL	BDOS
	LDA	DISKSAV
	MOV	E,A
	MVI	C,SELDSK
	CALL	BDOS
	LDA	SAVUSR
	MOV	E,A
	CALL	STUSER
	JMP	XPRT
;.....
;
;
CHRCK:	CPI	' '
	JZ	CHRCK1
	CPI	':'		; In case of A: or A1: or A11:	(etc.)
	RNZ
;
CHRCK1:	POP	PSW		; Reset the 'CALL' on the stack
	JMP	LOGNW2
;.....
;
;
FINDUSER:
	MVI	B,0		; Zero the 'B' reg. for 1st time through
	CALL	NUMCHK		; If neither, see if a valid number
	MOV	C,A		; Save
	MOV	A,B		; Get save first digit
	ADD	A		; X2
	ADD	A		; X4
	ADD	A		; X8
	ADD	B		; X9
	ADD	B		; X10
	ADD	C
	MOV	B,A		; Save
	RET
;.....
;
;
SAVEUSER:
	MOV	A,B
	CPI	15+1		; User numbers are 0-15
	JNC	NOTVLD
	STA	SAVUSR
	RET
;.....
;
;
NUMGET:	LXI	D,CMDBUF
	CALL	INBUF
	LDA	CMDBUF+2	; Get number
	CPI	' '
	RZ
;
NUMCHK:	SUI	'0'		; Remove ASCII bias
	CPI	9+1
	RC			; Ok if 9 or less
	POP	H		; Remove 1st call from the stack
	POP	H		; Remove 2nd call from the stack
	JMP	NOTVLD
;
GETUSER:MVI	E,0FFH		; Get current user
;
STUSER:	MVI	C,USER		; Set up BDOS call
	JMP	BDOS
;.....
;
;
GETDISK:MVI	C,CURDSK	; Get current drive
	JMP	BDOS
;.....
;
;
NORESET:CALL	ILPRT
	DB	'++      Terminal mode file open      ++',CR,LF
	DB	'++ Use WRT or DEL before LOG command ++',CR,LF
	DB	CR,LF,BELL,0
	XRA	A
	JMP	XPRT
;.....
;
;
STSPD:	CALL	ILPRT
	DB	'Delay between chars. (0-9): ',0
;
STSPD1:	CALL	STAT
	JZ	STSPD1
	CALL	KEYIN
	CALL	TYPE
	CALL	SAVEA
	CPI	CR
	JZ	STSPD2
	SUI	'0'
	CPI	9+1
	JNC	NOTVLD
	ADD	A
	ADD	A
	STA	BYTDLY
;
STSPD2:	CALL	ILPRT
	DB	'Delay at end of line (0-9): ',0
;
STSPD3:	CALL	STAT
	JZ	STSPD3
	CALL	KEYIN
	CALL	TYPE
	CALL	SAVEA
	CPI	CR
	JZ	STSPD4
	SUI	'0'
	CPI	9+1
	JNC	NOTVLD
	STA	CRDLY
;
STSPD4:	CALL	SPDMSG
	JMP	XPRT
;.....
;
;
SPDMSG:	CALL	ILPRT
	DB	CR,LF,'Char. delay (terminal file mode) is:  ',0
	LDA	BYTDLY
	CPI	10
	JNC	SPDMSG1
	PUSH	PSW
	CALL	ILPRT
	DB	' ',0
	POP	PSW
;
SPDMSG1:PUSH	H
	MOV	L,A
	MVI	H,0
	CALL	DECOUT
	POP	H
	CALL	ILPRT
	DB	' ms. per character',CR,LF
	DB	'Line  delay (terminal file mode) is: ',0
	LDA	CRDLY
	PUSH	H
	MOV	L,A
	MVI	H,0
	CALL	DECOUT
	POP	H
	CALL	ILPRT
	DB	'00 ms. per CR character',CR,LF,0
	RET
;......
;
;
SAVEA:	PUSH	PSW
	CALL	ILPRT
	DB	CR,LF,0
	POP	PSW
	RET
;.....
;
;
; Set the drive/user area if any requested
;
STDRV:	LDA	CMDBUF+3	; Allow for B: or B2: or B15:, etc.
	CPI	':'
	JZ	STDRV1
	LDA	CMDBUF+4
	CPI	':'
	JZ	STDRV1
	LDA	CMDBUF+5
	CPI	':'
	RNZ			; If no drive/user requested, return
	LDA	CMDBUF+2
	CPI	'S'		; Allows S B:FILENAME.EXT
	RZ
	CPI	'R'		; Allows R B:FILENAME.EXT
	RZ
;
;
; First check for the drive
;
STDRV1:	POP	H		; Remove "CALL STDRV" from stack
	LDA	CMDBUF+2	; Get the disk drive
	SUI	'A'		; Convert to binary value
	CPI	15+1		; For drives 0-15
	JNC	NOTVLD		; Answers over 15 not valid this program
;
	MOV	E,A
	MVI	C,SELDSK	; Select requested drive
	CALL	BDOS
;
;
; See if any user area requested
;
	LDA	CMDBUF+3	; See if just plain B: and no user area
	CPI	':'
	JZ	XPRT		; If yes, finished
;
;
; Since there was, enter the request
;
	SUI	'0'		; Convert to binary value
	CPI	1		; If a '1', could be units or tens
	JNZ	STDRV3		; If not, numbers stop at 15 so exit
	LDA	CMDBUF+4	; Check for a 2nd digit
	CPI	':'		; Accecpt '1' for  B1:	etc.
	JNZ	STDRV2
	MVI	A,1
	JMP	STDRV4
;
STDRV2:	CPI	'0'
	JC	STDRV5		; If less, not a valid number, ignore
	SUI	'0'-10		; Leave the '10' in as two digits used
;
STDRV3:	CPI	15+1		; User areas are 0-15 for this program
	JNC	NOTVLD
;
STDRV4:	MOV	E,A
	CALL	STUSER
	JMP	XPRT		; Back to work
;
STDRV5:	MVI	A,1
	JMP	STDRV2
;.....
;
;
; Set MODEM7/KMD batch selection
;
TGBAT:	LDA	KMDODE		; Get current selection and switch it
	CMA
	STA	KMDODE
	CALL	TGBAT1		; Show on CRT it has been changed
	JMP	XPRT
;.....
;
;
; Set CRC/checksum toggle
;
TGCRC:	LDA	CRCDFLT		; Get present value and switch it
	CMA
	STA	CRCDFLT
	CALL	TGCRC1		; Show on CRT it has been changed
	JMP	XPRT
;.....
;
;
TGBAT1:	LDA	KMDODE
	ORA	A
	JZ	TGBAT2
	CALL	ILPRT
	DB	'MODEM7 batch mode',CR,LF,0
	RET
;
TGBAT2:	CALL	ILPRT
	DB	'KMD batch mode',CR,LF,0
	RET
;.....
;
;
TGCRC1:	CALL	ILPRT
	DB	'Mode: ',0
	LDA	CRCDFLT		; See if set for 'CRC' or 'checksum'
	ORA	A
	JZ	CHEKMSG
	CALL	ILPRT
	DB	'CRC',CR,LF,0
	RET
;
CHEKMSG:CALL	ILPRT
	DB	'checksum',CR,LF,0
	RET
;.....
;
;
TIGNR:	LDA	IGNRCTL
	CMA
	STA	IGNRCTL
	CALL	TIGNR1
	JMP	XPRT
;.....
;
;
TIGNR1:	CALL	ILPRT
	DB	'Incoming control characters ',0
	LDA	IGNRCTL
	ORA	A
	JZ	NOIGNR
	CALL	ILPRT
	DB	'ignored',CR,LF,0
	RET
;.....
;
;
NOIGNR:
	CALL	ILPRT
	DB	'received',CR,LF,0
	RET
;.....
;
;
TGRUB:	LDA	CONVRUB
	CMA
	STA	CONVRUB
	CALL	TGRUB1
	JMP	XPRT
;.....
;
;
TGRUB1:	LDA	CONVRUB
	ORA	A
	JZ	NORUBMSG
	CALL	ILPRT
	DB	'Rub is backspace',CR,LF,0
	RET
;.....
;
;
NORUBMSG:
	CALL	ILPRT
	DB	'Rub is rub',CR,LF,0
	RET
;.....
;
;
TGLOC1:	CALL	ILPRT
	DB	'Use ESC before local command in terminal mode',CR,LF,0
	RET
;.....
;
;
TGLF:	LDA	ADDLFD
	CMA
	STA	ADDLFD
	CALL	TGLF1
	JMP	XPRT
;.....
;
;
TGLF1:	CALL	ILPRT
	DB	'LF ',0
	LDA	ADDLFD		; Adding LF after CR?
	ORA	A
	JNZ	LFMSG		; If yes, exit
	CALL	ILPRT
	DB	'NOT ',0
;
LFMSG:	CALL	ILPRT
	DB	'sent after CR in "L" or "T" for a disk file',CR,LF,0
	RET
;.....
;
;
RATE:	CALL	ILPRT
	DB	'Modem speed is: ',0
	CALL	PRTBAUD		; Display the speed
	CALL	ILPRT
	DB	CR,LF,0
	RET
;.....
;
;
XOFFMSG:CALL	ILPRT
	DB	'XOFF testing used in terminal mode file output'
	DB	CR,LF,0
	RET
;.....
;
;
GETANS:	LXI	D,CMDBUF
	CALL	INBUF
	LDA	CMDBUF+2	; Get answer
	CPI	' '
	CMC			; Set the carry flag
	RZ
	MOV	B,A
	CPI	'N'
	MVI	A,0
	RZ
	MOV	A,B
	CPI	'Y'
	MVI	A,1
	RZ
	POP	PSW		; Preserve stack
	JMP	NOTVLD
;.....
;
;
STUPENT:MVI	A,1
	STA	MANUAL		; Speed is being manually selected
	LXI	D,CMDBUF+1
	CALL	J$STUPR		; Go set the speed
	CALL	RATE
	JMP	XPRT
;.....
;
;
NEWFILE:LDA	NFILFLG		; File open for disk save?
	ORA	A
	JZ	NOFILOPN	; If not, show "no file open" message
	LDA	FCB3+1		; Check that file was requested
	CPI	' '
	JZ	NOFILOPN	; If no file, do not erase
	LXI	D,FCB3		; Otherwise erase the old file
	MVI	C,ERASE
	CALL	BDOS
	XRA	A
	STA	NFILFLG		; No file mentioned, reset flags
	STA	SAVEFLG
	LXI	H,FCB3
	CALL	INITFCB
	LXI	H,BUFFER	; Reset flags to bottom of ram just to
	SHLD	HLSAV		; Insure they are there
	JMP	XPRT
;.....
;
;
WRFIL:	LDA	NFILFLG		; Saving memory for a disk file?
	ORA	A
	JZ	NOFILOPN	; If not, nothing to write to disk
	CALL	WRFIL1		; Close the file
	STA	SAVEFLG
	STA	WRFLG
	LXI	H,FCB3
	CALL	INITFCB		; Blank out 'FCB' to written file
	LXI	H,BUFFER	; Can't be erased
	SHLD	HLSAV		; Reset to buffer start for next time
	JMP	XPRT
;...
;
;
WRFIL1:	LDA	FCB3+1		; Check that file was requested
	CPI	' '
	RZ
	CALL	WRDSK		; Write buffer to disk if not empty
;
WRFIL2:	LXI	D,FCB3		; Close the file
	MVI	C,CLOSE
	CALL	BDOS
;
;
; Show name of file that is being closed
;
	MVI	A,CR
	CALL	TYPE
	MVI	A,LF
	CALL	TYPE
	MVI	B,8
	LXI	H,FCB3+1
	CALL	WRFIL4
	MOV	A,M
	CPI	' '+1
	JC	WRFIL3
	MVI	A,'.'
	CALL	TYPE
;
WRFIL3:	MVI	B,3
	CALL	WRFIL4
	CALL	ILPRT
	DB	' closed',CR,LF,0
	XRA	A
	STA	NFILFLG		; File written, reset flags
	RET
;...
;
;
WRFIL4:	MOV	A,M
	CPI	' '
	JZ	WRFIL5
	CALL	TYPE
;
WRFIL5:	INX	H
	DCR	B
	JNZ	WRFIL4
	RET
;.....
;
;
NOFILOPN:
	CALL	ILPRT
	DB	CR,LF,'++ No file open ++',CR,LF,BELL,0
	JMP	XPRT
;.....
;
;
NEWLINE:MVI	A,CR		; Puts CRLF at memory pointed by 'DE'
	STAX	D		; Store it
	MVI	A,LF		; Line feed
	INX	D		; Bump pointer
	STAX	D		; Store lf
	INX	D		; Bump pointer
	RET
;.....
;
;
SPACES:	MVI	A,' '		; Space
	STAX	D
	INX	D		; 1
	STAX	D
	INX	D		; 2
	STAX	D
	INX	D		; 3
	RET
;.....
;
;
COMPARE:MOV	B,M		; Compares 'A' reg. with list
;
COMPLP:	INX	H
	CMP	M
	JZ	VALID
	DCR	B
	JNZ	COMPLP
	STC
;
VALID:	RET
;.....
;
;
NXTSCR:	CALL	ILPRT
	DB	'[more] ',0
;
NOKEY1:	CALL	STAT		; Get keyboard status
	JZ	NOKEY1		; Keep looping until keypress
	CALL	KEYIN		; Gobble up keypress
	MVI	B,CLEARSC	; CTL-Z to clear screen?
	CMP	B
	JNZ	NOKEY2		; If not, exit
	JMP	CLRS		; Erase screen, back to command
;
NOKEY2:	CPI	'C'-40H		; CTL-C to abort?
	JNZ	CLRTST
	POP	H		; Clear stack of return address
	CALL	CRLF		; Turn up a blank line
	JMP	XPRT
;.....
;
;
CLRTST:	LDA	CLEAR		; "Clear screen" character used?
	ORA	A
	JZ	CLRT2		; If not, exit
;
	CPI	' '		; See if a control character
	JC	CLRT1
	PUSH	PSW		; Save the "Clear screen" character
	MVI	A,ESC		; Send an 'Escape' character first
	CALL	TYPE
	POP	PSW		; Get the "Clear screen" character back
;
CLRT1:	JMP	TYPE		; Send it, done
;
CLRT2:	MVI	A,CR		; Else use a bunch of line feeds
	CALL	TYPE
	MVI	B,24
	MVI	A,LF
;
LFLOOP:	CALL	TYPE
	DCR	B
	JNZ	LFLOOP
	RET
;.....
;
;
CURPAR:	CALL	CLRTST
	CALL	ILPRT
	DB	'                Current Settings',CR,LF,LF,0
	CALL	TGCRC1		; CRC/checksum mode
	CALL	TGBAT1		; MODEM7/KMD batch mode
	CALL	TGRUB1		; Toggle rub to backspace
	CALL	LSTMS
	CALL	RATE
	CALL	TIGNR1		; Toggle incoming CTL-characters
	CALL	ILPRT
	DB	'Terminal mode file buffer is ',0
	LDA	NFILFLG		; Saving memory for a disk file?
	ORA	A
	JNZ	ACTIVE		; If yes, go say "active"
	CALL	ILPRT
	DB	'in',0		; If not, say "inactive"
;
ACTIVE:	CALL	ILPRT
	DB	'active',CR,LF,'Unused portion of buffer is ',0
	CALL	GETSPC
	CALL	ILPRT
	DB	' bytes',CR,LF,0
	CALL	TGLOC1
	CALL	XOFFMSG
	CALL	TGLF1
	CALL	SPDMSG
	CALL	ILPRT
	DB	CR,LF,LF,LF,LF,LF,LF,0
	JMP	XPRT
;.....
;
;
GETSPC:	LXI	D,BUFTOP	; Top of memory buffer
	LHLD	HLSAV		; Current buffer location
	XCHG
	XRA	A		; Clear the carry bit, if set
	SUB	E
	MOV	L,A
	MOV	A,H
	SBB	D
	MOV	H,A
	CALL	DECOUT		; Print the space remaining
	RET
;.....
;
;
;***********************************************************************
;
;	D - A - T - A	 A - R - E - A
;
;***********************************************************************
;
;
COMPLIST: DB	6, 'S',	'R', 'T', 'E', 'L', 'M'
;.....
;
;
; OPTION TABLE
;
OPTBL	EQU	$
BATCHFLG: DB	'B'
DISCFLG:DB	'D'
KKMD:	DB	'K'
QFLG:	DB	'Q'
RSEEFLG:DB	'R'
SSEEFLG:DB	'S'
VSEEFLG:DB	'V'
XMODEM:	DB	'X'
XITFLG:	DB	'Z'
OPTBE	EQU	$		; Transfer when program initially called
;
;
; The following must be in the same order as the table above:
;
RESTROPT: DB	'B','D','K','Q','R','S','V','X','Z'
;
;
; The next 16 bytes equal the number of bytes between RECNOB and
; RECNOE.
;
RESTSN:	DB	0,0,0,0,0
	DB	0,0,0,0,0
	DB	0,0,0,0
	DW	BUFFER
;
RECNOB	EQU	$		; Start of table marker
ACCERR:	DB	0,0		; \ No 'ACK' error count for 1k ratio
CHKEOT:	DB	0		; \
DATAFLG:DB	0		; \
EOFLG:	DB	0		; \
ERRCT:	DB	0		; \  16 bytes between table markers
FRSTIM:	DB	0		; /
RCDCNT:	DB	0,0		; /  (These get reset each batch mode
RCNT:	DB	0,0		; /  file that is sent)
RECNBF:	DB	0		; /
RECNO:	DB	0,0		; /
RECPTR:	DW	BUFFER		; /
RECNOE	EQU	$		; End of table marker
;
;
; Additional 16-bit initialized storage
;
CRCVAL:	DW	0
DIALCT:	DW	0
HLSAV:	DW	BUFFER
HLSAV1:	DW	PBUFF
HLSAV2:	DW	PBUFF
;
;
; Additional general purpose initialized storage
;
ABORTFLG: DB	0
CRCFLG:	DB	0
CRFLAG:	DB	0
DLYFLG:	DB	0
ECHOFLG:DB	0
EXACFLG:DB	0
DONEFLG:DB	0
FNKFLG:	DB	0		; Function key activity flag
FSTFLG:	DB	0
GOTONE:	DB	0
KFLG:	DB	0		; Flag for 1k blocks
LISTFLG:DB	0
LOCFLG:	DB	0
MFFLG1:	DB	0
NFILFLG:DB	0
OPTION:	DB	0
RCVCNT:	DB	0		; Record number received
RCVTRY:	DB	0		; Limits tries for batch mode header
SAVEFLG:DB	0
	DB	0
KMDODE:	DB	0		; Selects MODEM7/KMD batch
WRFLG:	DB	0
XFLG:	DB	0
CMDBUF:	DB	80H,0		; Command buffer control area
;
;
; General purpose unitialized storage area
;
	DS	128		; Storage area for 'CMDBUF'
BGNMS:	DS	2
TIMFLG:	DS	1
FLTRFLG:DS	1
CHRFLG:	DS	1
TIMVAL:	DS	2
QUIKTIM:DS	2
DISKNO:	DS	1
DISKSAV:DS	1
DSTORE:	DS	1
FILECT:	DS	1
FTYCNT:	DS	1
MAXRAM:	DS	1
NAMECT:	DS	1
NBSAVE:	DS	2
OLDUSER:DS	1
SAVUSR:	DS	1
SNDFLG:	DS	1
;
FCB3:	DS	33
FCB4:	DS	33
FCBBUF:	DS	15
MFNAM5:	DS	12		; Requested name
MFNAM6:	DS	12		; Current name
	DS	100		; Stack depth
;
;
EVNPAGE	EQU	($+255)/256*256	; Sets buffers on even page
;
;
	ORG	EVNPAGE
;
;
STACK	EQU	EVNPAGE-2	; Store original stack pointer
CRCTBL:	DS	512		; Two tables of 128 bytes each
BUFFDSK:DS	128		; Buffer for disk save
BUFFPNT:DS	128		; Buffer for printer
BUFFER:	DS	1024*BUFSIZ	; Send/receive file buffer
BUFSTR	EQU	BUFFER+126	; For storing batch mode file length
BUFTOP:	DS	0		; Filled in when length is found
PBUFF	EQU	$		; Printer buffer starts here
NAMEBUF	EQU	$		; Batch-mode filenames buffer
;.....
;
;
; BDOS EQUATES
;
RDCON	EQU	1
WRCON	EQU	2
LIST	EQU	5
PRINT	EQU	9
CONST	EQU	11
CPMVER	EQU	12
RESET	EQU	13
SELDSK	EQU	14
OPEN	EQU	15
CLOSE	EQU	16
SRCHF	EQU	17
SRCHN	EQU	18
ERASE	EQU	19
READ	EQU	20
WRITE	EQU	21
MAKE	EQU	22
CURDSK	EQU	25
STDMA	EQU	26
DSKALL	EQU	27
DSKPAR	EQU	31
USER	EQU	32
FILSIZ	EQU	35
BDOS	EQU	0005H
FCB	EQU	5CH
FCBEXT	EQU	FCB+12
FCBSNO	EQU	FCB+32
FCBRNO	EQU	FCB+32
FCB2	EQU	6CH
TBUF	EQU	80H
;.....
;
;
	END
