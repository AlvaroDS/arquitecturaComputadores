******************
* E/S programada *
******************

*Macros equate para la asignacion de posiciones de memoria a registros:
MRA:  EQU $EFFC01
CSRA:	EQU $EFFC03
ACR:	EQU $EFFC09
CRA:	EQU $EFFC05
RECTRA:	EQU $EFFC07 *registros del buffer para recepcion/transmision
*Reset:
	ORG $0

	DC.L $8000
	DC.L $3600

*Direcciones de los parametros

BUF: 	DS.B 200 *Reserva de caracteres 
TAM:	DC.W $C	 *Numero de caracteres a leerse


*Main:
	ORG $3600
MAIN:		
	* Manejadores de excepciones. Obtenido del ejemplo del enunciado *

	MOVE.L  #BUS_ERROR,8    * Bus error handler
	MOVE.L  #ADDRESS_ER,12  * Address error handler
	MOVE.L  #ILLEGAL_IN,16  * Illegal instruction handler
	MOVE.L  #PRIV_VIOLT,32  * Privilege violation handler
	MOVE.L  #ILLEGAL_IN,40  * Illegal instruction handler
	MOVE.L  #ILLEGAL_IN,44  * Illegal instruction handler

	BSR INIT
	MOVE.W TAM,D2	*Se apila el tamanyo del texto
	MOVE.W D2,-(A7)
	PEA BUF 	*Se apila la direccion efectiva del buffer
	BSR SCAN
	BSR PRINT
	BREAK

* Subrutina init
INIT: 	MOVE.B #%00000011,MRA 	* 8 bits por caracter
	MOVE.B #%00000000,MRA 	* Sin eco
	MOVE.B #%11001100,CSRA 	* 38400 en transmision y recepcion
	MOVE.B #%00000000,ACR
	MOVE.B #%00000101,CRA
	RTS

*Subrutina scan(buffer, tamano)
SCAN:	MOVE.L 4(A7),A2	 *Recuperacion de parametros
	MOVE.W 8(A7),D2	
	CLR.L D0	 *Inicializamos a 0 el contador de chars leidos

BUCLE1: BTST #0,CSRA 	 *Se analiza RxRDY del SRA. Si es 0, no se ha 
	BEQ BUCLE1	 *recibido ningun caracter nuevo.
	
	MOVE.B RECTRA,D1 *Se lleva a D1 el caracter leido
	MOVE.B D1,(A2)	 *y luego se carga en el buffer
	
	ADD.L #1,D0	 *Incremento del contador de caracteres y del puntero
	ADD.L #1,A2	 *al buffer, decremento del param tamano.
	SUB.W #1,D2	 *.L para 4 bytes y .W para 2 bytes

	CMP.W #0,D2	 *Si D2 resulta ser 0, sigue. Si no, repetir.
	BNE BUCLE1

	RTS		 *Retorno de subrutina

*Subrutina print(buffer, tamano)
PRINT:	MOVE.L 4(A7),A2	 *Identico a SCAN
	MOVE.W 8(A7),D2	
	CLR.L D0

BUCLE2:	BTST #2,CSRA 	 *Se analiza TxRDY del SRA. 
	BEQ BUCLE2

	MOVE.B (A2),D1	 *Esta vez cargamos en D1 char a char lo que hay en el
	MOVE.B D1,RECTRA *buffer y lo enviamos a la linea A

	ADD.L #1,D0	 *Incremento del contador de caracteres y del puntero
	ADD.L #1,A2	 *al buffer, decremento del param tamano.
	SUB.W #1,D2	 *.L para 4 bytes y .W para 2 bytes

	CMP.W #0,D2	 *Si D2 resulta ser 0, sigue. Si no, repetir.
	BNE BUCLE2

	RTS


BUS_ERROR:  BREAK * Bus error handler
            NOP
ADDRESS_ER: BREAK * Address error handler
            NOP
ILLEGAL_IN: BREAK * Illegal instruction handler
            NOP
PRIV_VIOLT: BREAK * Privilege violation handler
            NOP

