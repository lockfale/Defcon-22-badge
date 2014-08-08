'' =================================================================================================
''
''   File....... jm_sircs_tx.spin
''   Purpose.... SIRCS-compatible transmitter
''               -- works with active-high and active-low connections
''   Author..... Jon "JonnyMac" McPhalen
''               Copyright (c) 2009-13 Jon McPhalen
''               -- see below for terms of use
''   E-mail..... jon@jonmcphalen.com
''   Started.... 
''   Updated.... 01 MAY 2013
''
'' =================================================================================================

{{

    Typical connections:

              IR
      3.3v ──────┐
                    │
    ir pin ──────┘
               33



    Parallax QuickStart HID Board uses active-high output to IR LED 

          33  IR
    P9 ───────┐
                   
                    

    Protocol Reference:
    -- http://www.sbprojects.com/knowledge/ir/sirc.php
              
}}


var

  long  cog                                                     ' cog id

  long  irframes                                                ' frames ( > 0 is flag to tx )     
  long  ircode                                                  ' code
  long  irbits                                                  ' bits in ir code
  long  irstart                                                 ' ticks in start bit


pub start(pin, hz)

'' Starts SIRCS cog with 45ms frame timing (SIRCS standard)

  return startx(pin, hz, 45)

  
pub startx(pin, hz, framems)

'' Starts SIRCS cog with user-defined frame timing
'' -- pin is modulation output
'' -- hz is modulation frequency (e.g., 40_000)
'' -- framems is frame timing in milliseconds
''    * warning: will truncate transmission if too short
''    * minimum 6ms + (bits * 1.8ms)

  stop                                                          ' stop if running
   
  irframes := pin
  ircode   := ($8000_0000 / (clkfreq / hz)) << 1                ' setup for ctrx NCO mode
  irbits   := clkfreq / 1_000 * (10 #> framems <# 100)          ' frame timing
  irstart  := clkfreq / 1_000_000 * 2_400                       ' ticks in 2.4ms
   
  cog := cognew(@txsircs, @irframes) + 1                        ' start cog

  return cog


pub stop

'' Stops IR cog if running

  if (cog)
    cogstop(cog - 1)
    cog := 0

  longfill(@irframes, 0, 4)                                     ' clear parameters
    

pub tx(code, bits, frames)

'' Transmits SIRCS code
'' -- code is the code to transmit
'' -- bits is the bit count to transmit  (usually 12 or 20)
'' -- frames is the number of transmitted frames (typically 3 to 5)

  if ((bits > 0) and (frames > 0)) 
    ircode   := code
    irbits   := 1 #> bits <# 32                                ' limit bits
    irframes := 1 #> frames <# 5                               ' limit frames  


pub busy

'' Reports returns true while code is transmitting

  return (irframes > 0)


dat

                        org     0

txsircs                 mov     t1, par                         ' start of parameters
                        rdlong  txpin, t1                       ' read tx pin
                        mov     txmask, #1                      ' create pin control mask
                        shl     txmask, txpin
                        andn    dira, txmask                    ' disable modulation  

                        add     t1, #4                          ' get mod frequency
                        rdlong  frqa, t1                        ' setup ctra for txpin
                        movs    ctra, txpin
                        movi    ctra, NCO_SE

                        add     t1, #4
                        rdlong  frametix, t1                    ' read ticks in 45ms frame

                        add     t1, #4
                        rdlong  starttix, t1                    ' read ticks in start bit (2.4ms)

                        mov     bit1tix, starttix               ' calc ticks in "1" bit (1.2ms)
                        shr     bit1tix, #1

                        mov     bit0tix, starttix               ' calc ticks in "0" bit (0.6ms)
                        shr     bit0tix, #2

                        wrlong  ZERO, par                       ' clear frame count

                        
waitcmd                 mov     t1, par                         ' address of parameters
                        rdlong  txframes, t1            wz      ' get frame count
        if_z            jmp     #waitcmd                        ' wait for non-zero

                        add     t1, #4
                        rdlong  txcode, t1                      ' read code to tx

                        add     t1, #4
                        rdlong  txbits, t1                      ' read bits to tx

startframe              mov     frametimer, frametix            ' start the frame timer
                        add     frametimer, cnt

txstart                 mov     bittimer, starttix              ' load start bit timing
                        call    #txbit                          ' do it

                        mov     outcode, txcode                 ' copy code  
                        mov     outbits, txbits                 ' copy bit count

txir                    rcr     outcode, #1             wc      ' get lsb --> C
        if_c            mov     bittimer, bit1tix               
        if_nc           mov     bittimer, bit0tix
                        call    #txbit
                        djnz    outbits, #txir                  ' all bits tx'd?

                        waitcnt frametimer, frametix            ' let frame timer expire
                        djnz    txframes, #txstart              ' start next frame

                        wrlong  ZERO, par                       ' alert hub
                        jmp     #waitcmd

                        
' load bittimer with ticks before calling                     
                                           
txbit                   add     bittimer, cnt                   ' sync with system coutner
                        or      dira, txmask                    ' enable modulation
                        waitcnt bittimer, bit0tix               ' wait, then load bit pad (0)
                        andn    dira, txmask                    ' disable modulation 
                        waitcnt bittimer, #0                    ' let pad timing expire
txbit_ret               ret   

' --------------------------------------------------------------------------------------------------

ZERO                    long    0
NCO_SE                  long    %00100_000                      ' counter NCO mode (for movi)

txpin                   res     1                               ' ir tx pin (cathode)
txmask                  res     1                               ' mask for tx pin
frametix                res     1                               ' ticks in 45ms frame
starttix                res     1                               ' ticks in 2.4ms start bit
bit1tix                 res     1                               ' ticks in 1.2ms "1" bit
bit0tix                 res     1                               ' ticks in 0.6ms "0" bit

txframes                res     1                               ' command parameters
txcode                  res     1
txbits                  res     1

frametimer              res     1                               ' timers
bittimer                res     1

outcode                 res     1                               ' working copy of code
outbits                 res     1                               ' bits in code

t1                      res     1                               ' work vars
t2                      res     1

                        fit     496
                        

dat

{{

  Terms of Use: MIT License

  Permission is hereby granted, free of charge, to any person obtaining a copy of this
  software and associated documentation files (the "Software"), to deal in the Software
  without restriction, including without limitation the rights to use, copy, modify,
  merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
  permit persons to whom the Software is furnished to do so, subject to the following
  conditions:

  The above copyright notice and this permission notice shall be included in all copies
  or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
  INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
  PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
  CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
  OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

}}             
