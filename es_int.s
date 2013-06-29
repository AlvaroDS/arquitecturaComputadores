**************************
* E/S por interrupciones *
**************************
*Macros equate para la asignacion de posiciones de memoria a registros:
MRA:  EQU $EFFC01
MRB:	EQU $EFFC11
CSRA:	EQU $EFFC03
CSRB:	EQU $EFFC13
ACR:	EQU $EFFC09
CRA:	EQU $EFFC05
CRB:	EQU $EFFC15
IVR:	EQU $EFFC19
IMSR:	EQU $EFFC0B

*Reset:
	ORG $0

	DC.L $8000
	DC.L $3600

	ORG $400
*Bufferes internos de las subrutinas y variables globales asociadas:
BUFPA:		DS.B 2000
IN_BPA:		DS.L 1
CNT_BPA:	DS.W 1

BUFPB:		DS.B 2000
IN_BPB:		DS.L 1
CNT_BPB:	DS.W 1

BUFSA:		DS.B 2000
IN_BSA:		DS.L 1
CNT_BSA:	DS.W 1

BUFSB:		DS.B 2000
IN_BSB:		DS.L 1
CNT_BSB:	DS.W 1


BUFFER:		DS.B 3000 * dir de buffer que se pasa como parametro.

*Main:
	ORG $3600

MAIN:

	MOVE.L  #BUS_ERROR,8    * Bus error handler
	MOVE.L  #ADDRESS_ER,12  * Address error handler
	MOVE.L  #ILLEGAL_IN,16  * Illegal instruction handler
	MOVE.L  #PRIV_VIOLT,32  * Privilege violation handler
	MOVE.L  #ILLEGAL_IN,40  * Illegal instruction handler
	MOVE.L  #ILLEGAL_IN,44  * Illegal instruction handler
	BSR INIT
	MOVE.W #10,-(A7)
	MOVE.w #5,-(A7)
	MOVE.L #BUFFER,-(A7)
	BSR SCAN
	BREAK
*________________________________________________________*
*						INIT
*________________________________________________________*
*La programación de los dispositivos se ha realizado en órden con
*el enunciado de la misma subrutina.
INIT:	MOVE.B #%00000011,MRA
	MOVE.B #%00000011,MRB
	MOVE.B #%00000000,MRA
	MOVE.B #%00000000,MRB
	MOVE.B #%11001100,CSRA
	MOVE.B #%11001100,CSRB
	MOVE.B #%00000000,ACR
	MOVE.B #%00000101,CRA
	MOVE.B #%00000101,CRB
	MOVE.B #%00101000,IVR * D'40->vector de interrupción
	MOVE.B #%00100010,IMSR
	
	MOVE.L #RTI,A1 * Cargamos en A1 la dir. absoluta de RTI
	MOVE.L A1,$100 * y seguidamente la volcamos en la dirección 0x100,
				   * que será el resultado del vector*4 = 0x40*4
				   
	* Inicialización de bufferes. Se carga la dir.MP en la palabra encargada
	* de contener la dir. en la que comienza, se inicializa a 0 el contador de
	* bytes almacenados en los susodichos.
	MOVE.L #BUFPA,IN_BPA
	CLR.W CNT_BPA
	
	MOVE.L #BUFPB,IN_BPB
	CLR.W CNT_BPB
	
	MOVE.L #BUFSA,IN_BSA
	CLR.W CNT_BSA
	
	MOVE.L #BUFSB,IN_BSB
	CLR.W CNT_BSB
	
	RTS

*________________________________________________________*
*						PRINT
*________________________________________________________*
*Comprobamos que el parámetro tamaño no sea <1
PRINT:	MOVE.W 10(A7),D2 *D2 guarda el tamaño de bytes a escanear
		CMP.W #1,D2
		BLT ERR
		MOVE.W 8(A7),D1 *Ahora comprobamos que el parámetro
		CMP.W #0,D1		* "descriptor" sea válido, osea, =0 ó =1
		BEQ P_OK
		CMP.W #1,D1
		BEQ P_OK
		JMP ERR	

P_OK:	CLR.L D0		*Reseteamos D0
		
		RTS
*________________________________________________________*
*						SCAN
*________________________________________________________*
*Comprobamos que el parámetro tamaño no sea <1
SCAN:	MOVE.W 10(A7),D2 *D2 guarda el tamaño de bytes a escanear
		CMP.W #1,D2
		BLT ERR
		*Y que el nº de descriptor sea válido, esto es, =0 ó =1
		MOVE.W 8(A7),D1 
		CMP.W #0,D1		
		BEQ S_OK
		CMP.W #1,D1
		BEQ S_OK
		
		JMP ERR

S_OK	CLR.L D0		*Reseteamos D0
		
		RTS
	
*________________________________________________________*
*						RTI
*________________________________________________________*
RTI: 	RTS


*________________________________________________________*
*						OTROS
*________________________________________________________*
* Error, forzar fin de subrutina devolviendo -1 en D0
ERR:	MOVE.L #$FFFFFFFF,D0
		RTS

BUS_ERROR:  BREAK * Bus error handler
            NOP
ADDRESS_ER: BREAK * Address error handler
            NOP
ILLEGAL_IN: BREAK * Illegal instruction handler
            NOP
PRIV_VIOLT: BREAK * Privilege violation handler
            NOP
