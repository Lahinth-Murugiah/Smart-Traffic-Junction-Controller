# Implementation notes

This document distinguishes **what the submitted AVR Assembly implementation does** from what the assignment requires. Timing values below are nominal values derived from source constants and Timer1 settings, not independent measurements.

| Area | Submitted implementation | Qualification / difference |
| --- | --- | --- |
| Vehicle phases | Opposing North–South and East–West green phases, ~10 seconds each | Two paired control groups, four physical traffic modules |
| Normal transition | Both yellow groups illuminated for ~3 seconds | Opposite group is not held red; no dedicated all-red clearance |
| Pedestrian input | Debounced active-low button, polled during green | Presses during yellow can be missed |
| Pedestrian countdown | All traffic red during five consecutive ~1-second LED stages | No distinct clearance interval before pedestrian stage |
| Night operation | Simultaneous yellow flashing, 0.5-second on/off nominally | Uses light sensor's ADC threshold |
| Return to normal | 50 consecutive bright samples then ~1-second all-red | Nominal timing; not instrument verified |
| Night-mode button | Starts an all-red crossing then returns to night | Differs from assignment's ignore-or-defer option |
| Event handling | Polling used for ADC, button and Timer1 compare flag | No interrupt-based event-handling subsystem |
| Phase table | Labels and constants in program logic | Requested program-memory phase table absent |
| Assembler | AVRASM with `m328pdef.inc` | GNU `avr-as` compatibility not verified |

### Potential future enhancements

1. Insert a separate all-red clearance interval between each pair of vehicle phases and before pedestrian service.
2. Maintain the opposing group's red indication during the active yellow stage.
3. Capture button input throughout yellow and green, with appropriate event-handling and lockout logic.
4. Conform night-mode pedestrian handling to the assignment's ignore-or-defer requirement.
5. Introduce an assembly program-memory phase table and confirm toolchain compatibility.
6. Measure timing with instrumentation and document validated hardware results.

These are **proposed improvements**, not changes made to the uploaded firmware.

**Source basis:** final report sections 7.4 and 8, supplied Assembly source, assignment brief.
