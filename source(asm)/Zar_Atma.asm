;************************************************************************
;	Program Ad� 	: Zar_Atma.asm										*
;	Program�n amac� : Bu program elektronik zar olarak �al��maktad�r.	*
;	Yazan			: Erhan YILMAZ										*
;	Tarih			: 10-12-2011									  	*
;	S�r�m			: 1.0											  	*
;	Boyut			: 203 Byte											*
;************************************************************************

									
SHIFT_DATA 			EQU 	0X20			; Seri veri yoluna g�nderilecek veriyi tutan yazma�
CHIP_SELECT			EQU 	0X21.0			; G�sterge(74HC595) Se�me biti
RASGELE_SAYI 		EQU 	0X30			; Rasgele say� de�i�keni
ANIMASYON_SAYAC		EQU		0X30			; Animasyon program� sayac�
ZAR_BUTON			EQU 	P1.0			; Zar atma butonu
SCK					EQU		P2.0			; 74HC595 Saat sinyali ��k�� pini
SDO					EQU		P2.1   			; 74HC595 Seri veri ��k�� pini
CS1					EQU		P2.2			; G�sterge 1 se�me pini
CS2					EQU		P2.3			; G�sterge 2 se�me pini	


			ORG 0000H					  	;RESET vekt�r� adresi
			AJMP BASLA						;BASLA etiketine git

			ORG 0100H
;7 par�a g�sterge veri tablosu
;	   a
;	 -----
;	|	  | b
; f	|  g  |
;	 -----
; e |	  | c
;	|	  |
;	 ----- . dp
;	   d
;				   .gfedcba			
; Segment Data = 0bxxxxxxxx
; 7 par�a g�stergelere g�nderilecek olan de�erler program haf�zadan sabit olarak okunarak g�stegelere g�nderilir.
SEGMENT_TABLO:     	DB      0X3F,0X06,0X5B,0X4F,0X66,0X6D,0X7D,0X07,0X7F,0X6F,0X77,0X7C,0X39,0X5E,0X79,0X71
ANIMASYON_TABLO:	DB		0X01,0X02,0X04,0X08,0X10,0X20


BASLA:
			CLR 	A							; Ak�m�lat�r� temizle
			MOV 	P2,A						; Port2'yi temizle
			MOV 	ANIMASYON_SAYAC,#0X00		; Animasyon sayac�n� s�f�rla	
			MOV		TH0,#0X01					; Timer0 reload de�erini y�kle
			MOV		TL0,#0X01					; Timer0 ilk de�erini y�kle
			MOV		TMOD,#0XF2					; Timer0 8 bit tekrar y�klemeli(0x01) olarak �al��t�r�l�r.
			SETB	TCON.4						; Timer0 �al��t�r�l�r.
			CLR		CHIP_SELECT					; Ba�lang��ta G�sterge 1 temizlenir.
			MOV		SHIFT_DATA,#0x00
			ACALL	SHIFT_SEND_BYTE	
			SETB	CHIP_SELECT				  	; Ba�lang��ta G�sterge 2 temizlenir.
			MOV		SHIFT_DATA,#0x00
			ACALL	SHIFT_SEND_BYTE			

LOOP:				   	
			JB 		ZAR_BUTON,LOOP			  	; Butona bas�lana kadar bekle
			ACALL 	GECIKME						; Buton ark�n� �nlemek i�in bi s�re beklenir.
KAL:
			JB		ZAR_BUTON,ATLA				; Buton b�rak�lana kadar animasyon program�n� �al��t�r.
			ACALL	ANIMASYON
			AJMP 	KAL
ATLA:
			ACALL	ZAR_AT				   		; Birinci zar de�erini �ret
			CLR		CHIP_SELECT			   		; G�sterge0'i se�
			ACALL	SEGMENT_GOSTER		   		; Zar de�erini G�sterge0'de g�ster
			ACALL	ZAR_AT						; �kinci zar de�erini �ret
			SETB	CHIP_SELECT					; G�sterge1'i se�
			ACALL	SEGMENT_GOSTER				; Zar de�erini G�sterge1'de g�ster
			AJMP	LOOP				   		; Sonsuz d�ng�

;	Bu alt program 1-6 aras�nda rasgele say� �retir sonucu Ak�m�lat�re yazar.
ZAR_AT:					
			MOV	 	RASGELE_SAYI,TL0			; Rasgele say� �reteci i�in Timer0'dan ba�lang�� de�eri al
TEKRAR_URET:
			ACALL	RASGELE_SAYI_URET	   		; Rasgele say� �ret
			MOV		A,RASGELE_SAYI
			ANL		A,#0X0F
			CJNE	A,#0X00,SIFIR_DEGIL    		; �retilen rasgele say�n�n alt 4 bitinin s�f�r olup olmad���n� test et.
 			SJMP	TEKRAR_URET			   		; S�f�rsa ba�ka say� �ret.
SIFIR_DEGIL:
			CLR C						    
			SUBB	A,#0X07				   
			JC		BITIR						; �retilen say�n�n alt 4 bitinin 6'dan b�y�k olup olmad���n� test et.
			LJMP 	TEKRAR_URET			   		; B�y�kse ba�ka say� �ret.
BITIR:		
			MOV		A,RASGELE_SAYI
			RET


;	Bu alt program	(A) Ak�m�lat�rdeki de�erin alt 4 bitini (0-F) g�stergelere
;	g�nderir. CHIP_SELECT bayra�� set edilmi�se veri g�sterge1'e edilmemi�se g�sterge0'a gider
SEGMENT_GOSTER:
			ANL		A,#0X0F
			MOV     DPTR,#SEGMENT_TABLO    
           	MOVC    A,@A+DPTR         
			MOV		SHIFT_DATA,A
			ACALL	SHIFT_SEND_BYTE
			RET
;	Bu alt program	SHIFT_DATA yazmac�ndaki 8 bit veriyi seri veri yolu �zerinden 74HC595 �iplerine g�nderir. 
SHIFT_SEND_BYTE:
			MOV 	R0,#0X08					;Sayac de�eri olarak 8 y�kle
GONDER:
			SETB 	SDO							; Seri veri hatt�n� set et
			JB		SHIFT_DATA.7,A1				; SHIFT_DATA.7 bitini kontrol et
			CLR		SDO							; S�f�r ise seri veri hatt�n� s�f�ra �ek
A1:			SETB 	SCK							; Saat sinyalini olu�tur.
			CLR  	SCK
			MOV		A,SHIFT_DATA				; Di�er biti g�ndermek i�in 1 bit sola �tele.
			RL		A
			MOV		SHIFT_DATA,A				; 8 bit yollanana kadar devam et.
			DJNZ 	R0,GONDER
			JB		CHIP_SELECT,A2				; G�sterge 1 se�iliyse
			SETB	CS1							; 1. 74HC595 latch edilir.
			CLR		CS1
A2:
			JNB		CHIP_SELECT,A3				; G�sterge 2 se�iliyse
			SETB	CS2							; 2. 74HC595 latch edilir.
			CLR		CS2
A3:
			RET

;	Bu alt program LFSR(Lineer Feedback Shift Register) temelli 8bit rasgele say� �retir.(al�nt�d�r.)
RASGELE_SAYI_URET:
			CLR 	C
			MOV		A,RASGELE_SAYI
			RRC		A
			JNC		SON1
			XRL		A,#0XB4
SON1:
			MOV		RASGELE_SAYI,A
			RET
;	Bu alt program g�stergelerde y�r�yen segment efekti yapar.
ANIMASYON:
			MOV     DPTR,#ANIMASYON_TABLO 
			MOV		A,ANIMASYON_SAYAC   
           	MOVC    A,@A+DPTR
			CLR		CHIP_SELECT
			MOV		SHIFT_DATA,A
			ACALL	SHIFT_SEND_BYTE
			SETB	CHIP_SELECT
			MOV		SHIFT_DATA,A
			ACALL	SHIFT_SEND_BYTE
			ACALL	GECIKME
			INC		ANIMASYON_SAYAC
			MOV		A,ANIMASYON_SAYAC
			CLR		C
			SUBB	A,#0x06
			JC		SON2
			CLR		A
			MOV		ANIMASYON_SAYAC,A
SON2:
			RET

;	Bu alt program gecikme sa�lamak i�in kullan�l�r. (al�nt�d�r)
GECIKME:	
			MOV 	R1,#0X04
			MOV 	R2,#0X80	
BEKLE:				
			DJNZ 	R1,BEKLE
			DJNZ 	R2,BEKLE
			RET

END
