''********************************************
''*  Full-Duplex Serial Driver v1.2          *
''*  Author: Chip Gracey, Jeff Martin        *
''*  Copyright (c) 2006-2009 Parallax, Inc.  *
''*  See end of file for terms of use.       *
''********************************************

{

  -----------------REVISION HISTORY-----------------

   * cryto elements by Ryan Clarke (1o57)
   
   * minor updates by Jon McPhalen
   
   v1.2 - 5/7/2009 fixed bug in dec method causing largest negative value (-2,147,483,648) to be output as -0.
   v1.1 - 3/1/2006 first official release.
   
}


con

  BUF_SIZE = 64                                                 ' *JM* (must be power of 2)                                         
  BUF_LAST = BUF_SIZE-1                                         ' *JM*   


var

  long  cog                                                     ' cog flag/id

  long  rx_head                                                 ' 9 contiguous longs
  long  rx_tail
  long  tx_head
  long  tx_tail
  long  rx_pin
  long  tx_pin
  long  rxtx_mode
  long  bit_ticks
  long  buffer_ptr
                     
  byte  rx_buffer[BUF_SIZE]                                     ' *JM*
  byte  tx_buffer[BUF_SIZE]  

  byte  lost                                                    ' *1o57*
  

pub start(rxpin, txpin, mode, baudrate) : okay

'' Start serial driver - starts a cog
'' returns false if no cog available
''
'' mode bit 0 = invert rx
'' mode bit 1 = invert tx
'' mode bit 2 = open-drain/source tx
'' mode bit 3 = ignore tx echo on rx

  stop
  
  longfill(@rx_head, 0, 4)
  longmove(@rx_pin, @rxpin, 3)
  bit_ticks := clkfreq / baudrate
  buffer_ptr := @rx_buffer
  
  okay := cog := cognew(@fds, @rx_head) + 1


pub stop

'' Stop serial driver - frees a cog

  if (cog)
    cogstop(cog - 1)
    cog := 0


pub rxflush

'' Flush receive buffer

  repeat while (rxcheck => 0)
  
    
pub rxcheck : rxbyte

'' Check if byte received (never waits)
'' returns -1 if no byte received, $00..$FF if byte

  rxbyte := -1
  if (rx_tail <> rx_head)
    rxbyte := rx_buffer[rx_tail]
    rx_tail := (rx_tail + 1) & BUF_LAST                         ' *JM*


pub rxtime(ms) : rxbyte | t

'' Wait ms milliseconds for a byte to be received
'' returns -1 if no byte received, $00..$FF if byte

  t := cnt
  repeat until ((rxbyte := rxcheck) => 0) or ((cnt - t) / (clkfreq / 1000) > ms)


pub rxtix(tix) : rxbyte | t                                     ' *JM*

'' Waits tix clock ticks for a byte to be received
'' -- returns -1 if not byte rx'd

  t := cnt
  repeat until ((rxbyte := rxcheck) => 0) or ((cnt - t) > tix)
 

pub rx : rxbyte

'' Receive byte (may wait for byte)
'' returns $00..$FF

  repeat while ((rxbyte := rxcheck) < 0)


pub txflush

'' Wait for transmit buffer to empty, then wait for byte to transmit

  repeat until (tx_tail == tx_head)
  repeat 11                                                     ' start + 8 + 2
    waitcnt(bit_ticks + cnt)


pub tx(txbyte)

'' Send byte (may wait for room in buffer)

  repeat until (tx_tail <> (tx_head + 1) & BUF_LAST)            ' *JM*
  tx_buffer[tx_head] := txbyte
  tx_head := (tx_head + 1) & BUF_LAST                           ' *JM*

  if (rxtx_mode & %1000)
    rx


pub str(p_zstr)                                                

'' Send string                    

  repeat strsize(p_zstr)
    tx(byte[p_zstr++])


pub caesar(p_zstr) | c                                          ' *1o57*   

  lost := byte[p_zstr++]
  repeat strsize(p_zstr)
    c := byte[p_zstr++] 
    case c
      32    : tx(32)
      13    : tx(13)
      other : tx((((c-65)+26-lost)//26)+65)

      
pub exor(p_zstr)                                                ' *1o57*   

  lost := byte[p_zstr++]
  repeat strsize(p_zstr)
    tx(byte[p_zstr++]^lost)
    
    
pub otp(p_zstr1, p_zstr2)                                       ' *1o57*

  repeat until (byte[p_zstr1] == 0)
    if (byte[p_zstr1] == 32)
      tx(32)
      p_zstr1++
      
    elseif (byte[p_zstr1] == 13)
      tx(13)
      p_zstr1++
      
    elseif (byte[p_zstr2] == 32)
      p_zstr2++
      
    else
      tx((((byte[p_zstr1++]-65)+(byte[p_zstr2++]-65))//26)+65)


pub dec(value) | i, x

'' Print a decimal number

  x := value == negx                                            ' Check for max negative
  if value < 0                                                   
    value := ||(value+x)                                        ' If negative, make positive; adjust for max negative
    tx("-")                                                     ' and output sign
                                                                 
  i := 1_000_000_000                                            ' Initialize divisor
                                                                 
  repeat 10                                                     ' Loop for 10 digits
    if value => i                                                
      tx(value / i + "0" + x*(i == 1))                          ' If non-zero digit, output digit; adjust for max negative
      value //= i                                               ' and digit from value
      result~~                                                  ' flag non-zero found
    elseif result or (i == 1)                                    
      tx("0")                                                   ' If zero digit (or only digit) output it
    i /= 10                                                     ' Update divisor


pub rjdec(val, width, pchar) | tmpval, pad                      ' *DH/JM*

'' Print right-justified decimal value
'' -- val is value to print
'' -- width is width of (padded) field for value
'' -- pchar is [leading] pad character (usually "0" or " ")

'  Original code by Dave Hein
'  Added (with modifications) to FDS by Jon McPhalen

  if (val => 0)                                                 ' if positive
    tmpval := val                                               '  copy value
    pad := width - 1                                            '  make room for 1 digit
  else                                                           
    if (val == NEGX)                                            '  if max negative
      tmpval := POSX                                            '    use max positive for width
    else                                                        '  else
      tmpval := -val                                            '    make positive
    pad := width - 2                                            '  make room for sign and 1 digit
                                                                 
  repeat while (tmpval => 10)                                   ' adjust pad for value width > 1
    pad--                                                        
    tmpval /= 10                                                 
                                                                 
  repeat pad                                                    ' print pad
    tx(pchar)                                                    
                                                                 
  dec(val)                                                      ' print value

  
pub hex(value, digits)

'' Print a hexadecimal number

  value <<= (8 - digits) << 2
  repeat digits
    tx(lookupz((value <-= 4) & $F : "0".."9", "A".."F"))


pub bin(value, digits)

'' Print a binary number

  value <<= 32 - digits
  repeat digits
    tx((value <-= 1) & 1 + "0")


DAT

'***********************************
'* Assembly language serial driver *
'***********************************

                        org     0
'
'
' Entry
'
fds                     mov     t1, par                         ' get structure address
                        add     t1, #4 << 2                     ' skip past heads and tails

                        rdlong  t2, t1                          ' get rx_pin
                        mov     rxmask, #1
                        shl     rxmask, t2

                        add     t1, #4                          ' get tx_pin
                        rdlong  t2, t1
                        mov     txmask, #1
                        shl     txmask, t2

                        add     t1,#4                           ' get rxtx_mode
                        rdlong  rxtxmode, t1

                        add     t1,#4                           ' get bit_ticks
                        rdlong  bitticks, t1

                        add     t1, #4                          ' get buffer_ptr
                        rdlong  rxbuff, t1
                        mov     txbuff, rxbuff
                        add     txbuff, #BUF_SIZE               ' *JM* 

                        test    rxtxmode, #%100  wz             ' init tx pin according to mode
                        test    rxtxmode, #%010  wc
        if_z_ne_c       or      outa, txmask
        if_z            or      dira, txmask

                        mov     txcode, #transmit               ' initialize ping-pong multitasking


' =========
'  Receive
' =========
'
receive                 jmpret  rxcode, txcode                  ' run a chunk of transmit code, then return

                        test    rxtxmode, #%001  wz             ' wait for start bit on rx pin
                        test    rxmask, ina      wc
        if_z_eq_c       jmp     #receive

                        mov     rxbits, #9                      ' ready to receive byte
                        mov     rxcnt, bitticks
                        shr     rxcnt, #1
                        add     rxcnt, cnt                          

:bit                    add     rxcnt, bitticks                 ' ready next bit period

:wait                   jmpret  rxcode, txcode                  ' run a chuck of transmit code, then return

                        mov     t1, rxcnt                       ' check if bit receive period done
                        sub     t1, cnt
                        cmps    t1, #0                  wc
        if_nc           jmp     #:wait

                        test    rxmask, ina             wc      ' receive bit on rx pin
                        rcr     rxdata, #1
                        djnz    rxbits, #:bit
                                                                
                        shr     rxdata, #32-9                   ' justify and trim received byte
                        and     rxdata, #$FF
                        test    rxtxmode, #%001         wz      ' if rx inverted, invert byte
        if_nz           xor     rxdata, #$FF

                        rdlong  t2, par                         ' save received byte and inc head
                        add     t2, rxbuff
                        wrbyte  rxdata, t2
                        sub     t2, rxbuff
                        add     t2, #1
                        and     t2, #BUF_LAST                   ' *JM*
                        wrlong  t2, par
                                                                
                        jmp     #receive                        ' byte done, receive next byte
 

' ==========
'  Transmit
' ==========
'
transmit                jmpret  txcode, rxcode                  ' run a chunk of receive code, then return

                        mov     t1, par                         ' check for head <> tail
                        add     t1, #2 << 2
                        rdlong  t2, t1
                        add     t1, #1 << 2
                        rdlong  t3, t1
                        cmp     t2, t3                  wz
        if_z            jmp     #transmit

                        add     t3, txbuff                      ' get byte and inc tail
                        rdbyte  txdata, t3
                        sub     t3, txbuff
                        add     t3, #1
                        and     t3, #BUF_LAST                   ' *JM*
                        wrlong  t3, t1

                        or      txdata, #$100                   ' ready byte to transmit
                        shl     txdata, #2
                        or      txdata, #1
                        mov     txbits, #11
                        mov     txcnt, cnt

:bit                    test    rxtxmode, #%100         wz      ' output bit on tx pin according to mode
                        test    rxtxmode, #%010         wc
        if_z_and_c      xor     txdata, #1
                        shr     txdata, #1              wc
        if_z            muxc    outa, txmask        
        if_nz           muxnc   dira, txmask                     
                        add     txcnt, bitticks                 ' ready next cnt

:wait                   jmpret  txcode, rxcode                  ' run a chunk of receive code, then return

                        mov     t1, txcnt                       ' check if bit transmit period done
                        sub     t1, cnt
                        cmps    t1, #0                  wc
        if_nc           jmp     #:wait

                        djnz    txbits, #:bit                   ' another bit to transmit?

                        jmp     #transmit                       ' byte done, transmit next byte


' --------------------------------------------------------------------------------------------------

' Uninitialized data
'
t1                      res     1
t2                      res     1
t3                      res     1

rxtxmode                res     1
bitticks                res     1

rxmask                  res     1
rxbuff                  res     1
rxdata                  res     1
rxbits                  res     1
rxcnt                   res     1
rxcode                  res     1

txmask                  res     1
txbuff                  res     1
txdata                  res     1
txbits                  res     1
txcnt                   res     1
txcode                  res     1

{{

┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │                                                            
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │ 
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}
