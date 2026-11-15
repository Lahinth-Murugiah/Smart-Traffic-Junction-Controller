;=========================================================
; SMART TRAFFIC LIGHT CONTROLLER
; ATmega328P / Arduino Uno
; AVRASM - Microchip Studio
; Clock: 16 MHz
;
; PIN CONNECTIONS - UNCHANGED
;
; PB0-PB4 = Five pedestrian countdown LEDs
; PD0     = Push button (active LOW)
; PD1     = Module 1 RED
; PD2     = Module 1 YELLOW
; PD3     = Module 1 GREEN
; PD4     = Module 2 RED
; PD5     = Module 2 YELLOW
; PD6     = Module 2 GREEN
; PC0/A0  = LDR
;
; MODULE 1 = NORTH AND SOUTH
; MODULE 2 = EAST AND WEST
;
; NORMAL:
; Green       = 10 seconds
; Both yellow = 3 seconds
;
; DARKNESS DURING GREEN:
; Active direction yellow = 5 seconds
; Both red = 1 second
; Then Night mode
;
; NIGHT MODE:
; Both yellow LEDs flash at 1 Hz
; Brightness must remain detected for 5 seconds
; Both red = 1 second before normal operation
;
; PEDESTRIAN:
; Both red for 5 seconds
; Five countdown LEDs
; Button requests are not queued during crossing
;=========================================================

.include "m328pdef.inc"

;=========================================================
; CONSTANTS
;=========================================================

.equ LIGHT_THRESHOLD = 125

.equ GREEN_TICKS = 100
.equ YELLOW_TICKS = 30
.equ ALL_RED_TICKS = 10
.equ NIGHT_RETURN_TICKS = 50
.equ NIGHT_TRANSITION_TICKS = 50
.equ BLINK_HALF_TICKS = 5

;=========================================================
; RESET VECTOR
;=========================================================

.cseg
.org 0x0000
    rjmp RESET

;=========================================================
; INITIALIZATION
;=========================================================

RESET:

    cli

    ; Initialize stack pointer
    ldi r16, high(RAMEND)
    out SPH, r16

    ldi r16, low(RAMEND)
    out SPL, r16

    ; PB0-PB4 outputs
    ldi r16, 0x1F
    out DDRB, r16

    ; Countdown LEDs OFF
    clr r16
    out PORTB, r16

    ; PD0 input; PD1-PD6 outputs
    ldi r16, 0x7E
    out DDRD, r16

    ; Both red; enable PD0 internal pull-up
    ldi r16, 0x13
    out PORTD, r16

    ; ADC0 input
    cbi DDRC, PC0
    cbi PORTC, PC0

    ; AVCC reference, left-adjusted, ADC0 selected
    ldi r16, (1<<REFS0) | (1<<ADLAR)
    sts ADMUX, r16

    ; Enable ADC, prescaler 128
    ldi r16, (1<<ADEN) | (1<<ADPS2) | (1<<ADPS1) | (1<<ADPS0)
    sts ADCSRA, r16

    ; Initialize variables
    clr r19                 ; Pedestrian request
    clr r18                 ; Timer/blink counter
    clr r23                 ; Night yellow state
    clr r26                 ; Brightness counter
    clr r27                 ; Button-held latch

    ; Initial light check
    rcall CHECK_LIGHT
    tst r25
    breq START_IN_NIGHT

    ; Start with both RED for 1 second
    ldi r16, 0x13
    out PORTD, r16

    ldi r17, ALL_RED_TICKS
    rcall FIXED_TICKS

    rcall CHECK_LIGHT
    tst r25
    breq START_IN_NIGHT

    rjmp M1_GREEN

START_IN_NIGHT:
    jmp NIGHT_MODE

;=========================================================
; MODULE 1 GREEN / MODULE 2 RED
;=========================================================

M1_GREEN:

    rcall CHECK_LIGHT
    tst r25
    breq M1_GREEN_START_DARK

    ; M1 GREEN, M2 RED
    ldi r16, 0x19
    out PORTD, r16

    ldi r16, 0
    out PORTB, r16

    ldi r17, GREEN_TICKS

M1_GREEN_LOOP:

    rcall DELAY_100MS

    rcall CHECK_LIGHT
    tst r25
    breq M1_GREEN_DARK

    rcall POLL_BUTTON

    dec r17
    brne M1_GREEN_LOOP

    tst r19
    breq M1_NORMAL_YELLOW

    jmp M1_PED_YELLOW

M1_GREEN_START_DARK:
    jmp NIGHT_MODE

M1_GREEN_DARK:
    jmp NIGHT_FROM_M1

;=========================================================
; NORMAL TRANSITION: BOTH YELLOW FOR 3 SECONDS
;=========================================================

M1_NORMAL_YELLOW:

    ; Both yellow LEDs ON
    ldi r16, 0x25
    out PORTD, r16

    ldi r17, YELLOW_TICKS

M1_NORMAL_YELLOW_LOOP:

    rcall DELAY_100MS

    rcall CHECK_LIGHT
    tst r25
    breq M1_NORMAL_YELLOW_DARK

    dec r17
    brne M1_NORMAL_YELLOW_LOOP

    jmp M2_GREEN

M1_NORMAL_YELLOW_DARK:
    jmp NIGHT_MODE

;=========================================================
; PEDESTRIAN REQUEST AFTER MODULE 1 GREEN
; M1 YELLOW / M2 RED FOR 3 SECONDS
;=========================================================

M1_PED_YELLOW:

    ldi r16, 0x15
    out PORTD, r16

    ldi r17, YELLOW_TICKS

M1_PED_YELLOW_LOOP:

    rcall DELAY_100MS

    rcall CHECK_LIGHT
    tst r25
    breq M1_PED_YELLOW_DARK

    dec r17
    brne M1_PED_YELLOW_LOOP

    rcall PEDESTRIAN_CROSSING

    jmp M2_GREEN

M1_PED_YELLOW_DARK:
    jmp NIGHT_FROM_M1

;=========================================================
; MODULE 2 GREEN / MODULE 1 RED
;=========================================================

M2_GREEN:

    rcall CHECK_LIGHT
    tst r25
    breq M2_GREEN_START_DARK

    ; M1 RED, M2 GREEN
    ldi r16, 0x43
    out PORTD, r16

    ldi r16, 0
    out PORTB, r16

    ldi r17, GREEN_TICKS

M2_GREEN_LOOP:

    rcall DELAY_100MS

    rcall CHECK_LIGHT
    tst r25
    breq M2_GREEN_DARK

    rcall POLL_BUTTON

    dec r17
    brne M2_GREEN_LOOP

    tst r19
    breq M2_NORMAL_YELLOW

    jmp M2_PED_YELLOW

M2_GREEN_START_DARK:
    jmp NIGHT_MODE

M2_GREEN_DARK:
    jmp NIGHT_FROM_M2

;=========================================================
; NORMAL TRANSITION: BOTH YELLOW FOR 3 SECONDS
;=========================================================

M2_NORMAL_YELLOW:

    ldi r16, 0x25
    out PORTD, r16

    ldi r17, YELLOW_TICKS

M2_NORMAL_YELLOW_LOOP:

    rcall DELAY_100MS

    rcall CHECK_LIGHT
    tst r25
    breq M2_NORMAL_YELLOW_DARK

    dec r17
    brne M2_NORMAL_YELLOW_LOOP

    jmp M1_GREEN

M2_NORMAL_YELLOW_DARK:
    jmp NIGHT_MODE

;=========================================================
; PEDESTRIAN REQUEST AFTER MODULE 2 GREEN
; M1 RED / M2 YELLOW FOR 3 SECONDS
;=========================================================

M2_PED_YELLOW:

    ldi r16, 0x23
    out PORTD, r16

    ldi r17, YELLOW_TICKS

M2_PED_YELLOW_LOOP:

    rcall DELAY_100MS

    rcall CHECK_LIGHT
    tst r25
    breq M2_PED_YELLOW_DARK

    dec r17
    brne M2_PED_YELLOW_LOOP

    rcall PEDESTRIAN_CROSSING

    jmp M1_GREEN

M2_PED_YELLOW_DARK:
    jmp NIGHT_FROM_M2

;=========================================================
; DARKNESS WHILE MODULE 1 WAS GREEN
; M1 YELLOW / M2 RED FOR 5 SECONDS
;=========================================================

NIGHT_FROM_M1:

    ; Discard any old daytime request
    clr r19

    ; Turn countdown LEDs OFF
    clr r16
    out PORTB, r16

    ; M1 YELLOW / M2 RED
    ldi r16, 0x15
    out PORTD, r16

    ldi r17, NIGHT_TRANSITION_TICKS
    rcall FIXED_TICKS

    ; Both RED for 1 second
    ldi r16, 0x13
    out PORTD, r16

    ldi r17, ALL_RED_TICKS
    rcall FIXED_TICKS

    jmp NIGHT_MODE

;=========================================================
; DARKNESS WHILE MODULE 2 WAS GREEN
; M1 RED / M2 YELLOW FOR 5 SECONDS
;=========================================================

NIGHT_FROM_M2:

    clr r19

    clr r16
    out PORTB, r16

    ; M1 RED / M2 YELLOW
    ldi r16, 0x23
    out PORTD, r16

    ldi r17, NIGHT_TRANSITION_TICKS
    rcall FIXED_TICKS

    ; Both RED for 1 second
    ldi r16, 0x13
    out PORTD, r16

    ldi r17, ALL_RED_TICKS
    rcall FIXED_TICKS

    jmp NIGHT_MODE

;=========================================================
; PEDESTRIAN CROSSING
; BOTH RED FOR 5 SECONDS
;=========================================================

PEDESTRIAN_CROSSING:

    ; Both RED
    ldi r16, 0x13
    out PORTD, r16

    ; Discard request and ignore button until released
    clr r19
    ldi r27, 1

    ; 5 seconds remaining
    ldi r16, 0b00011111
    out PORTB, r16
    rcall DELAY_1SEC

    ; 4 seconds remaining
    ldi r16, 0b00001111
    out PORTB, r16
    rcall DELAY_1SEC

    ; 3 seconds remaining
    ldi r16, 0b00000111
    out PORTB, r16
    rcall DELAY_1SEC

    ; 2 seconds remaining
    ldi r16, 0b00000011
    out PORTB, r16
    rcall DELAY_1SEC

    ; 1 second remaining
    ldi r16, 0b00000001
    out PORTB, r16
    rcall DELAY_1SEC

    ; Countdown finished
    clr r16
    out PORTB, r16

    ret

;=========================================================
; NIGHT MODE
; BOTH YELLOW FLASH TOGETHER
; 500 ms ON / 500 ms OFF
; REQUIRE 5 CONSECUTIVE SECONDS OF LIGHT TO EXIT
;=========================================================

NIGHT_MODE:

    ; Clear old requests on entering Night mode
    clr r19

    ; Countdown LEDs OFF
    clr r16
    out PORTB, r16

    ; Reset counters
    clr r18
    clr r26

    ; Yellow state = ON
    ldi r23, 1

    ; Both yellow ON
    ldi r16, 0x25
    out PORTD, r16

NIGHT_LOOP:

    rcall DELAY_100MS

    ; Allow pedestrian request during Night mode
    rcall POLL_BUTTON

    tst r19
    brne NIGHT_PED_REQUEST

    ; Check the light sensor
    rcall CHECK_LIGHT

    tst r25
    breq NIGHT_DARK_SAMPLE

    ; Bright sample
    inc r26

    cpi r26, NIGHT_RETURN_TICKS
    brlo NIGHT_BRIGHT_NOT_READY

    jmp NIGHT_TO_DAY

NIGHT_DARK_SAMPLE:

    ; Any dark sample resets the 5-second counter
    clr r26

NIGHT_BRIGHT_NOT_READY:

    ; Toggle yellow every five 100 ms ticks
    inc r18

    cpi r18, BLINK_HALF_TICKS
    brlo NIGHT_LOOP

    clr r18

    tst r23
    breq NIGHT_YELLOW_ON

    ; Turn both yellow LEDs OFF
    ldi r16, 0x01
    out PORTD, r16

    clr r23

    jmp NIGHT_LOOP

NIGHT_YELLOW_ON:

    ; Turn both yellow LEDs ON
    ldi r16, 0x25
    out PORTD, r16

    ldi r23, 1

    jmp NIGHT_LOOP

;=========================================================
; BUTTON PRESSED DURING NIGHT MODE
; BOTH RED + 5-SECOND COUNTDOWN
; THEN RETURN TO NIGHT MODE
;=========================================================

NIGHT_PED_REQUEST:

    clr r19

    rcall PEDESTRIAN_CROSSING

    jmp NIGHT_MODE

;=========================================================
; NIGHT TO DAY
; BOTH RED FOR 1 SECOND BEFORE NORMAL TRAFFIC
;=========================================================

NIGHT_TO_DAY:

    ; Countdown LEDs OFF
    clr r16
    out PORTB, r16

    ; Both RED
    ldi r16, 0x13
    out PORTD, r16

    ldi r17, ALL_RED_TICKS
    rcall FIXED_TICKS

    ; Recheck: darkness may have returned
    rcall CHECK_LIGHT

    tst r25
    breq NIGHT_MODE

    jmp M1_GREEN

;=========================================================
; FIXED TIMER
; R17 = number of 100 ms ticks
; Does not check the LDR during the interval
;=========================================================

FIXED_TICKS:

    tst r17
    breq FIXED_TICKS_DONE

FIXED_TICKS_LOOP:

    rcall DELAY_100MS

    dec r17
    brne FIXED_TICKS_LOOP

FIXED_TICKS_DONE:

    ret

;=========================================================
; BUTTON POLLING
; PD0 HIGH = RELEASED
; PD0 LOW  = PRESSED
;
; R19 = pending request
; R27 = press latch, prevents repeat requests while held
;=========================================================

POLL_BUTTON:

    ; If PD0 is HIGH, the button is released
    sbis PIND, PD0
    rjmp BUTTON_IS_PRESSED

    ; Released: permit a new press
    clr r27
    ret

BUTTON_IS_PRESSED:

    ; Already recorded this press?
    tst r27
    brne BUTTON_POLL_DONE

    ; Debounce
    rcall DELAY_20MS

    ; Confirm button is still pressed
    sbis PIND, PD0
    rjmp BUTTON_CONFIRMED

    ret

BUTTON_CONFIRMED:

    ldi r27, 1
    ldi r19, 1

BUTTON_POLL_DONE:

    ret

;=========================================================
; ADC LIGHT SENSOR
;
; R25 = 0 DARK
; R25 = 1 LIGHT
;
; ADCH < 125  = DARK
; ADCH >= 125 = LIGHT
;=========================================================

CHECK_LIGHT:

    ; Start ADC conversion
    lds r16, ADCSRA
    ori r16, (1<<ADSC)
    sts ADCSRA, r16

ADC_WAIT:

    lds r16, ADCSRA

    sbrc r16, ADSC
    rjmp ADC_WAIT

    ; Read upper 8 ADC bits
    lds r24, ADCH

    cpi r24, LIGHT_THRESHOLD
    brlo ADC_DARK

    ; LIGHT
    ldi r25, 1

    ret

ADC_DARK:

    ; DARK
    clr r25

    ret

;=========================================================
; ONE SECOND DELAY
; 10 x 100 ms
;=========================================================

DELAY_1SEC:

    ldi r18, 10

DELAY_1SEC_LOOP:

    rcall DELAY_100MS

    dec r18
    brne DELAY_1SEC_LOOP

    ret

;=========================================================
; ACCURATE APPROXIMATE 100 ms TIMER1 DELAY
; CPU = 16 MHz
; Timer1 prescaler = 64
; Timer clock = 250 kHz
; 25,000 counts = 100 ms
; OCR1A = 24,999
;=========================================================

DELAY_100MS:

    ; OCR1A = 24999
    ldi r16, high(24999)
    sts OCR1AH, r16

    ldi r16, low(24999)
    sts OCR1AL, r16

    ; Stop Timer1
    clr r16
    sts TCCR1B, r16

    ; Reset counter
    sts TCNT1H, r16
    sts TCNT1L, r16

    ; Clear compare flag
    ldi r16, (1<<OCF1A)
    out TIFR1, r16

    ; CTC mode, prescaler 64
    ldi r16, (1<<WGM12) | (1<<CS11) | (1<<CS10)
    sts TCCR1B, r16

TIMER1_WAIT:

    in r16, TIFR1

    sbrs r16, OCF1A
    rjmp TIMER1_WAIT

    ; Stop Timer1
    clr r16
    sts TCCR1B, r16

    ; Clear compare flag for next delay
    ldi r16, (1<<OCF1A)
    out TIFR1, r16

    ret

;=========================================================
; APPROXIMATE 20 ms BUTTON DEBOUNCE
;=========================================================

DELAY_20MS:

    ldi r20, 2

DELAY20_OUTER:

    ldi r21, 200

DELAY20_MIDDLE:

    ldi r22, 250

DELAY20_INNER:

    dec r22
    brne DELAY20_INNER

    dec r21
    brne DELAY20_MIDDLE

    dec r20
    brne DELAY20_OUTER

    ret

;=========================================================
; END OF PROGRAM
;=========================================================
