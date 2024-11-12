import std/macros
import std/tables
import avr_io


const
  buttonUpPin   = 0 # PIN8 => PORTB[0]
  tim2Out       = 1 # PIN3 => PORTD[3]
  buttonDownPin = 2 # PIN3 => PORTD[3]


type PwmState = enum
  Pwm50DT1Hz
  Pwm20DT1Hz
  Pwm80DT1Hz
  Pwm50DT10Hz
  Pwm50DT50Hz
  Pwm20DT50Hz
  Pwm80DT50Hz


proc `inc`(p: var PwmState) =
  if p == PwmState.high:
    p = PwmState.low
    return
  p = cast[PwmState](p.ord + 1)


proc `dec`(p: var PwmState) =
  if p == PwmState.low:
    p = PwmState.high
  p = cast[PwmState](p.ord - 1)


proc delayMs(ms: uint16) {.importc: "_delay_ms", header: "util/delay.h"}

proc readDebounced(p: Port, pin: uint8): uint8 =
  const debounceResolution = 8
  var   accumulator = 0'u8

  while true:
    var counter = 0
    while counter < debounceResolution:
      accumulator = (accumulator shl 1) or (p.readPin pin)
      delayMs 1
      inc counter
    if accumulator == 0x00 or accumulator == 0xff:
     return accumulator


template setPwm(timer: Timer, freq: uint32, dt: uint8) =
  const
    mcuFreq = 16e6.uint32
    pwmPre  = 1024.uint32 # No prescaler in use
    ocraVal  = mcuFreq div (pwmPre * freq) - 1
    ocrbVal  = (ocraVal * dt) div 100

  timer1.ocra[] = ocraVal.uint16
  timer1.ocrb[] = ocrbVal.uint16


proc initPwmTimer1 =
  # 16-bit timer1 in CTC mode using interrupts
  timer1.setTimerFlag({TimCtlB16Flag.wgm2, cs0, cs2})
  timer1.setPwm(1, 50)
  timer1.setTimerFlag({Timsk16Flag.ociea, ocieb})


proc setPwmHandle   {.isr(Timer1CompAVect).} = portB.setPin(tim2Out)
proc clearPwmHandle {.isr(Timer1CompBVect).} = portB.clearPin(tim2Out)


template actuatePwm(state: PwmState) =
  case state
  of Pwm50DT1Hz:
    timer1.setPwm(1, 50)
  of Pwm20DT1Hz:
    timer1.setPwm(1, 20)
  of Pwm80DT1Hz:
    timer1.setPwm(1, 80)
  of Pwm50DT10Hz:
    timer1.setPwm(10, 50)
  of Pwm50DT50Hz:
    timer1.setPwm(50, 50)
  of Pwm20DT50Hz:
    timer1.setPwm(50, 20)
  of Pwm80DT50Hz:
    timer1.setPwm(50, 80)


proc loop =
  portB.asOutputPin(tim2Out)
  portB.asInputPullupPin(buttonUpPin)
  portB.asInputPullupPin(buttonDownPin)
  initPwmTimer1()
  sei()

  var
    state = Pwm50DT1Hz
    buttonStateUp   = false
    buttonStateDown = false

  while true:
    let pressedUp   = portB.readDebounced(buttonUpPin) == 0x00
    let pressedDown = portB.readDebounced(buttonDownPin) == 0x00

    if pressedUp and pressedUp != buttonStateUp:
      inc state
      actuatePwm state

    if pressedDown and pressedDown != buttonStateDown:
      dec state
      actuatePwm state

    buttonStateUp = pressedUp
    buttonStateDown = pressedDown

loop()
