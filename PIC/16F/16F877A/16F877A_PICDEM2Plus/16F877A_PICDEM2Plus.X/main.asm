; 
; File: main.asm
; Target: PIC16F877A
; IDE: MPLABX v3.35
; Compiler: MPASMWIN v5.58
;
; -------------------------
; Main application
; -------------------------
#define MAIN_ASM
#include "main.inc"
#include "lcd.inc"
#include "buttons.inc"
;
;                         PIC16F877A
;                 +----------:_:----------+
;   S1  VPP ->  1 : MCLR/VPP      PGD/RB7 : 40 <> PGD
; R16(0-5V) ->  2 : RA0/AN0       PGC/RB6 : 39 <> PGC
;           <>  3 : RA1               RB5 : 38 <>
;           <>  4 : RA2               RB4 : 37 <>
;           <>  5 : RA3           PGM/RB3 : 36 <> LED_D5
;   S2      ->  6 : RA4               RB2 : 35 <> LED_D4
;   S3      ->  7 : RA5               RB1 : 34 <> LED_D3
;           <>  8 : RE0               RB0 : 33 <> LED_D2
;           <>  9 : RE1               VDD : 32 <- PWR
;           <> 10 : RE2               VSS : 31 <- GND
;       PWR -> 11 : VDD               RD7 : 30 -> LCD_ON
;       GND -> 12 : VSS               RD6 : 29 -> LCD_E
;      4MHZ -> 13 : OSC1              RD5 : 28 -> LCD_RW
;           <- 14 : OSC2              RD4 : 27 -> LCD_RS
;           <> 15 : RC0/SOSCO   RX/DT/RC7 : 26 <- RXD
;           <> 16 : RC1/SOSCI   TX/CK/RC6 : 25 -> TXD
;    BUZZER <> 17 : RC2               RC5 : 24 <>
;       SCL <> 18 : RC3/SCL       SDA/RC4 : 23 <> SDA
;    LCD_D4 <> 19 : RD0               RD3 : 22 <> LCD_D7
;    LCD_D5 <> 20 : RD1               RD2 : 21 <> LCD_D6
;                 +-----------------------:
;                          DIP-40
;
;   PICDEM 2 Plus:
;   RD0 <> LCD_D4    Special note that the LCD module on my PICDEM2 PLUS
;   RD1 <> LCD_D5    is a NOVATEK 7605. In 4-bit mode the NOVATEK 7605 is 
;   RD2 <> LCD_D6    not 100% compatible with the Hitachi HD44780. The 
;   RD3 <> LCD_D7    issue is that in 4-bit mode a status read returns the 
;   RD4 -> LCD_RS    4-bits in an order that is different from the HD44780.
;   RD5 -> LCD_R/W   
;   RD6 -> LCD_E   
;   RD7 -> LCD_ON  
;
;------------------------------------------------------------------------
;
;
;
MAIN_DATA udata
lcdTestCount    	res 1


MAIN_CODE code
; 
; This is the LCD test application.
;
; First open the LCD with a 4-bit 
; interface 5x7 character size
; and more than one line.
;
main:
    movlw   (FOUR_BIT&LINES_5X7)
    lcall   OpenXLCD
    lcall   ButtonInit

    lgoto   lcdTest

;
; LCD test
;
; Start by sending two lines to the LCD:
;   Line1: LCD test Ver 1.0
;   Line2:                 
;
; Then wait for a key event then display
; the LCD character set 16 characters at
; a time for each key event.
;
lcdTest:
    movlw   LINE_ONE
    lcall   SetDDRamAddr

    movlw   LOW(LCD_message4)
    movwf   pszLCD_RomStr
    movlw   HIGH(LCD_message4)
    movwf   pszLCD_RomStr+1
    lcall   putrsXLCD
;
; Blank second line of LCD
;
lcdTestRestart:
    movlw   LINE_TWO
    lcall   SetDDRamAddr

    movlw   LOW(LCD_message_BlankLine)
    movwf   pszLCD_RomStr
    movlw   HIGH(LCD_message_BlankLine)
    movwf   pszLCD_RomStr+1
    lcall   putrsXLCD

    banksel lcdTestCount
    clrf    lcdTestCount
;
; Wait for key event.
;
; Display 16 character on LCD line 2.
;
lcdTestLoop:
    lcall   ButtonGetStatus
    pagesel lcdTestLoop
    skpnz
    goto    lcdTestContinue
    xorlw   BUTTON_S2_CHANGE_MASK | BUTTON_S2_STATE_MASK
    skpz
    goto    lcdTestContinue

    movlw   LINE_ONE
    lcall   SetDDRamAddr

    movlw   LOW(LCD_message5)
    movwf   pszLCD_RomStr
    movlw   HIGH(LCD_message5)
    movwf   pszLCD_RomStr+1
    lcall   putrsXLCD

    movlw   LINE_ONE+D'14'
    lcall   SetDDRamAddr
    banksel lcdTestCount
    movf    lcdTestCount,W
    lcall   PutHexXLCD

    movlw   LINE_TWO
    lcall   SetDDRamAddr
lcdTestWriteLoop:
    banksel lcdTestCount
    movf    lcdTestCount,W
    lcall   WriteDataXLCD
    pagesel lcdTestLoop

    banksel lcdTestCount
    incf    lcdTestCount,F
    movf    lcdTestCount,W
    andlw   0x0F
    skpz
    goto    lcdTestWriteLoop
lcdTestContinue:
    btfss   INTCON,T0IF
    goto    lcdTestLoop
    bcf     INTCON,T0IF
    lcall   ButtonPoll
    lgoto   lcdTestLoop

;
; LCD messages
;
MAIN_CONST   code
LCD_message_BlankLine:
    dt  "                ",0
LCD_message4:
    dt  "LCD test Ver 1.0",0
LCD_message5:
    dt  "Character row   ",0
    END
