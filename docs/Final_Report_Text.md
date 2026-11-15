# Smart Traffic Junction Controller — Final Report (Text Extract)

**Course:** IE3064 — Embedded Systems Engineering · **Group:** 14 · **Institution:** Sri Lanka Institute of Information Technology · **Year:** 2026

> **About this file:** This is a searchable text extraction of the team's uploaded 34-page final report. It is **not the original PDF**: diagrams, model photographs, exact table layout, page design and embedded figures are not reproduced here. Refer to the team's original PDF for the authoritative formatted submission.

---

<!-- Source PDF page 1 of 34 -->

Sri Lanka Institute of Information Technology
IE3064: Embedded Systems Engineering
Smart Traffic Junction Controller
Group Members(14)
U.Lathussoban - IT24101646
M.Lahinth - IT24103482

Degree Programme: BSc (Hons) in Computer Systems Engineering
Date of Submission: 15th November 2026

<!-- Source PDF page 2 of 34 -->

TABLE OF CONTENTS

1. INTRODUCTION ........................................................................................................ 5
  1.1 Background .............................................................................................................. 5
  1.2 Project Objectives ................................................................................................... 5
  1.3 Scope ........................................................................................................................ 6

2. SYSTEM OVERVIEW ................................................................................................. 6
  2.1 Functional Organisation ........................................................................................... 6
  2.2 Operating Modes ...................................................................................................... 6
  2.3 Design Requirements ............................................................................................... 7

3. HARDWARE DESIGN AND IMPLEMENTATION ................................................... 7
  3.1 Components Used .................................................................................................... 7
  3.2 Microcontroller Selection ........................................................................................ 8
  3.3 Traffic Module Arrangement ................................................................................... 8
  3.4 Pin-to-Port Mapping ................................................................................................ 8
  3.5 Pedestrian Button ..................................................................................................... 9
  3.6 Countdown Display ................................................................................................. 9
  3.7 Current-Limiting Resistors .................................................................................... 10
  3.8 LDR Sensor............................................................................................................ 10
  3.9 Power Supply ......................................................................................................... 10
  3.10 Physical Construction .......................................................................................... 11

4. FIRMWARE ARCHITECTURE ................................................................................ 11
  4.1 Programming Approach ......................................................................................... 11
  4.2 Initialisation Sequence ........................................................................................... 12
  4.3 Register Allocation................................................................................................. 12
  4.4 Digital Port Configuration ..................................................................................... 13
  4.5 Timer1 Configuration............................................................................................. 13

<!-- Source PDF page 3 of 34 -->

4.6 ADC Configuration ................................................................................................ 14
  4.7 Polling Architecture ............................................................................................... 14

5. OPERATING SEQUENCES ...................................................................................... 15
  5.1 Traffic Output Masks ............................................................................................. 15
  5.2 Timing Constants ................................................................................................... 15
  5.3 Normal Traffic Cycle ............................................................................................. 16
  5.4 Pedestrian Request Recognition ............................................................................ 16
  5.5 Deferred Pedestrian Operation ............................................................................... 17
  5.6 Countdown Sequence............................................................................................. 17
  5.7 Return After Pedestrian Crossing........................................................................... 17
  5.8 Darkness During Green.......................................................................................... 18
  5.9 Night Flashing........................................................................................................ 18
  5.10 Brightness Qualification ...................................................................................... 18
  5.11 Night-to-Day Transition ....................................................................................... 19
  5.12 Pedestrian Input During Night Mode ................................................................... 19

6. STATE MACHINE AND SUBROUTINE FLOWCHARTS...................................... 19
  6.1 Overall Operating State Machine........................................................................... 19
  6.2 Normal Phase Cycling ........................................................................................... 20
  6.3 Button Polling ........................................................................................................ 21
  6.4 Night Detection and Brightness Qualification ....................................................... 22
  6.5 Countdown Routine ............................................................................................... 23

7. TESTING AND RESULTS......................................................................................... 24
  7.1 Evaluation Method ................................................................................................. 24
  7.2 Visual Observations ............................................................................................... 24
  7.3 Nominal Timing Evaluation ................................................................................... 26
  7.4 Evaluation Against the Assignment ....................................................................... 27
  7.5 Interpretation of Results......................................................................................... 30

<!-- Source PDF page 4 of 34 -->

8. DISCUSSION ............................................................................................................. 30
  8.1 Hardware Integration ............................................................................................. 30
  8.2 Timer-Based Operation .......................................................................................... 30
  8.3 Polling and Input Responsiveness ......................................................................... 31
  8.4 Pedestrian Handling ............................................................................................... 31
  8.5 Night-Mode Behaviour .......................................................................................... 31
  8.6 Documentation and Toolchain Requirements ........................................................ 31

9. CONCLUSION ........................................................................................................... 32

10. INDIVIDUAL CONTRIBUTIONS .......................................................................... 32
   U. Lathussoban: Pedestrian Crossing Subsystem ....................................................... 32
   M. Lahinth: Normal and Night Modes ....................................................................... 33

11. REFERENCES.......................................................................................................... 33

## APPENDIX A: SYSTEM CONNECTION SCHEMATIC............................................. 34

<!-- Source PDF page 5 of 34 -->

## 1. INTRODUCTION
### 1.1 Background
A traffic junction controller coordinates vehicle movements through a defined
sequence of signal indications. Its operation requires predictable timing and
controlled transitions between conflicting vehicle groups. Pedestrian crossing
requests introduce an additional requirement because vehicle traffic must be
stopped before pedestrians are given a crossing interval.
This project demonstrates these functions using a scaled four-way junction.
Traffic modules are positioned at the North, South, East and West approaches. A
pedestrian button and five-LED countdown display provide crossing control on
the South approach.
An LDR sensor allows the controller to respond to changes in ambient light.
When sufficient light is detected, the system operates in Normal mode. Under
low-light conditions, the controller enters Night mode and flashes the yellow
indicators simultaneously.
The project uses an Arduino Uno as the hardware platform, but the application
does not use Arduino library functions. AVR Assembly instructions directly
configure the ATmega328P ports, timer and ADC.
### 1.2 Project Objectives
The objectives of the project are:
   1. To construct a four-way traffic junction model using four traffic modules.
   2. To implement the controller entirely in AVR Assembly.
   3. To control traffic outputs and a pedestrian countdown through multiple
ports.
   4. To generate operating intervals using Timer1.
   5. To recognise pedestrian requests and provide an all-red crossing interval.
   6. To display the crossing time using five LEDs.
   7. To select Normal or Night mode using an LDR sensor.
   8. To evaluate the working model through functional observation.
   9. To compare the implemented behaviour with the assignment
requirements.

<!-- Source PDF page 6 of 34 -->

### 1.3 Scope
North and South operate as one coordinated vehicle group, referred to in the
source as Module 1. East and West operate as the second group, referred to as
Module 2.
These names represent logical groups rather than the number of physical traffic
modules. The model contains four physical traffic modules, one at each
approach.
The project does not include vehicle detection, adaptive green timing, separately
controlled turning movements, emergency vehicle priority or network
communication.

## 2. SYSTEM OVERVIEW
### 2.1 Functional Organisation
The controller consists of three main functional parts:
   •   Inputs: the LDR sensor and pedestrian push-button.
   •   Control: the ATmega328P executing the Assembly program.
   •   Outputs: four traffic modules and five countdown LEDs.
The LDR is connected to ADC0. The button is connected to a digital input with
an internal pull-up. Traffic outputs are controlled through PORTD, and the
countdown display is controlled through PORTB.
### 2.2 Operating Modes
The system provides the following operating behaviours:
 Operating            Description
 behaviour
 Normal mode          Alternates the North-South and East-West vehicle
groups.
 Pedestrian           Holds all traffic approaches red while five LEDs display
 crossing             the crossing countdown.
 Night mode           Flashes all yellow indicators together under low-light
conditions.

<!-- Source PDF page 7 of 34 -->

Return to Normal     Requires sustained brightness before leaving Night
 mode                 mode.

### 2.3 Design Requirements
The assignment requires correct vehicle sequencing, transitional yellow, all-red
clearance, deferred pedestrian service, a five-second countdown and light-
dependent Night mode.
The supplied implementation addresses several of these functions. Differences
between the final source and the assignment requirements are identified in the
discussion rather than being presented as successful features without supporting
evidence.

## 3. HARDWARE DESIGN AND IMPLEMENTATION
### 3.1 Components Used
Table 1. Hardware components
 Component               Quantity     Purpose
 Arduino Uno with        1            Executes the Assembly firmware and
 ATmega328P                           interfaces with inputs and outputs.
 Traffic module          4            Provides red, yellow and green
indications at the four approaches.
 LDR sensor              1            Detects ambient-light conditions.
 Countdown LED           5            Displays the remaining pedestrian
crossing time.
 330 Ω resistor          5            Limits current through the countdown
LEDs.
 Pedestrian button       1            Generates a crossing request.
 switch
 9 V battery             1            Supplies power to the model.
 LM2596 buck             1            Steps the battery voltage down to
 converter                            nominally 5 V.

<!-- Source PDF page 8 of 34 -->

60 × 60 cm Regiform      1           Supports the junction layout and
 base                                 components.
 Connecting wires         As          Provides electrical connections between
required    the components.

### 3.2 Microcontroller Selection
The Arduino Uno provides the ATmega328P controller required by the
assignment. Its digital ports support the traffic modules and countdown LEDs,
while ADC0 supports the LDR input.
Timer1 provides a hardware timing resource for the programmed intervals. The
source assumes a 16 MHz CPU clock.
Although the Uno board is used, the application logic is implemented through
AVR Assembly instructions and direct register manipulation.
### 3.3 Traffic Module Arrangement
One traffic module is mounted at each approach.
The North and South modules receive the same logical signal states. The East
and West modules form the opposing pair. This arrangement allows four traffic
heads to be controlled using six output signals.
The program uses active-high output masks: a HIGH bit selects the
corresponding traffic indication.
The five separately identified external resistors belong to the countdown
display. The traffic modules are treated as assembled components; their internal
circuit details were not characterised during the visual evaluation.
### 3.4 Pin-to-Port Mapping
Table 2. Pin allocation
 Function                       ATmega328P port          Arduino Uno pin
 Pedestrian button              PD0                      D0
 North-South red                PD1                      D1
 North-South yellow             PD2                      D2
 North-South green              PD3                      D3

<!-- Source PDF page 9 of 34 -->

East-West red                  PD4                       D4
 East-West yellow               PD5                       D5
 East-West green                PD6                       D6
 Countdown LED 1                PB0                       D8
 Countdown LED 2                PB1                       D9
 Countdown LED 3                PB2                       D10
 Countdown LED 4                PB3                       D11
 Countdown LED 5                PB4                       D12
 LDR sensor output              PC0/ADC0                  A0
 Regulated power input          5V                        Uno 5V pin
 Common reference               GND                       Uno GND
D0 and D1 also have serial-interface functions on the Uno. In this application,
they are assigned to the pedestrian input and a traffic output.
### 3.5 Pedestrian Button
The pedestrian button is connected between PD0 and ground.
PD0 is configured as an input, and its internal pull-up resistor is enabled. The
resulting logic is:
   •   Button released: HIGH.
   •   Button pressed: LOW.
The pull-up prevents the released input from floating. Software checks confirm
the press before recording the request.
### 3.6 Countdown Display
The countdown display contains five LEDs connected to PB0–PB4. Each LED
has a separate 330 Ω current-limiting resistor.
All five LEDs illuminate at the beginning of the crossing interval. One LED
turns off after each nominal one-second interval.
The sequence provides a direct visual indication of the remaining time:
5 LEDs → 4 LEDs → 3 LEDs → 2 LEDs → 1 LED → all LEDs off
The all-off state represents zero remaining time.

<!-- Source PDF page 10 of 34 -->

### 3.7 Current-Limiting Resistors
The LED current is approximately determined by:
ILED = (Vdrive − VF) / R
For the countdown display:
R = 330 Ω
The actual current depends on the LED forward voltage and the loaded
microcontroller output voltage.
The resistors limit the current through the LEDs and reduce the load on the
output pins. LED current was not measured during the reported evaluation, so
no measured current value is claimed.
### 3.8 LDR Sensor
The LDR sensor supplies a light-dependent voltage to A0.
The firmware reads this voltage using the ADC and classifies it as bright or
dark. In the final source, values below the configured threshold indicate
darkness.
During operation, bringing a flashlight near the LDR provides sufficient
brightness for Normal mode. Without sufficient illumination, the controller
operates in Night mode.
The brightness decision is based on an ADC threshold rather than a calibrated
light measurement in lux.
### 3.9 Power Supply
A 9 V battery supplies the LM2596 buck converter. The converter steps the
voltage down to nominally 5 V. The converter output is connected to the
Arduino Uno’s 5V pin, with a common ground between the converter, Uno and
peripheral circuits.
This arrangement provides battery-powered operation without requiring a
computer connection. The reported testing was visual. Converter output
accuracy, current consumption, conversion efficiency and battery runtime were
not measured. The system connection schematic, including the controller pin
assignments and peripheral connections, is presented in Appendix A, Figure A.1

<!-- Source PDF page 11 of 34 -->

### 3.10 Physical Construction
The model is constructed on a 60 × 60 cm Regiform base.
The four approaches converge at the centre of the junction. A traffic module is
placed at each approach, while the pedestrian button and countdown display are
associated with the South crossing.
The Regiform base provides sufficient space for the road layout, wiring and
control components while keeping the model lightweight.

## 4. FIRMWARE ARCHITECTURE
### 4.1 Programming Approach
The firmware is written in AVR Assembly and is organised into labelled
routines for:
   •   Initialisation.
   •   Vehicle green phases.
   •   Normal yellow transitions.
   •   Pedestrian yellow transitions.
   •   Pedestrian countdown.
   •   Night-mode entry.
   •   Night flashing.
   •   Return to Normal mode.
   •   Button polling.
   •   ADC acquisition.
   •   Timer-based delays.
The supplied source uses AVRASM syntax and includes m328pdef.inc.

<!-- Source PDF page 12 of 34 -->

### 4.2 Initialisation Sequence
The RESET routine performs the following operations:
   1. Disables global interrupts using CLI.
   2. Initialises the stack pointer.
   3. Configures PB0–PB4 as countdown outputs.
   4. Turns off the countdown LEDs.
   5. Configures PD1–PD6 as traffic outputs.
   6. Configures PD0 as the button input.
   7. Enables the button pull-up.
   8. Selects an all-red traffic output.
   9. Configures ADC0.
   10.Clears the working flags and counters.
   11.Reads the initial light condition.
   12.Selects the startup operating mode.
In bright conditions, the program applies a nominal one-second all-red interval
before starting North-South green. If darkness is detected, it enters Night mode.
### 4.3 Register Allocation
Table 3. Working registers
 Register     Purpose
 r16          Temporary values for peripheral access and port output
 r17          Remaining number of phase timing intervals
 r18          Night flash counter and one-second delay counter
 r19          Pending pedestrian request
 r20–r22      Software debounce counters
 r23          Night yellow ON/OFF state
 r24          ADC value read from ADCH
 r25          Interpreted light condition

<!-- Source PDF page 13 of 34 -->

r26              Consecutive bright-sample counter
 r27              Button-held latch

### 4.4 Digital Port Configuration
The program writes:
DDRB = 0x1F
This configures PB0–PB4 as outputs.
It also writes:
DDRD = 0x7E
This configures PD1–PD6 as outputs while leaving PD0 as an input.
Traffic output masks preserve bit 0 of PORTD as HIGH so that the button pull-
up remains enabled.
### 4.5 Timer1 Configuration
The DELAY_100MS routine uses Timer1 in Clear Timer on Compare Match
mode.
The configuration is:
   •   CPU clock: 16 MHz.
   •   Prescaler: 64.
   •   Compare value: OCR1A = 24999.
The timer clock is:
ftimer = 16,000,000 / 64 = 250,000 Hz
The nominal interval is:
T = (OCR1A + 1) / ftimer
T = (24999 + 1) / 250,000 = 0.100 s
The routine clears the compare flag, starts the timer and waits until the compare
event occurs. It then stops the timer and returns.
The complete elapsed time between application events also includes instruction
execution and other processing.

<!-- Source PDF page 14 of 34 -->

### 4.6 ADC Configuration
The ADC is configured with:
   •   AVCC as the reference.
   •   ADC0 as the selected channel.
   •   Left-adjusted results.
   •   A prescaler of 128.
The ADC clock is:
fADC = 16,000,000 / 128 = 125,000 Hz
The CHECK_LIGHT routine starts a conversion, waits for completion and
reads ADCH.
The decision threshold is:
   •   ADCH < 125: dark.
   •   ADCH ≥ 125: bright.
For a nominal 5 V reference, this corresponds approximately to:
Vthreshold = (125 / 256) × 5 ≈ 2.44 V
### 4.7 Polling Architecture
The supplied implementation uses polling.
The program polls:
   •   The Timer1 compare flag.
   •   The ADC conversion status.
   •   The pedestrian input.
No interrupt service routine is present, and global interrupts remain disabled.
Therefore, the implementation is accurately described as hardware-timer-
based with polled event handling. Timer events and input conditions are
handled by polling, while global interrupts remain disabled.

<!-- Source PDF page 15 of 34 -->

## 5. OPERATING SEQUENCES
### 5.1 Traffic Output Masks
Table 4. PORTD output values
PORTD value Traffic indication
0x19             North-South green; East-West red
0x43             North-South red; East-West green
0x15             North-South yellow; East-West red
0x23             North-South red; East-West yellow
0x13             All approaches red
0x25             All approaches yellow
0x01             All traffic indicators off
The HIGH value of bit 0 maintains the pedestrian-input pull-up.
### 5.2 Timing Constants
Table 5. Nominal timing values in the final source
Constant or operation               Timing intervals         Nominal
duration
GREEN_TICKS                         100                      10 s
YELLOW_TICKS                        30                       3s
ALL_RED_TICKS                       10                       1s
NIGHT_TRANSITION_TICKS 50                                    5s
NIGHT_RETURN_TICKS                  50 consecutive bright    Approximately 5
samples                  s
BLINK_HALF_TICKS                    5                        0.5 s
Complete countdown                  Five one-second stages   5s

<!-- Source PDF page 16 of 34 -->

### 5.3 Normal Traffic Cycle
Under bright conditions, the no-request sequence in the final source is:
1. North-South green and East-West red for nominally 10 seconds.
2. All yellow indicators on for nominally 3 seconds.
3. East-West green and North-South red for nominally 10 seconds.
4. All yellow indicators on for nominally 3 seconds.
5. Repeat.
Table 6. Actual no-request Normal-mode sequence
 Phase North-South East-West Nominal duration
 1         Green           Red          10 s
 2         Yellow          Yellow       3s
 3         Red             Green        10 s
 4         Yellow          Yellow       3s
The nominal cycle duration is:
Tcycle = 10 + 3 + 10 + 3 = 26 s
The final source does not insert a separate all-red clearance into this normal
sequence. This differs from the assignment requirement.
### 5.4 Pedestrian Request Recognition
The POLL_BUTTON routine checks PD0.
If the button is released, the held-button latch is cleared. If the button is pressed
and has not already been recorded, a short software delay is applied before
checking the input again.
A confirmed press sets:
•   r19 = 1: pending pedestrian request.
•   r27 = 1: current press already recognised.
The request flag stores one pending crossing rather than a count of all presses.

<!-- Source PDF page 17 of 34 -->

### 5.5 Deferred Pedestrian Operation
During a green phase, a recognised request does not immediately change the
outputs.
The current green interval finishes. The program then applies yellow to the
active vehicle group while the opposing group remains red for nominally three
seconds.
After this transition, PEDESTRIAN_CROSSING is called.
The routine sets all four traffic modules to red and begins the five-second
countdown.
In the supplied source, there is no additional all-red waiting interval between the
end of pedestrian yellow and the beginning of the countdown.
### 5.6 Countdown Sequence
Table 7. Pedestrian countdown
 Elapsed time Remaining time PB4–PB0 LEDs illuminated
 0s              5s                 11111        5
 1s              4s                 01111        4
 2s              3s                 00111        3
 3s              2s                 00011        2
 4s              1s                 00001        1
 5s              0s                 00000        0
The all-red traffic output remains active throughout the countdown routine.
The button and LDR are not polled during these five blocking countdown
stages.
### 5.7 Return After Pedestrian Crossing
For a crossing served from the North-South green path, the program proceeds to
East-West green.
For a crossing served from the East-West green path, it proceeds to North-South
green.
The selected green routine checks the light condition on entry, so a return to
vehicle operation also depends on the current light status.

<!-- Source PDF page 18 of 34 -->

### 5.8 Darkness During Green
When darkness is detected during green, the program enters the corresponding
Night-entry routine.
That routine:
   1. Clears the pending pedestrian request.
   2. Turns off the countdown display.
   3. Applies yellow to the previously active group for nominally five seconds.
   4. Applies all red for nominally one second.
   5. Enters Night mode.
Darkness detected during a normal yellow phase enters Night mode directly.
Therefore, Night-entry behaviour depends on the state in which darkness is
recognised.
### 5.9 Night Flashing
Night mode alternates between:
   •   All yellow indicators on.
   •   All traffic indicators off.
The yellow state toggles after five nominal 100 ms intervals.
Therefore:
Ton = 5 × 0.100 = 0.5 s
Toff = 5 × 0.100 = 0.5 s
Tperiod = 1 s
fflash = 1 Hz
The nominal duty cycle is 50%.
### 5.10 Brightness Qualification
The program counts consecutive bright samples in r26.
Each bright sample increments the counter. Any dark sample resets it to zero.
When the count reaches 50, the program begins the Night-to-Day transition.
This implements time-based brightness qualification using one ADC threshold.
It prevents a single bright sample from immediately restoring Normal mode.

<!-- Source PDF page 19 of 34 -->

### 5.11 Night-to-Day Transition
The NIGHT_TO_DAY routine applies all red for nominally one second and
then checks the LDR again.
If the input is still bright, the program starts North-South green. If darkness has
returned, the controller returns to Night mode.
This explains why bringing a flashlight near the LDR does not require an
immediate change: sustained brightness must first satisfy the qualification
period.
### 5.12 Pedestrian Input During Night Mode
The final source polls the pedestrian button during Night mode.
A recognised request calls the same all-red countdown routine and then returns
to Night mode. This differs from the assignment’s permitted alternatives of
ignoring the request or deferring it until Normal mode resumes.
The source behaviour is documented here so that the report remains consistent
with the submitted program.

## 6. STATE MACHINE AND SUBROUTINE FLOWCHARTS
### 6.1 Overall Operating State Machine
The following diagram summarises the operating modes of the final source. The
detailed green and yellow paths are described in Section 5.
Figure 1. Overall operating states of the supplied firmware.

<!-- Source PDF page 20 of 34 -->

### 6.2 Normal Phase Cycling

Figure 2. Main Normal-mode phase selection. Light checks also occur inside the yellow routines, with
the transition paths described in Section 5.

<!-- Source PDF page 21 of 34 -->

### 6.3 Button Polling
Figure 3. Pedestrian input recognition and held-button suppression.

<!-- Source PDF page 22 of 34 -->

### 6.4 Night Detection and Brightness Qualification
Figure 4. Night-mode input handling and brightness qualification.

<!-- Source PDF page 23 of 34 -->

### 6.5 Countdown Routine

Figure 5. Functional representation of the unrolled five-stage countdown routine.

<!-- Source PDF page 24 of 34 -->

## 7. TESTING AND RESULTS
### 7.1 Evaluation Method
The model was evaluated by visual observation.
The main checks involved:
   •   Bringing a flashlight near the LDR.
   •   Removing sufficient illumination to produce Night mode.
   •   Pressing the pedestrian button.
   •   Watching the traffic indications.
   •   Watching the countdown LEDs turn off.
   •   Observing the subsequent return to operation.
### 7.2 Visual Observations
Table 8. Reported visual results
Test condition             Observed behaviour            Evaluation
Flashlight brought         The controller operated in    Light-dependent
near the LDR               Normal traffic mode.          Normal operation
observed.
LDR without                The controller operated in    Low-light mode
sufficient illumination    Night mode.                   selection observed.
Pedestrian button          The traffic modules changed   All-red pedestrian
pressed during             to red before the countdown   indication observed.
daytime operation          display operated.
Countdown active           The five LEDs reduced         Countdown
progressively until the       progression
crossing interval ended.      observed.
Daytime crossing           The controller returned to    Return to vehicle
completed                  Normal operation under        operation observed.
bright conditions.

<!-- Source PDF page 25 of 34 -->

These observations establish the visible operation of the principal functions.
They do not independently verify every timing and boundary condition in the
marking scheme.
Figure 6. Normal traffic operation showing one vehicle group receiving green while the opposing
group remains red.

Figure 7. Pedestrian crossing operation showing red traffic indications and the illuminated five-LED
countdown display.

<!-- Source PDF page 26 of 34 -->

Figure 8. Yellow-indicator state of the junction model with the pedestrian countdown LEDs switched
off.

The completed prototype was evaluated through visual observation during
practical demonstrations. The system operated consistently with the final
Assembly program, including Normal mode under sufficient illumination, Night
mode under reduced illumination, and pedestrian crossing with all-red traffic
indications and a five-LED countdown. No conflicting operation was observed
during these demonstrations. Operating intervals are reported as nominal values
derived from the program because instrument-based timing measurements were
not performed.
### 7.3 Nominal Timing Evaluation
Table 9. Calculated timing values
Parameter                     Nominal value           Basis
Timer interval                100 ms                  Timer1 prescaler and OCR1A
Vehicle green                 10 s                    100 timer intervals
Normal yellow                 3s                      30 timer intervals
Daytime no-request            26 s                    Two green and two normal-
cycle                                                 yellow phases

<!-- Source PDF page 27 of 34 -->

Pedestrian countdown 5 s                          Five one-second delay stages
Night yellow ON            0.5 s                  Five timer intervals
Night yellow OFF           0.5 s                  Five timer intervals
Night flash frequency      1 Hz                   One-second nominal period
Brightness                 Approximately 5        50 consecutive bright samples
qualification              s
Night exit all red         1s                     Ten timer intervals

### 7.4 Evaluation Against the Assignment
Table 10. Requirement assessment
Assignment           Evidence from the final          Assessment
area                 code and visual
observations
Normal vehicle       Under sufficient                 Implemented in the code and
cycling              illumination, North–South        reported as visually
and East–West alternate as       observed.
paired traffic groups.
Phase timing         Timer1 provides nominal          Timing is hardware-timer-
100 ms intervals used to         based. Exact timing accuracy
generate the programmed          was not measured using
phase durations.                 instruments.
Transitional         During normal transitions,       Yellow transitions are
yellow               both groups display yellow.      implemented, but normal
When servicing a pedestrian      operation does not maintain
request, the active group        the opposing group at red
displays yellow while the        during yellow.
opposing group remains
red.
All-red              The normal sequence              A separate all-red clearance
clearance            proceeds from the yellow         between normal directional
between normal       state directly to the next       changes is absent.
phases               group’s green state.

<!-- Source PDF page 28 of 34 -->

Deferred          A recognised button press       Deferred handling during
pedestrian        sets a request flag. Under      green is implemented.
request during    continuing bright
green             conditions, the current
green interval finishes,
followed by yellow, before
crossing begins.
Pedestrian        The yellow-phase loops do       A press that begins and ends
request during    not call the button-polling     entirely during yellow can be
yellow            routine.                        missed. A press held into the
following green phase may
be detected then.
Clearance         The crossing routine            All-red operation is
before            activates all-red outputs and   implemented, but the
pedestrian        immediately starts the          separate clearance interval
countdown         countdown.                      required before the crossing
window is absent.
All-red           All four traffic modules        Implemented in the code and
indication        remain red throughout the       reported as visually
during crossing   pedestrian countdown.           observed.
Five-second       The LED sequence is five,       Implemented in the code and
countdown         four, three, two, one and       reported as visually
then zero illuminated LEDs,     observed. Exact elapsed time
using nominal one-second        was not measured.
delays.
Multiple presses A single pending-request         Request suppression is
and held-button flag combines recognised          implemented. A dedicated
suppression      presses into one pending         repeated-press test was not
crossing. A held-button          documented.
latch prevents continuous
holding from repeatedly
registering a request.
Requests during   The button is not polled        Presses occurring entirely
crossing and      during the countdown. After     during crossing are not
subsequent        crossing, a new request can     queued. There is no explicit
lockout           be recorded during the next     lockout preventing a new
request from being recorded

<!-- Source PDF page 29 of 34 -->

green phase following a        until one complete vehicle
detected release.              phase has passed.
Resumption of      After a daytime pedestrian     The correct next paired
normal traffic     crossing, the program          group is selected in the code.
selects the opposite vehicle
group, provided lighting
conditions permit Normal
mode.
Night-mode         Both groups’ yellow outputs    Night operation was reported
flashing           toggle after five nominal      as visually observed. The
100 ms intervals, producing    programmed frequency is
nominal 0.5-second ON and      nominally 1 Hz; exact
OFF periods.                   frequency was not measured.
Sustained          The program requires 50        A nominal five-second
brightness         consecutive bright samples     brightness qualification is
before returning   in the nominal 100 ms          implemented. Its exact
to Normal mode     Night-mode loop before         duration was not
beginning the return           independently measured.
transition.
Reset of           A dark sample clears the       Implemented in the code. A
brightness         brightness counter,            separate brief-uncover-and-
qualification      requiring the bright-sample    recover test was not
sequence to restart.           documented.
Pedestrian         A recognised request           This is the implemented
requests during    activates an all-red           behaviour. It differs from the
Night mode         countdown, after which         assignment’s requirement to
Night mode restarts.           ignore the request or defer it
until Normal mode resumes.

<!-- Source PDF page 30 of 34 -->

### 7.5 Interpretation of Results
Visual testing demonstrated successful integration of the controller, traffic
modules, LDR sensor, pedestrian button and countdown display. The prototype
responded to changes in illumination and pedestrian requests according to the
final Assembly program, demonstrating the main operating functions of the
system.
Assessment against the assignment requirements also identified specific
limitations in clearance sequencing and pedestrian request handling. These
findings distinguish the functions demonstrated during testing from
requirements that still need refinement. The prototype therefore provides a
working foundation for further development, with clear priorities for improving
sequence control, input responsiveness and overall compliance.

## 8. DISCUSSION
### 8.1 Hardware Integration
The project combines the controller, four traffic modules, countdown display,
LDR and button into one battery-powered model.
The LM2596 converter allows the 9 V battery to supply the nominal 5 V rail.
The 60 × 60 cm Regiform base provides a suitable physical layout for
demonstrating the four approaches and pedestrian crossing.
The countdown arrangement uses only five LEDs and five 330 Ω resistors,
making the remaining-time indication easy to follow visually.
### 8.2 Timer-Based Operation
Timer1 provides a hardware reference for the operating intervals.
Nevertheless, the program repeatedly starts and stops the timer and performs
additional operations between waits. ADC conversion, input polling, debounce
and other instructions increase the elapsed time beyond the nominal timer
interval alone.
Consequently, exact timing accuracy cannot be concluded from the programmed
constants or visual observation.

<!-- Source PDF page 31 of 34 -->

### 8.3 Polling and Input Responsiveness
Polling makes the execution sequence easy to follow, but input recognition
depends on when the relevant routine is called.
The pedestrian input is checked during green and Night mode. It is not checked
during the yellow loops or pedestrian countdown.
This creates a risk of missing short presses during yellow. A periodic event-
handling structure would provide more consistent input capture.
### 8.4 Pedestrian Handling
The source correctly separates request recognition from immediate traffic output
changes during green.
The countdown routine also maintains all-red outputs while the LEDs turn off.
However, the assignment requires a separate all-red clearance before the
crossing window. In the supplied code, all red and the countdown start together.
The held-button latch prevents repeated recognition of a continuously held
press, but it does not implement an explicit full-vehicle-phase lockout after
crossing.
### 8.5 Night-Mode Behaviour
The consecutive-bright-sample counter provides temporal filtering before
Normal mode resumes.
Dark samples reset the counter, helping prevent an immediate exit caused by a
brief change in illumination.
The current Night-mode button path grants a crossing and then returns to Night
mode. Although this produces a visible all-red countdown, it is different from
the assignment’s specified ignore-or-defer choice.
### 8.6 Documentation and Toolchain Requirements
The source contains timing constants rather than a phase table stored in program
memory. A table in the written report does not replace this firmware
requirement.
The code also uses AVRASM syntax. Compatibility with AVR-GCC/avr-as has
not been demonstrated by the available evidence.
These points must be distinguished from the successful operation of the flashed
model.

<!-- Source PDF page 32 of 34 -->

## 9. CONCLUSION
The Smart Traffic Junction Controller demonstrated the practical application of
AVR Assembly programming to a working four-way traffic junction model
using the Arduino Uno and ATmega328P. The system integrated four traffic
modules, an LDR sensor, a pedestrian push-button and a five-LED countdown
display to provide coordinated vehicle signalling, light-dependent mode
selection and pedestrian crossing operation. Visual testing showed that the
prototype responded to changes in illumination and pedestrian requests
according to the final program, with all four traffic modules displaying red
during the crossing countdown. These results demonstrate the integration of
digital input/output control, ADC sensing and hardware-timer-based sequencing
within an embedded system.
The project also established the importance of evaluating a working prototype
against each design requirement. Although the main operating functions were
demonstrated, full assignment compliance requires improvements to clearance
intervals, button detection during yellow, pedestrian request handling in Night
mode and the specified firmware architecture. Instrument-based measurements
would also be needed to verify timing accuracy beyond visual observation. The
completed prototype therefore provides a practical foundation for further
development while strengthening understanding of register-level programming,
hardware–software integration and systematic testing.

## 10. INDIVIDUAL CONTRIBUTIONS
Table 11. Division of individual responsibilities
 Group            Student ID     Responsibilities
 member
 U.               IT24101646 Pedestrian crossing operation and five-LED
 Lathussoban                 countdown.
 M. Lahinth       IT24103482 Normal traffic operation and Night mode.

U. Lathussoban: Pedestrian Crossing Subsystem
U. Lathussoban was responsible for the pedestrian crossing subsystem. His
responsibilities included pedestrian button handling, deferred crossing requests,
all-red traffic indication during crossing, the five-LED countdown and the
return to vehicle operation after crossing.

<!-- Source PDF page 33 of 34 -->

M. Lahinth: Normal and Night Modes
M. Lahinth was responsible for Normal traffic operation and Night mode. His
responsibilities included vehicle signal sequencing, LDR-based light detection,
simultaneous yellow flashing during Night mode and sustained-brightness
detection before returning to Normal mode.

## 11. REFERENCES
[1] Sri Lanka Institute of Information Technology, IE3064 Embedded Systems
Engineering: Smart Traffic Junction Controller Assignment, Year 3, Semester 1,
July 2026. Course assignment brief.
[2] Microchip Technology Inc., ATmega48A/PA/88A/PA/168A/PA/328/P Data
Sheet, document DS40002061B, 2020. [Online]. Available: Microchip
datasheet. Accessed: Nov. 14, 2026.
[3] Arduino, Arduino Uno Rev3 Pinout, Oct. 13, 2021. [Online]. Available:
Arduino Uno Rev3 pinout. Accessed: Nov. 14, 2026.
[4] GNU Binutils, Using as: The GNU Assembler. [Online]. Available: GNU
assembler documentation. Accessed: Nov. 14, 2026.

<!-- Source PDF page 34 of 34 -->

## APPENDIX A: SYSTEM CONNECTION SCHEMATIC
Figure A.1. System connection schematic of the Smart Traffic Junction Controller, showing the
 Arduino Uno, four traffic modules, LDR sensor interface, pedestrian button, five-LED countdown
display and LM2596-regulated power supply.
