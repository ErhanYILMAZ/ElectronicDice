;************************************************************************
;	Program Adý 	: Zar_Atma.asm										*
;	Programýn amacý : Bu program elektronik zar olarak çalýþmaktadýr.	*
;	Yazan			: Erhan YILMAZ										*
;	Tarih			: 10-12-2011									  	*
;	Sürüm			: 1.0											  	*
;	Boyut			: 203 Byte											*
;************************************************************************

									
SHIFT_DATA 			EQU 	0X20			; Seri veri yoluna gönderilecek veriyi tutan yazmaç
CHIP_SELECT			EQU 	0X21.0			; Gösterge(74HC595) Seçme biti
RASGELE_SAYI 		EQU 	0X30			; Rasgele sayý deðiþkeni
ANIMASYON_SAYAC		EQU		0X30			; Animasyon programý sayacý
ZAR_BUTON			EQU 	P1.0			; Zar atma butonu
SCK					EQU		P2.0			; 74HC595 Saat sinyali çýkýþ pini
SDO					EQU		P2.1   			; 74HC595 Seri veri çýkýþ pini
CS1					EQU		P2.2			; Gösterge 1 seçme pini
CS2					EQU		P2.3			; Gösterge 2 seçme pini	


			ORG 0000H					  	;RESET vektörü adresi
			AJMP BASLA						;BASLA etiketine git

			ORG 0100H
;7 parça gösterge veri tablosu
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
; 7 parça göstergelere gönderilecek olan deðerler program hafýzadan sabit olarak okunarak göstegelere gönderilir.
SEGMENT_TABLO:     	DB      0X3F,0X06,0X5B,0X4F,0X66,0X6D,0X7D,0X07,0X7F,0X6F,0X77,0X7C,0X39,0X5E,0X79,0X71
ANIMASYON_TABLO:	DB		0X01,0X02,0X04,0X08,0X10,0X20


BASLA:
			CLR 	A							; Akümülatörü temizle
			MOV 	P2,A						; Port2'yi temizle
			MOV 	ANIMASYON_SAYAC,#0X00		; Animasyon sayacýný sýfýrla	
			MOV		TH0,#0X01					; Timer0 reload deðerini yükle
			MOV		TL0,#0X01					; Timer0 ilk deðerini yükle
			MOV		TMOD,#0XF2					; Timer0 8 bit tekrar yüklemeli(0x01) olarak çalýþtýrýlýr.
			SETB	TCON.4						; Timer0 çalýþtýrýlýr.
			CLR		CHIP_SELECT					; Baþlangýçta Gösterge 1 temizlenir.
			MOV		SHIFT_DATA,#0x00
			ACALL	SHIFT_SEND_BYTE	
			SETB	CHIP_SELECT				  	; Baþlangýçta Gösterge 2 temizlenir.
			MOV		SHIFT_DATA,#0x00
			ACALL	SHIFT_SEND_BYTE			

LOOP:				   	
			JB 		ZAR_BUTON,LOOP			  	; Butona basýlana kadar bekle
			ACALL 	GECIKME						; Buton arkýný önlemek için bi süre beklenir.
KAL:
			JB		ZAR_BUTON,ATLA				; Buton býrakýlana kadar animasyon programýný çalýþtýr.
			ACALL	ANIMASYON
			AJMP 	KAL
ATLA:
			ACALL	ZAR_AT				   		; Birinci zar deðerini üret
			CLR		CHIP_SELECT			   		; Gösterge0'i seç
			ACALL	SEGMENT_GOSTER		   		; Zar deðerini Gösterge0'de göster
			ACALL	ZAR_AT						; Ýkinci zar deðerini üret
			SETB	CHIP_SELECT					; Gösterge1'i seç
			ACALL	SEGMENT_GOSTER				; Zar deðerini Gösterge1'de göster
			AJMP	LOOP				   		; Sonsuz döngü

;	Bu alt program 1-6 arasýnda rasgele sayý üretir sonucu Akümülatöre yazar.
ZAR_AT:					
			MOV	 	RASGELE_SAYI,TL0			; Rasgele sayý üreteci için Timer0'dan baþlangýç deðeri al
TEKRAR_URET:
			ACALL	RASGELE_SAYI_URET	   		; Rasgele sayý üret
			MOV		A,RASGELE_SAYI
			ANL		A,#0X0F
			CJNE	A,#0X00,SIFIR_DEGIL    		; Üretilen rasgele sayýnýn alt 4 bitinin sýfýr olup olmadýðýný test et.
 			SJMP	TEKRAR_URET			   		; Sýfýrsa baþka sayý üret.
SIFIR_DEGIL:
			CLR C						    
			SUBB	A,#0X07				   
			JC		BITIR						; Üretilen sayýnýn alt 4 bitinin 6'dan büyük olup olmadýðýný test et.
			LJMP 	TEKRAR_URET			   		; Büyükse baþka sayý üret.
BITIR:		
			MOV		A,RASGELE_SAYI
			RET


;	Bu alt program	(A) Akümülatördeki deðerin alt 4 bitini (0-F) göstergelere
;	gönderir. CHIP_SELECT bayraðý set edilmiþse veri gösterge1'e edilmemiþse gösterge0'a gider
SEGMENT_GOSTER:
			ANL		A,#0X0F
			MOV     DPTR,#SEGMENT_TABLO    
           	MOVC    A,@A+DPTR         
			MOV		SHIFT_DATA,A
			ACALL	SHIFT_SEND_BYTE
			RET
;	Bu alt program	SHIFT_DATA yazmacýndaki 8 bit veriyi seri veri yolu üzerinden 74HC595 çiplerine gönderir. 
SHIFT_SEND_BYTE:
			MOV 	R0,#0X08					;Sayac deðeri olarak 8 yükle
GONDER:
			SETB 	SDO							; Seri veri hattýný set et
			JB		SHIFT_DATA.7,A1				; SHIFT_DATA.7 bitini kontrol et
			CLR		SDO							; Sýfýr ise seri veri hattýný sýfýra çek
A1:			SETB 	SCK							; Saat sinyalini oluþtur.
			CLR  	SCK
			MOV		A,SHIFT_DATA				; Diðer biti göndermek için 1 bit sola ötele.
			RL		A
			MOV		SHIFT_DATA,A				; 8 bit yollanana kadar devam et.
			DJNZ 	R0,GONDER
			JB		CHIP_SELECT,A2				; Gösterge 1 seçiliyse
			SETB	CS1							; 1. 74HC595 latch edilir.
			CLR		CS1
A2:
			JNB		CHIP_SELECT,A3				; Gösterge 2 seçiliyse
			SETB	CS2							; 2. 74HC595 latch edilir.
			CLR		CS2
A3:
			RET

;	Bu alt program LFSR(Lineer Feedback Shift Register) temelli 8bit rasgele sayý üretir.(alýntýdýr.)
RASGELE_SAYI_URET:
			CLR 	C
			MOV		A,RASGELE_SAYI
			RRC		A
			JNC		SON1
			XRL		A,#0XB4
SON1:
			MOV		RASGELE_SAYI,A
			RET
;	Bu alt program göstergelerde yürüyen segment efekti yapar.
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

;	Bu alt program gecikme saðlamak için kullanýlýr. (alýntýdýr)
GECIKME:	
			MOV 	R1,#0X04
			MOV 	R2,#0X80	
BEKLE:				
			DJNZ 	R1,BEKLE
			DJNZ 	R2,BEKLE
			RET

END
