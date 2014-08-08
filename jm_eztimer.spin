'' =================================================================================================
''
''   File....... jm_eztimer.spin
''   Purpose.... Asyncrhonous (accumulator) timer
''               -- methods must be called every ~53.687s (80MHz) or sooner to prevent rollover
''   Author..... Jon "JonnyMac" McPhalen
''               Copyright (c) 2014 Jon McPhalen
''               -- see below for terms of use
''   E-mail..... jon@jonmcphalen.com
''   Started.... 
''   Updated.... 23 MAY 2014
''
'' =================================================================================================


con


var

  long  sync                                                    ' sync point (snapshot of cnt)
  long  tix                                                     ' ticks accumulator
  long  tms                                                     ' ticks per millisecond
  long  ms                                                      ' milliseconds accumulator
  

pub start 

'' Start or restart the timer object

  startx(cnt)                                                   ' start now
        

pub startx(spoint)

'' Start the timer object with specific sync point
'' -- for synchronizing with another timer

  sync  := spoint                                               ' set sync point
  tms   := clkfreq / 1_000                                      ' set ticks/millisecond
  tix   := 0                                                    ' reset ticks accumulator
  ms    := 0                                                    ' reset milliseconds accumulator

  
pub millis

'' Returns milliseconds accumulator

  mark                                                          ' update timer

  return ms                                                     ' return milliseconds


pub seconds

'' Returns seconds (from ms accumulator)

  mark                                                          ' update timer

  return ms / 1000                                              ' return seconds


pub adjust(msoffset)

'' Adjust milliseconds register

  mark

  ms += msoffset


pub mark | now, delta

'' Marks the current point
'' -- updates ticks and ms accumulators
'' -- returns current milliseconds

  now := cnt                                                    ' capture cnt
  delta := now - sync                                           ' delta since last capture

  if (delta < 0)                                                ' rollover past posx?
    ms += posx / tms                                            ' add posx millis
    delta += posx + (posx // tms) + 2                           ' correct delta

  tix += delta                                                  ' increment ticks
  ms += tix / tms                                               ' update millis
  tix //= tms                                                   ' udpate ticks    

  sync := now                                                   ' reset sync point
  
  return ms                                                     ' return millis


pub get_sync

'' Returns sync point
'' -- used to syncronize multiple timers

  return sync

  
dat { license }

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
