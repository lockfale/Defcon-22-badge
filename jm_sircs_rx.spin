'' =================================================================================================
''
''   File....... jm_sircs_rx.spin
''   Purpose.... SIRCS-compatible IR receiver
''   Author..... Jon "JonnyMac" McPhalen
''               Copyright (c) 2009-2014 Jon McPhalen  
''               -- see below for terms of use
''   E-mail..... jon@jonmcphalen.com
''   Started.... 
''   Updated.... 08 JUL 2014
''
'' =================================================================================================

{{

    Example IR Connection (PNA4602M)
 
            ┌───┐
            │(*)│ 5v
            └┬┬┬┘ 
       ir ──┘│└──┘
              

    Protocol Reference:
    -- http://www.sbprojects.com/knowledge/ir/sirc.php
             
}}         


var

  long  cog                                                     ' cog id

  long  ircode                                                  ' rx'd code
  long  irbits                                                  ' bits in code


pub start(p) 

'' Start SIRCS receiver on pin p

  stop

  ircode := p                                                   ' set pin
  irbits := clkfreq / 1_000_000 * 2_160                         ' 90% of 2.4ms
    
  cog := cognew(@rxsircs, @ircode) + 1                          ' start cog
        
  repeat
  until (irbits < 0)                                            ' wait for cog to initialize
  
  return cog
  

pub stop

'' Stops SIRCS receiver cog if running

  if (cog)
    cogstop(cog - 1)
    cog := 0

  disable
    

pub enable

'' Enables SIRCS receive process

  longfill(@ircode, 0, 2)


pub disable

'' Disable SIRCS receive process

  longfill(@ircode, -1, 2) 

     
pub rx

'' Enables and waits for ir input
'' -- warning: blocks until IR code received!
'' -- does not remove code/bits from buffer

  enable                                                        ' allow ir rx
  repeat until (irbits > 0)                                     ' wait for code

  return ircode 


pub rxcheck

'' Returns code if available, -1 if none
'' -- must have previously been enabled
'' -- does not remove code/bits from buffer

  if (irbits > 0)                                               ' if code ready
    return ircode
  else
    return -1  

 
pub bit_count

'' Returns bit count of last ir code
'' -- check status before using
'' -- if 0, no code is available or disabled

  if (irbits > 0)
    return irbits
  else
    return 0

    
dat

                        org     0

rxsircs                 mov     t1, par                         ' start of parameters
                        rdlong  t2, t1                          ' read rx pin
                        mov     rxmask, #1                      ' convert to mask
                        shl     rxmask, t2

                        mov     ctra, NEG_DETECT                ' ctra measures bit width
                        or      ctra, t2                        '  of rx pin
                        mov     frqa, #1
                                                
                        mov     ctrb, POS_DETECT                ' ctrb measures idle state
                        or      ctrb, t2                        '  of rx pin
                        mov     frqb, #1

                        add     t1, #4                           
                        rdlong  starttix, t1                    ' read ticks in start bit
                                                                 
                        mov     bittix, starttix                 
                        shr     bittix, #1                      ' '1' bit is 1/2 start bit

                        neg     t2, #1                          ' t2 := -1
                        mov     t1, par                         
                        wrlong  t2, t1                          ' write to ircode 
                        add     t1, #4
                        wrlong  t2, t1                          ' write to irbits

                  
waitrx                  rdlong  t1, par                 wz      ' wait for enable (0)
        if_nz           jmp     #waitrx
                            
waitstart               waitpeq rxmask, rxmask                  ' wait for idle
                        mov     phsa, #0                        ' reset bit timer                                      
                        waitpne rxmask, rxmask                  ' wait for falling edge
                        nop
                        waitpeq rxmask, rxmask                  ' wait for rising edge
                        cmp     starttix, phsa          wc, wz  ' valid start bit?
        if_a            jmp     #waitstart                      ' try again if no

restart                 mov     phsb, #0                        ' reset timeout
                        mov     rxbits, #0                      ' reset bit count
                        
waitbit                 mov     phsa, #0                        ' reset bit timer
:loop                   cmp     bittix, phsb            wc      ' check timeout while waiting
        if_b            jmp     #irdone                         ' if timeout exceeded, abort

                        test    rxmask, ina             wz      ' look for new bit
        if_nz           jmp     #:loop

getbit                  mov     phsb, #0                        ' reset timeout    
                        waitpeq rxmask, rxmask                  ' let bit finish
                        cmp     starttix, phsa          wc      ' check for restart
        if_b            jmp     #restart
                        cmp     bittix, phsa            wc      ' measure bit --> C
                        rcr     rxwork, #1                      ' C --> rxwork.31
                        add     rxbits, #1
                        cmp     rxbits, #32             wz, wc
        if_b            jmp     #waitbit

irdone                  mov     t1, #32
                        sub     t1, rxbits              wz
        if_nz           shr     rxwork, t1                      ' right align ir code
                              
                        mov     t1, par                         ' point to ircode
                        wrlong  rxwork, t1                      ' write rx'd code
                        add     t1, #4                          ' point to irbits
                        wrlong  rxbits, t1                      ' write rx'd bits

                        jmp     #waitrx                         

' -------------------------------------------------------------------------------------------------

POS_DETECT              long    %01000 << 26                    ' increment phsx on high
NEG_DETECT              long    %01100 << 26                    ' increment phsx on low

rxmask                  res     1                               ' mask for IR sensor input
starttix                res     1                               ' ticks in start bit
bittix                  res     1                               ' ticks in '1' bit
                                                                 
rxbits                  res     1                               ' # of bits rx'd
rxwork                  res     1                               ' workspace for incoming byte
                                                                 
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
