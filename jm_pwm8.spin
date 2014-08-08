'' =================================================================================================
''
''   File....... jm_pwm8.spin
''   Purpose.... LED modulation using fixed-frequency pwm (up to ~360Hz @ 80MHz sys clock)
''   Author..... Jon "JonnyMac" McPhalen
''               Copyright (c) 2011-2012 Jon McPhalen
''               -- see below for terms of use
''   E-mail..... jon@jonmcphalen.com
''   Started.... 
''   Updated.... 06 JUL 2012
''
'' =================================================================================================


con

  MIN_TIX  = 850                                                ' cnt ticks per pwm loop

  LOG      = $00                                                ' output modes  
  LINEAR   = $FF


con

  CHANNELS = 8
  LAST_CH  = CHANNELS - 1

  
var

  long  cog

  long  chmode                                                  ' bit mask; 0 = log, 1 = linear
  long  pincount                                                ' pins used 
  long  basepin                                                 ' lsb of group
  long  bittix                                                  ' tix per bit
  long  curvepntr                                               ' hub address of
  long  brpntr  
  
  byte  brightness[CHANNELS]                                    ' brightness levels


pub start(count, base)

'' Start PWM8 pwm driver; uses one cog
'' -- count is number of pwm outputs (1 to CHANNELS)
'' -- base is the first pin to use (0 to 28-count); protects rx, tx, i2c pins

  return startx(count, base, 360, -1)                           ' pwm @ 360Hz, internal table

  
pub startx(count, base, freq, cpntr)

'' Start PWM8 pwm driver; uses one cog
'' -- n is number of pwm outputs (1 to 8)
'' -- p is the first pin to use (0 to 28-n); protects rx, tx, i2c pins
'' -- freq is the modulation frequency
'' -- cpntr is address of brightness correction table (-1 for default log table)

  stop                                                          ' stop if running

  if ((count => 1) and (count =< 8))                            ' count okay?
    if ((base => 0) and (base =< (28-count)))                   ' base pin okay?
      pincount := count                                         ' setup parameters                                  
      basepin  := base
      bittix   := ((clkfreq / freq) >> 8) #> MIN_TIX
      if (cpntr < 0)                                            ' use default adjustment curve?
        curvepntr := @LogTable                                  '  yes
      else
        curvepntr := cpntr                                      ' no, use specified table
      brpntr := @brightness

      cog := cognew(@pwm8, @chmode) + 1                         ' start the pwm cog

  return cog
  

pub stop

'' Stops PWM8 driver; frees a cog

  set_all(0) 

  if (cog)
    cogstop(cog - 1)
    cog := 0


pub running

'' Reports true if PWM cog is loaded

  return (cog > 0)


pub pwm_mode(ch, state) | mask

'' Set mode for channel
'' -- ch is 0 to 7 for individual channel
''    * $FF uses state as 8-bit mask for all
'' -- state 0 uses log table (best for LEDs); state 1 uses direct PWM value

  case ch
    0..LAST_CH:
      mask := 1 << ch
      if (state)
        chmode |= mask
      else
        chmode &= !mask & $FF

    $FF:
      chmode := state & $FF

  return chmode & $FF   
   

pub set(ch, level)

'' Sets channel to specified level

  if ((ch => 0) and (ch =< LAST_CH))
    brightness[ch] := 0 #> level <# 255

  return brightness[ch]
    

pub set_all(level)

'' Set all channels to same level

  level := 0 #> level <#255                                     ' limit to byte value
  bytefill(@brightness[0], level, CHANNELS)

  return level


pub high(ch)

'' Sets channel to on

  if ((ch => 0) and (ch =< LAST_CH))
    brightness[ch] := 255


pub low(ch)

'' Sets channel to off

  if ((ch => 0) and (ch =< LAST_CH))
    brightness[ch] := 0


pub toggle(ch)

'' Inverts channel level

  if ((ch => 0) and (ch =< LAST_CH))
    brightness[ch] := 0 #> (255 - brightness[ch]) <# 255

  
pub inc(ch)

'' Increment channel brightness

  if ((ch => 0) and (ch =< LAST_CH))
    if (brightness[ch] < 255)
      ++brightness[ch]

  return brightness[ch]


pub inc_all | ch

'' Increment all channels

  repeat ch from 0 to 7
    if (brightness[ch] < 255)
      ++brightness[ch]


pub dec(ch)

'' Decrement channel brightness

  if ((ch => 0) and (ch =< LAST_CH))
    if (brightness[ch] > 0)
      --brightness[ch]

  return brightness[ch]


pub dec_all | ch

'' Decrement all channels

  repeat ch from 0 to 7
    if (brightness[ch] > 0)
      --brightness[ch]


pub digital(value, mask) | ch

'' Sets enabled pins (in mask) to corresponding bit in value

  repeat ch from 0 to LAST_CH                                   ' loop through outputs
    if (mask & (1 << ch))                                       ' if channel enabled
      if (value & (1 << ch))                                    ' if on
        brightness[ch] := 255                                   '  set to full 
      else
        brightness[ch] := 0                                     '  set to off


pub dcd(bit)

'' Sets output to decoded power-of-2 value

  if (bit < 0)                                                  ' if negative
    set_all(0)                                                  '  all off
  elseif (bit =< LAST_CH)                                       ' if valid
    digital(1 << bit, %1111_1111)                               '  convert to bit output
              

pub read(ch)

'' Returns channel brightness

  if ((ch => 0) and (ch =< LAST_CH))
    return brightness[ch]
  else
    return -1


pub ez_log(level)

'' Shapes linear input to quasi-log output
'' -- for use when mode is 1 (direct value)

  return (level * level) / 255


pub address

'' Returns hub address of brightness array

  return @brightness
  

dat

' Simple log table for better LED brightness control over 0 - 255 range

                        byte

LogTable                byte    000, 000, 000, 000, 000, 000, 000, 000
                        byte    000, 000, 000, 000, 000, 000, 000, 000
                        byte    001, 001, 001, 001, 001, 001, 001, 002
                        byte    002, 002, 002, 002, 003, 003, 003, 003
                        byte    004, 004, 004, 004, 005, 005, 005, 005
                        byte    006, 006, 006, 007, 007, 007, 008, 008
                        byte    009, 009, 009, 010, 010, 011, 011, 011
                        byte    012, 012, 013, 013, 014, 014, 015, 015
                        byte    016, 016, 017, 017, 018, 018, 019, 019
                        byte    020, 020, 021, 022, 022, 023, 023, 024
                        byte    025, 025, 026, 027, 027, 028, 029, 029
                        byte    030, 031, 031, 032, 033, 033, 034, 035
                        byte    036, 036, 037, 038, 039, 040, 040, 041
                        byte    042, 043, 044, 044, 045, 046, 047, 048
                        byte    049, 050, 050, 051, 052, 053, 054, 055
                        byte    056, 057, 058, 059, 060, 061, 062, 063
                        byte    064, 065, 066, 067, 068, 069, 070, 071
                        byte    072, 073, 074, 075, 076, 077, 079, 080
                        byte    081, 082, 083, 084, 085, 087, 088, 089
                        byte    090, 091, 093, 094, 095, 096, 097, 099
                        byte    100, 101, 102, 104, 105, 106, 108, 109
                        byte    110, 112, 113, 114, 116, 117, 118, 120
                        byte    121, 122, 124, 125, 127, 128, 129, 131
                        byte    132, 134, 135, 137, 138, 140, 141, 143
                        byte    144, 146, 147, 149, 150, 152, 153, 155
                        byte    156, 158, 160, 161, 163, 164, 166, 168
                        byte    169, 171, 172, 174, 176, 177, 179, 181
                        byte    182, 184, 186, 188, 189, 191, 193, 195
                        byte    196, 198, 200, 202, 203, 205, 207, 209
                        byte    211, 212, 214, 216, 218, 220, 222, 224
                        byte    225, 227, 229, 231, 233, 235, 237, 239
                        byte    241, 243, 245, 247, 249, 251, 253, 255

  
dat

                        org     0

pwm8                    mov     t1, par                         ' start of parameters

                        add     t1, #4                          ' skip over mode
                        rdlong  chcount, t1                     ' read channel count
                        
                        add     t1, #4
                        rdlong  ch0pin, t1                      ' read pin for ch 0
                        
                        add     t1, #4
                        rdlong  bittime, t1                     ' read ticks per bit
                        
                        add     t1, #4
                        rdlong  hubcurve, t1                    ' read hub addr of adjust curve
                        
                        add     t1, #4
                        rdlong  hubch0, t1                      ' read hub addr of levels array

                        mov     t1, #%1111_1111                 ' create mask for pins
                        mov     t2, #8
                        sub     t2, chcount
                        shr     t1, t2                          ' removed unused
                        shl     t1, ch0pin                      ' align lsbs
                        mov     dira, t1                        ' set outputs     

                        mov     bridx, #0                       ' reset brightness index
                        
                        mov     timer, bittime                  ' start bit timer
                        add     timer, cnt                      ' sync with system timer

                        
pwmloop                 rdlong  modebits, par                   ' get mode bits
                        mov     mdmask, #1                      ' reset channel mode bit mask  

                        mov     chidx, #0                       ' reset channel index
                        mov     chpntr, hubch0                  ' reset hub pointer for levels
                        mov     chmask, #1                      ' reset channel output mask
                        shl     chmask, ch0pin
                        
chx                     rdbyte  t1, chpntr                      ' read channel level
                        test    modebits, mdmask        wc      ' check for linear mode
        if_c            jmp     #chtest                         ' jump if linear mode

chcurve                 mov     t2, hubcurve                    ' point to curve
                        add     t2, t1                          ' offset with value
                        rdbyte  t1, t2                          ' convert value

chtest                  cmp     t1, #0                  wz      ' off?
        if_z            andn    outa, chmask                    ' yes, kill output
        if_z            jmp     #chexit                         '  and exit
                        cmp     bridx, t1               wc, wz  ' check level
        if_be           or      outa, chmask                    '  on if not done
        if_a            andn    outa, chmask                    '  else kill output


chexit                  shl     mdmask, #1                      ' update mode bit test mask  
                        add     chidx, #1                       ' update channel index
                        add     chpntr, #1                      ' update hub pointer
                        shl     chmask, #1                      ' update output mask

                        cmp     chidx, chcount          wc, wz  ' done with all channels?
        if_b            jmp     #chx                            ' no, do next
                                                
looppad                 add     bridx, #1                       ' update brightness index
                        and     bridx, #$FF                     ' rollover
                                                
                        waitcnt timer, bittime                     
                        jmp     #pwmloop                        

' --------------------------------------------------------------------------------------------------                        

chcount                 res     1                               ' channel count
ch0pin                  res     1                               ' channel 0 pin #
bittime                 res     1                               ' timing for each bit
hubcurve                res     1                               ' hub address of curve data
hubch0                  res     1                               ' hub address of brightness array                     

bridx                   res     1                               ' test brightness
timer                   res     1                               ' bit timer

chidx                   res     1                               ' channel index
chpntr                  res     1                               ' hub pointer to levels
chmask                  res     1                               ' channel mask
mdmask                  res     1                               ' mask for mode bits testing

modebits                res     1

t1                      res     1                               ' work vars
t2                      res     1
t3                      res     1

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
