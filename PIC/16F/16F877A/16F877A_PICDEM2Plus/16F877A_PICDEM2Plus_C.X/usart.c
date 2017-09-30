/*
 * file: usart.c
 * target: PIC16F877A
 *
 */
#include "init.h"
#include "usart.h"

volatile unsigned char OERRcounter;
volatile unsigned char FERRcounter;

/* UART routines */
void USART_Init(USART_BAUD baudselect, USART_CONFIG conf, USART_MODE mode, USART_9TH_BIT nineth_bit)
{
    /*Clear error counts */
    OERRcounter = 0;    
    FERRcounter = 0;
    
    /* Disable UART interrupts */
    PIE1bits.TXIE = 0;
    PIE1bits.RCIE = 0;

    /* Turn off USART module */
    RCSTA = 0; 
    TXSTA = 0;
    
    //UARTCKPIN = 1; /* Configure USART GPIO pins  */
    //UARTDTPIN = 1; /* as required in datasheet. */
    RCSTAbits.RX9 = (nineth_bit!=USART_9TH_BIT_OFF) ? 1 : 0;
    RCSTAbits.ADDEN = 0;
    TXSTAbits.TX9 = (nineth_bit!=USART_9TH_BIT_OFF) ? 1 : 0;
    
    switch (baudselect)
    {
        case USART_BAUD_MAXIMUM:
            SPBRG = SPBRG_AT_MAXIMUM;
            TXSTAbits.BRGH = 1; /* Setting high speed */
            break;
        case USART_BAUD_38400:
            SPBRG = SPBRG_AT_38400;
            TXSTAbits.BRGH = BRGH_AT_38400;
            break;
        case USART_BAUD_19200:
            SPBRG = SPBRG_AT_19200;
            TXSTAbits.BRGH = BRGH_AT_19200;
            break;
        case USART_BAUD_9600:
            SPBRG = SPBRG_AT_9600;
            TXSTAbits.BRGH = BRGH_AT_9600;
            break;
        case USART_BAUD_4800:
            SPBRG = SPBRG_AT_4800;
            TXSTAbits.BRGH = BRGH_AT_4800;
            break;
        case USART_BAUD_2400:
            SPBRG = SPBRG_AT_2400;
            TXSTAbits.BRGH = BRGH_AT_2400;
            break;
        default:
            /* default is the slowest baud rate */
            SPBRG = 0xFF;
            TXSTAbits.BRGH = 0;
            break;
    }
    
    switch (mode) 
    {
        case USART_ASYNC:
            TXSTAbits.SYNC = 0; /* Setting Asynchronous Mode, ie UART */
            break;
        case USART_SYNC_MASTER:
            TXSTAbits.CSRC = 1; /* Setting internal clock generated by BRG */
            TXSTAbits.SYNC = 1; /* Setting Synchronous Mode, ie UART */
            TXSTAbits.BRGH = 0;
            break;
        case USART_SYNC_SLAVE:
            TXSTAbits.CSRC = 0; /* Setting internal clock generated by master (slave mode) */
            TXSTAbits.SYNC = 1; /* Setting Synchronous Mode, ie UART  */
            TXSTAbits.BRGH = 0;
            break;
    }
    
    switch (conf) 
    {
        case USART_READ:
            RCSTAbits.CREN = 1; /* Enable continuous receive  */
            break;
        case USART_WRITE:
            TXSTAbits.TXEN = 1; /* Enables Transmission */
            break;
        case USART_READ_AND_WRITE:
            RCSTAbits.CREN = 1; /* Enable continuous receive  */
            TXSTAbits.TXEN = 1; /* Enables Transmission */
            break;
    } 
    RCSTAbits.SPEN = 1; /* Enables Serial Port */
    /*
     * Flush UART receive buffer
     */
    RCREG;
    RCREG;
    RCREG;
}
    
unsigned char USART_TX_Empty( void ) {
  return (TRMT!=0?1:0);
}
    
void USART_Write(unsigned char data) {
  while(!TRMT); /* Wait for buffer to be empty */
  TXREG = data;
}
    
void USART_WriteConstString(const unsigned char *pBuffer) {
    if (pBuffer)
    {
        while(*pBuffer)
        {
            USART_Write(*pBuffer++);
        }
    }
}
    
void USART_WriteString(unsigned char *pBuffer) {
    if (pBuffer)
    {
        while(*pBuffer)
        {
            USART_Write(*pBuffer++);
        }
    }
}
    
unsigned char USART_Data_Ready( void )
{
  return (RCIF!=0?1:0);
}
    
unsigned char USART_Read(unsigned char *buffer)
{ 
    unsigned char Result;
    
    Result = 0;
    
    if (PIR1bits.RCIF) 
    {
        unsigned char rxerr = 0;
        
        if (RCSTAbits.OERR) {
            rxerr = 1;
            RCSTAbits.CREN = 0; /* reset receiver */
            RCSTAbits.CREN = 1;
            RCREG;
            RCREG;
            RCREG;
            if(OERRcounter < 255) OERRcounter++;
        }
        
        if (RCSTAbits.FERR) {
            rxerr = 1;
            RCREG; /* Discard character with framing error */
            if(FERRcounter < 255) FERRcounter++;
        } 
        
        if (!rxerr) { /* No error detected during reception */
            *buffer = RCREG;
            Result = 1;
        }
    }
    
    return Result;
}
