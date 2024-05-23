BDOS	EQU	5
FCB1	EQU	5CH	; CP/M FCB 1
FCB2	EQU	6CH

CR	EQU	13
LF	EQU	10

;-----------------------------
; JAIR Serial Ports 
;-----------------------------
COM1	equ	20h		;COM1 base port address
COM2	equ	28h		;COM2 base port address

COMDLS	equ	0
COMDMS	equ	1
COMLCR	equ	3

COMDLAB	equ	80h		;divisor latch access bit (DLAB)
COM8N1	equ	03h		;8N1
COM110	equ	1047		;110 baud rate
COM300	equ	384		;300 baud rate
COM1200	equ	96		;1200 baud rate
COM2400	equ	48		;2400 baud rate
COM9600	equ	12		;9600 baud rate
COM192K	equ	6		;19.2K baud rate
COM384K	equ	3		;38.4K baud rate

;
	ORG	100H

;
; Use CP/M stack
;
	LDA	FCB2+1	;
	CPI	'1'	;COM1?
	JNZ	BAUD

	MVI	A,COM1
	STA	PORT

BAUD:	LDA	FCB1+1	;check for baud rate argument
	CPI	' '
	JZ	HELP	; PRINT HELP MSG IF NO FILES SPECIFIED

	CPI	'1'
	JZ	BAUD1

	CPI	'3'
	JZ	BAUD3

	LXI	H,COM2400
	CPI	'2'
	JZ	SETBD

	LXI	H,COM9600
	CPI	'9'
	JZ	SETBD

	JMP	HELP	;invalid baud rate

BAUD1:	LDA	FCB1+2	;check for baud rate argument

	LXI	H,COM110
	CPI	'1'
	JZ	SETBD

	LXI	H,COM1200
	CPI	'2'
	JZ	SETBD

	LXI	H,COM192K
	CPI	'9'
	JZ	SETBD

	JMP	HELP	;invalid baud rate

BAUD3:	LDA	FCB1+2	;check for baud rate argument

	LXI	H,COM300
	CPI	'0'
	JZ	SETBD

	LXI	H,COM384K
	CPI	'8'
	JZ	SETBD

	JMP	HELP		;invalid baud rate

SETBD:	MVI	B,COMLCR	;set DLAB
	MVI	C,COMDLAB
	CALL	OUTP

	MVI	B,COMDLS	;divisor latch (LS)
	MOV	C,L
	CALL	OUTP
;
	MVI	B,COMDMS	;divisor latch (MS)
	MOV	C,H
	CALL	OUTP

	MVI	B,COMLCR	;clear DLAB
	MVI	C,COM8N1
	CALL	OUTP

	RET			;return to CP/M
;
; Output C to PORT + B
;
OUTP:	LDA	PORT
	ADD	B
	STA	OUTOP+1
	MOV	A,C

OUTOP:	OUT	COM1

	RET

HELP:	LXI	D,HLPMSG
	JMP	PRINT

HLPMSG:	DB	'SETBAUD <BAUD> [1]',CR,LF
	DB	'BAUD = 110, 300, 1200, 2400, 9600, 19200 or 38400',CR,LF
	DB	CR,LF
	DB	'Set JAIR COM2 baud rate to BAUD. Specify 1 for COM1.',CR,LF,'$'
;
;	PRINT (MSG)
;		DE^=MSG TERMIATED BY '$'
PRINT:	MVI	C,9
	JMP	BDOS

;
;	DATA AREA
;
PORT:	DB	COM2

	END
