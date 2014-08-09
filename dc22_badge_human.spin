'' =================================================================================================
''
''   File....... dc22_badge_human.spin
'' 
''   Authors.... Jon "JonnyMac" McPhalen and Ryan "1o57" Clarke
''               MIT License
''               -- see below for terms of use
''
''   E-mail..... jon@jonmcphalen.com
''               1o57@10000100001.org 
''
'' =================================================================================================

{{

  Welcome to Defcon 22. This year we would like to invite you to experiment more fully with your
  badge -- feel free to play around with code.

  You can load directly to RAM [F10] if you don't want to blast your firmware, but even if you do,
  we are giving you the source from the start. The source provides a nice badge template with extra
  objects so that you can experiment with LEDs, buttons, IR (in and out), timing, speed changes, etc.

  Completing the challenge will at some point require you to 'update' your badge -- but for now, how
  about changing your LED pattern? It's easier than you think! If you need help, feel free to stop
  by the Hardware Hacking Village, or simply ask someone who has a different pattern than yours.
  Create a new pattern -- have fun!

}}


con { timing }

  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000                                          ' use 5MHz crystal

  CLK_FREQ = ((_clkmode - xtal1) >> 6) * _xinfreq               ' system freq as a constant
  MS_001   = CLK_FREQ / 1_000                                   ' ticks in 1ms
  US_001   = CLK_FREQ / 1_000_000                               ' ticks in 1us


  ' speed settings for power control/reduction
  ' -- use with clkset() instruction

  XT1_P16  = %0_1_1_01_111                                      ' 16x crystal (5MHz) = 80MHz
  XT1_PL8  = %0_1_1_01_110 
  XT1_PL4  = %0_1_1_01_101                                      
  XT1_PL2  = %0_1_1_01_100
  XT1_PL1  = %0_1_1_01_011
  RC_SLOW  = %0_0_0_00_001                                      ' 20kHz


  ' program speed and terminal baud
  
  B_SPEED  = 20     { MHz }
  T_BAUD   = 57_600 { for terminal io }


  IR_FREQ  = 36_000 { matches receiver on DC22 badge }
  IR_BAUD  = 2400   { max supported using IR connection }
  

con { io pins }

  RX1    = 31                                                   ' programming / terminal
  TX1    = 30
  
  SDA    = 29                                                   ' eeprom / i2c
  SCL    = 28

  PAD3   = 27                                                   ' touch pads
  PAD2   = 26
  PAD1   = 25
  PAD0   = 24
  
  LED7   = 23                                                   ' leds
  LED6   = 22
  LED5   = 21
  LED4   = 20
  LED3   = 19
  LED2   = 18
  LED1   = 17
  LED0   = 16

  IR_IN  = 15                                                   ' ir input
  IR_OUT = 14                                                   ' ir output


con { io configuration }

  IS_OFF    =  0                                                ' all bits off   
  IS_ON     = -1                                                ' all bits on    

  IS_LOW    =  0                                                
  IS_HIGH   = -1                                                

  IS_INPUT  =  0
  IS_OUTPUT = -1
  

con { pst formatting }

  #1, HOME, GOTOXY, #8, BKSP, TAB, LF, CLREOL, CLRDN, CR
  #14, GOTOX, GOTOY, CLS


obj

  term : "cryptofullduplexserial64"                             ' serial io for terminal
  irtx : "jm_sircs_tx"                                          ' SIRCS output
  irrx : "jm_sircs_rx"                                          ' SIRCS input
  prng : "jm_prng"                                              ' random #s
  tmr1 : "jm_eztimer"                                           ' asynchronous timer
  ee   : "jm_24xx512"                                           ' eeprom access
  pwm  : "jm_pwm8"                                              ' pwm for LEDs
 

var

  long  ms001                                                   ' system ticks per millisecond
  long  us001                                                   ' system ticks per microsecond


pub main | idx, last, button
           
  setup                                                         ' setup badge io and objects

  term.tx(CLS)                                                  ' clear the terminal
  
  irtx.start(IR_OUT, IR_FREQ)
  
  irrx.start(IR_IN)
  ircog := cognew(recv, @irstack) + 1

  repeat until (read_pads <> %0000)                             ' wait for a pad press
    idx := (prng.random >> 1) // 13
    repeat (idx << 1)
      term.tx(" ")
    idx := (prng.random >> 1) // 13  
    term.caesar(@@Commands[idx])
    pause(250)

  term.tx(CLS) 
  
  term.caesar(@Greets)
  term.tx(CR)
  
  term.otp(@Test3, @Test4)
  term.tx(CR)

  last := -1                                                    ' any button to start
  
  repeat                                                        
    repeat
      button := read_pads                                       ' wait for input
    until ((button <> %0000) and (button <> last))              ' must be new
    last := button                                              ' save for next check
    sendgoon                                                    ' send goon code
    
    case button
      %0001:
        start_animation(@Cylon, 0)                              ' start animation
        term.caesar(@Detective)                                 ' display crypto string
        pause(250)                                              ' allow clean button release
     
      %0101:
        start_animation(@Chaser, 0)
        term.otp(@Scientist, @Driver)
        pause(250)
      
      %0111:     
        start_animation(@Police, 0)
        term.caesar(@Diver)
        pause(250)
        
      %1000:   
        start_animation(@InOut, 0)
        term.otp(@Politician, @Football)
        pause(250)
      
      %1001:
        stop_animation
        term.otp(@RayNelson, @Mystery)
        pause(250)
        
      %1010:
        repeat
          sendgoon
          button := read_pads
          start_animation(@Pulse1, 0)
          pause(100)  
          start_animation(@Pulse2, 0)
          pause(100)  
          start_animation(@Pulse3, 0)
          pause(100)  
          start_animation(@Pulse4, 0)
          pause(100)
          start_animation(@Pulse5, 0)
          pause(100)
          start_animation(@Pulse4, 0)
          pause(100)
          start_animation(@Pulse3, 0)
          pause(100)
          start_animation(@Pulse2, 0)
          pause(100)
          start_animation(@Pulse1, 0)
          pause(100)
          start_animation(@Pulse0, 0)
          pause(100)
        until ((button <> %0000) and (button <> last))              ' must be new
        last := button


pub recv
    repeat
      irrx.start(IR_IN)
      irrx.enable           
      term.hex(irrx.rx, 255)
      

pub sendgoon
    irtx.tx(56354, 20, 16)
 
pub setup

'' Setup badge IO and objects
'' -- set speed before starting other objects

  set_speed(B_SPEED)                                            ' set badge speed (MHz)
  
  set_leds(%00000000)                                           ' LEDs off

  term.start(RX1, TX1, %0000, T_BAUD)                           ' start terminal

  prng.seed(cnt << 2, cnt, $1057, -cnt, cnt ~> 2)               ' seed prng (random #s)
  

con

  { ----------------------------- }
  {  B A D G E   F E A T U R E S  }
  { ----------------------------- }


pub set_speed(mhz)

'' Sets badge clock speed
'' -- sets timing variables ms001 and us001
'' -- note: objects may require restart after speed change

  case mhz
     0: clkset(RC_SLOW,     20_000)                             ' super low power -- sleep mode only!
     5: clkset(XT1_PL1,  5_000_000)
    10: clkset(XT1_PL2, 10_000_000)
    20: clkset(XT1_PL4, 20_000_000)
    40: clkset(XT1_PL8, 40_000_000) 
    80: clkset(XT1_P16, 80_000_000)

  waitcnt(cnt + (clkfreq / 100))                                ' wait ~10ms

  ms001 := clkfreq / 1_000                                      ' set ticks per millisecond for waitcnt
  us001 := clkfreq / 1_000_000                                  ' set ticks per microsecond for waitcnt

  
pub set_leds(pattern)

'' Sets LED pins to output and writes pattern to them
'' -- swaps LSB/MSB for correct binary output

  outa[LED0..LED7] := pattern                                   ' write pattern to LEDs
  dira[LED0..LED7] := IS_HIGH                                   ' make LED pins outputs

  
pub read_pads

'' Reads and returns state of touch pad inputs
'' -- swaps LSB/MSB for correct binary input

  outa[PAD3..PAD0] := IS_HIGH                                   ' charge pads (all output high)   
  dira[PAD3..PAD0] := IS_OUTPUT
    
  dira[PAD3..PAD0] := IS_INPUT                                  ' float pads   
  pause(50)                                                     ' -- allow touch to discharge

  return (!ina[PAD3..PAD0] & $0F) >< 4                          ' return "1" for touched pads


con

  { --------------- }
  {  L E D   F U N  }
  { --------------- }


var

  long  anicog                                                  ' cog running animation
  long  anistack[32]                                            ' stack space for Spin cog
  long  ircog                                                   ' cog running animation
  long  irstack[32]                                             ' stack space for Spin cog
  long  handles
  

pri start_animation(p_table, cycles)

'' Start animation in background cog
'' -- allows LED animation while doing other processes
'' -- p_table is pointer (address of) animation table
'' -- set cycles to 0 to run without stopping

  stop_animation
  
  anicog := cognew(run_animation(p_table, cycles), @anistack) + 1  

  return anicog                                                 ' return cog used


pri stop_animation

'' Stop animation if currently running

  if (anicog)                                                   ' if running
    cogstop(anicog - 1)                                         ' stop the cog
    anicog := 0                                                 ' mark stopped 


pri run_animation(p_table, cycles) | p_leds

'' Run animation
'' -- p_table is pointer (address of) animation table
'' -- cycles is number of iterations to run
''    * 0 cycles runs "forever"
'' -- usually called with start_animation()

  if (cycles =< 0)
    cycles := POSX                                              ' run "forever"

  repeat cycles
    p_leds := p_table                                           ' point to table
    repeat byte[p_leds++]                                       ' repeat for steps in table
      set_leds(byte[p_leds++])                                  ' update leds
      pause(byte[p_leds++])                                     ' hold
      
  anicog := 0                                                   ' mark stopped
  cogstop(cogid)                                                ' stop this cog
    

dat

  ' Animation tables for LEDs
  ' -- 1st byte is number of steps in animation sequence
  ' -- each step holds pattern and hold time (ms)
  ' -- for delays > 255, duplicate pattern + delay

  Cylon       byte      (@Cylon_X - @Cylon) / 2 + 1 
              byte      %10000000, 125
              byte      %01000000, 125
              byte      %00100000, 125 
              byte      %00010000, 125
              byte      %00001000, 125  
              byte      %00000100, 125  
              byte      %00000010, 125  
              byte      %00000001, 125
              byte      %00000010, 125
              byte      %00000100, 125
              byte      %00001000, 125  
              byte      %00010000, 125  
              byte      %00100000, 125    
  Cylon_X     byte      %01000000, 125

  
  ProgBar     byte      (@ProgBar_X - @ProgBar) / 2 + 1 
              byte      %10000000, 125
              byte      %11000000, 125
              byte      %11100000, 125 
              byte      %11110000, 125
              byte      %11111000, 125  
              byte      %11111100, 125  
              byte      %11111110, 500 
              byte      %11111111, 125
              byte      %11111110, 125
              byte      %11111100, 125
              byte      %11111000, 125  
              byte      %11110000, 125  
              byte      %11100000, 125    
  ProgBar_X   byte      %11000000, 125

                    
  Chaser      byte      (@Chaser_X - @Chaser) / 2 + 1      
              byte      %10010010,  75
              byte      %00100100,  75
  Chaser_X    byte      %01001001,  75

                     
  InOut       byte      (@InOut_X - @InOut) / 2 + 1  
              byte      %10000001, 100
              byte      %01000010, 100
              byte      %00100100, 100
              byte      %00011000, 100
              byte      %00100100, 100
  InOut_X     byte      %01000010, 100

          
  Police      byte      (@Police_X - @Police) / 2 + 1 
              byte      %11001100,  75
              byte      %11110000,  75
              byte      %11001100,  75
              byte      %11110000,  75         
              byte      %00001111,  75
              byte      %00110011,  75
              byte      %00001111,  75
  Police_X    byte      %00110011,  75
          

  Pulse1      byte      (@Pulse1_X - @Pulse1) / 2 + 1
              byte      %10000001, 1
  Pulse1_X    byte      %00000000, 20

  
  Pulse2      byte      (@Pulse2_X - @Pulse2) / 2 + 1
              byte      %11000011, 1
  Pulse2_X    byte      %10000001, 20

  
  Pulse3      byte      (@Pulse3_X - @Pulse3) / 2 + 1
              byte      %11100111, 1
  Pulse3_X    byte      %11000011, 20

  
  Pulse4      byte      (@Pulse4_X - @Pulse4) / 2 + 1
              byte      %11111111, 1
  Pulse4_X    byte      %11100111, 20

  Pulse5      byte      (@Pulse5_X - @Pulse5) / 2 + 1
  Pulse5_X    byte      %11111111, 100

  Pulse0      byte      (@Pulse5_X - @Pulse5) / 2 + 1
  Pulse0_X    byte      %00000000, 100  

  
con   

  { ------------- }
  {  B A S I C S  }
  { ------------- }


pub pause(ms) | t

'' Delay program in milliseconds
'' -- ensure set_speed() used before calling

  t := cnt                                                      ' sync to system counter
  repeat (ms #>= 0)                                             ' delay > 0
    waitcnt(t += ms001)                                         ' hold 1ms


pub high(pin)

'' Makes pin output and high

  outa[pin] := IS_HIGH
  dira[pin] := IS_OUTPUT


pub low(pin)

'' Makes pin output and low

  outa[pin] := IS_LOW
  dira[pin] := IS_OUTPUT


pub toggle(pin)

'' Toggles pin state

  !outa[pin]
  dira[pin] := IS_OUTPUT


pub input(pin)

'' Makes pin input and returns current state

  dira[pin] := IS_INPUT

  return ina[pin]


pub pulse_out(pin, us) | state

'' Generate pulse on pin for us microseconds
'' -- ensure set_speed() used before calling
'' -- makes pin output
'' -- pulse out is opposite of pin's input state
'' -- blocks until pulse is finished (to clear counter)

  us *= us001                                                   ' convert us to system ticks
  state := ina[pin]                                             ' read incoming state of pin

  if (ctra == 0)                                                ' ctra available?
    if (state == 0)                                             ' low-high-low
      low(pin)                                                  ' set to output
      frqa := 1 
      phsa := -us                                               ' set timing
      ctra := (%00100 << 26) | pin                              ' start the pulse
      repeat
      until (phsa => 0)                                         ' let pulse finish
                          
    else                                                        ' high-low-high
      high(pin)
      frqa := -1
      phsa := us
      ctra := (%00100 << 26) | pin
      repeat
      until (phsa < 0) 

    ctra := IS_OFF                                              ' release counter
    return true

  elseif (ctrb == 0)               
    if (state == 0)                
      low(pin)                     
      frqb := 1 
      phsb := -us               
      ctrb := (%00100 << 26) | pin 
      repeat
      until (phsb => 0)            
                          
    else                           
      high(pin)
      frqb := -1
      phsb := us
      ctrb := (%00100 << 26) | pin
      repeat
      until (phsb < 0) 

    ctrb := IS_OFF                     
    return true
  
  else
    return false                                                ' alert user of error
  

pub set_freq(ctrx, px, fx)

'' Sets ctrx to frequency fx on pin px (NCO/SE mode)
'' -- fx in hz
'' -- use fx of 0 to stop counter that is running

  if (fx > 0)                             
    fx := ($8000_0000 / (clkfreq / fx)) << 1                    ' convert freq for NCO mode    
    case ctrx                                                    
      "a", "A":                                                  
        ctra := ((%00100) << 26) | px                           ' configure ctra for NCO on pin
        frqa := fx                                              ' set frequency
        dira[px] := IS_OUTPUT                                    
                                                                 
      "b", "B":                                                  
        ctrb := ((%00100) << 26) | px                            
        frqb := fx                                               
        dira[px] := IS_OUTPUT                                    
                                                                 
  else                                                           
    case ctrx                                                    
      "a", "A":                                                  
        ctra := IS_OFF                                          ' disable counter
        outa[px] := IS_OFF                                      ' clear pin/driver 
        dira[px] := IS_INPUT                                  
     
      "b", "B":                         
        ctrb := IS_OFF  
        outa[px] := IS_OFF  
        dira[px] := IS_INPUT 


dat
 
  RayNelson   byte      "IAIHG TPJNU QU CZR GALWXK DC MHR LANK FOTLA OTN LOYOC HPMPB PX HKICW",0
  Test4       byte      "DID YOU REALLY THINK THAT IT WOULD BE SO EASY? Really?  Just running strings?",0
  Greets      byte      16,77,85,66,83,69,67,85,32,74,69,32,84,85,86,83,69,68,32,74,77,85,68,74,79,32,74,77,69,13,0
  Detective   byte      13,74,85,82,69,82,32,71,66,32,79,82,84,86,65,32,86,32,88,65,66,74,32,83,86,65,81,32,85,78,69,66,89,81,13,0
  Scientist   byte      76,81,84,89,86,70,32,82,75,66,32,83,78,90,32,83,81,87,83,85,32,87,82,65,32,73,77,82,66,32,67,70,72,82,32,90,65,65,65,65,32,73,89,77,87,90,32,80,32,69,65,74,81,86,68,32,89,79,84,80,32,76,71,65,87,32,89,75,90,76,13,0
  Diver       byte      10,"DBI DRO PSBCD RKVP YP RSC ZRYXO XEWLOB PYVVYGON LI RSC VKCD XKWO DROX DRO COMYXN RKVP YP RSC XEWLOB",CR,0
  Driver      byte      "SOMETIMES WE HAVE ANSWERS AND DONT EVEN KNOW IT SO ENJOY THE VIEW JUST BE HAPPY",0
  Politician  byte      83,83,80,87,76,77,32,84,72,67,65,80,32,81,80,32,74,84,32,73,87,69,32,87,68,88,70,90,32,89,85,90,88,32,85,77,86,72,88,72,32,90,65,32,67,66,32,80,65,69,32,88,82,79,76,32,70,65,89,32,73,80,89,75,13,0
  Test3       byte      "ZGJG MTM LLPN C NTER MPMH TW",CR,0
  Football    byte      "IT MIGHT BE HELPFUL LATER IF YOU KNOW HOW TO GET TO EDEN OR AT LEAST THE WAY",0
  Mystery     byte      "OH A MYSTERY STRING I SHOULD HANG ON TO THIS FOR LATER I WONDER WHAT ITS FOR OR WHAT IT DECODES TO?",0

  
dat

  Cmd00       byte      $05, $42, $54, $57, $50, $20, $4A, $4E, $4C, $4D, $59, $20, $4D, $54
              byte      $5A, $57, $58, $0D, $00, $4C, $4F, $56, $45, $00 
  Cmd01       byte      $04, $41, $45, $58, $47, $4C, $20, $58, $5A, $0D, $00
  Cmd02       byte      $0E, $47, $49, $50, $41, $57, $48, $0D, $00, $4C, $49, $46, $45, $00
  Cmd03       byte      $0C, $45, $46, $4D, $4B, $20, $4D, $45, $58, $51, $51, $42, $0D, $00
  Cmd04       byte      $04, $53, $46, $49, $43, $0D, $00, $47, $69, $47, $21, $00
  Cmd05       byte      $14, $48, $49, $20, $43, $48, $58, $59, $4A, $59, $48, $58, $59, $48
              byte      $4E, $20, $4E, $42, $49, $4F, $41, $42, $4E, $0D, $00
  Cmd06       byte      $02, $50, $51, $20, $4B, $4F, $43, $49, $4B, $50, $43, $56, $4B, $51
              byte      $50, $0D, $00, $4A, $6F, $6E, $6E, $79, $4D, $61, $63, $00
  Cmd07       byte      $0C, $59, $4D, $44, $44, $4B, $20, $4D, $5A, $50, $20, $44, $51, $42
              byte      $44, $41, $50, $47, $4F, $51, $0D, $00, $48, $41, $50, $50, $59, $00
  Cmd08       byte      $05, $4A, $46, $59, $0D, $00, $48, $45, $41, $4C, $54, $48, $00
  Cmd09       byte      $09, $4D, $58, $20, $57, $58, $43, $20, $5A, $44, $4E, $42, $43, $52
              byte      $58, $57, $20, $4A, $44, $43, $51, $58, $41, $52, $43, $48, $0D, $00 
  Cmd10       byte      $0F, $52, $44, $43, $48, $4A, $42, $54, $0D, $00
  Cmd11       byte      $02, $45, $51, $50, $48, $51, $54, $4F, $0D, $00
  Cmd12       byte      $19, $41, $54, $58, $0D, $00, $57, $45, $41, $4C, $54, $48, $00
              byte      $31, $6F, $35, $37, $00
 
  Commands    word      @Cmd00, @Cmd01, @Cmd02, @Cmd03, @Cmd04, @Cmd05
              word      @Cmd06, @Cmd07, @Cmd08, @Cmd09, @Cmd10, @Cmd11
              word      @Cmd12
  

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
