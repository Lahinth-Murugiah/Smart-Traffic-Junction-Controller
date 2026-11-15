# 🚦 Smart Traffic Junction Controller

**Four-way traffic control in pure AVR Assembly — Arduino Uno / ATmega328P**

![Language](https://img.shields.io/badge/Language-AVR%20Assembly-blue) ![Hardware](https://img.shields.io/badge/Microcontroller-ATmega328P-informational) ![Project](https://img.shields.io/badge/Type-Academic%20Prototype-lightgrey)

An embedded-systems demonstration developed for **IE3064 — Embedded Systems Engineering**, BSc (Hons) in Computer Systems Engineering, **Sri Lanka Institute of Information Technology (SLIIT)**. The prototype implements paired traffic-signal sequencing, ambient-light-controlled night operation, and a five-LED pedestrian countdown using register-level programming rather than Arduino libraries.

> **Project status:** Academic demonstration prototype. The repository preserves the submitted firmware and documents differences between its behaviour and the full assignment specification. **Not intended for real-world traffic control.**

## Overview

| | |
| --- | --- |
| **Platform** | Arduino Uno, ATmega328P (16 MHz) |
| **Firmware** | AVR Assembly (Microchip Studio / AVRASM syntax) |
| **Traffic layout** | North–South pair vs East–West pair; four physical signal modules |
| **Timing** | Timer1 CTC compare-match flag, 100 ms nominal tick |
| **Light sensing** | LDR on ADC0 (A0), 8-bit ADCH threshold = 125 |
| **Pedestrian input** | Active-low push button, internal pull-up, software debounce |
| **Countdown** | Five LEDs on PB0–PB4, turning off one per nominal second |
| **Power** | 9 V battery through LM2596 regulator, nominal 5 V, as documented |

## Main functions

**Daytime traffic operation.** North–South and East–West run as opposing pairs, with nominal **10-second green** phases and **3-second yellow** intervals. The current firmware lights both sets of yellow signals in ordinary transitions; a separate regular all-red clearance phase is **not yet implemented**.

**Pedestrian crossing.** During green, a debounced button press sets a pending request. The current green phase completes, the active direction turns yellow, then all signals display red for the **5-second pedestrian countdown**. The five LEDs count down visually from five lit LEDs to none.

**Night mode.** The LDR drives a switch to simultaneous flashing yellow signals at a nominal **1 Hz**. The controller requires approximately **5 continuous seconds of bright samples** before transitioning back to daytime, with a nominal 1-second all-red transition.

**Low-level control.** Firmware configures DDRx/PORTx/PINx, Timer1, ADC and stack pointer directly, and does not use C/C++ or Arduino library calls.

## Hardware pin mapping

| Function | ATmega328P | Uno pin |
| --- | --- | --- |
| Pedestrian button | PD0 | D0 |
| North–South red / yellow / green | PD1 / PD2 / PD3 | D1 / D2 / D3 |
| East–West red / yellow / green | PD4 / PD5 / PD6 | D4 / D5 / D6 |
| Countdown LEDs (five) | PB0–PB4 | D8–D12 |
| LDR signal | PC0 / ADC0 | A0 |

**Wiring note:** Uno pins D0 and D1 are also used for serial communications. Review the project wiring before using the board's programming and serial interfaces.

## Repository contents

```text
Smart-Traffic-Junction-Controller/
├── README.md
├── .gitignore
├── src/
│   └── Smart_Traffic_Junction_Controller.asm
└── docs/
    ├── Final_Report_Text.md
    └── IMPLEMENTATION_NOTES.md
```

- **[Firmware source](src/Smart_Traffic_Junction_Controller.asm)** — complete submitted AVR Assembly source, preserved without logic edits.
- **[Report text](docs/Final_Report_Text.md)** — searchable extraction from the full 34-page final report (original formatted PDF is not included in this GitHub commit).
- **[Implementation notes](docs/IMPLEMENTATION_NOTES.md)** — documented behaviour, limitations and possible improvements.

## Build and hardware setup

1. Install **Microchip Studio** and the AVR assembler/device support for **ATmega328P**.
2. Create a project using the **AVR Assembler** toolchain, targeting ATmega328P.
3. Add [`src/Smart_Traffic_Junction_Controller.asm`](src/Smart_Traffic_Junction_Controller.asm).
4. Ensure **`m328pdef.inc`** is available to the assembler; it is an external device definition, not bundled here.
5. Assemble and flash through a supported AVR programming workflow; confirm power, wiring and peripheral polarity before testing.

The firmware uses **AVRASM syntax**, and its build with GNU `avr-as` has not been verified. The original assignment separately requires that toolchain. The repository does **not** claim a fresh successful build or independently measured timing accuracy.

## Current limitations

The final report and source identify the following differences from the full assignment requirements:

- Ordinary directional changes lack a dedicated all-red clearance interval.
- In normal yellow transitions, both groups are yellow rather than the opposing group staying red.
- Pedestrian polling runs during green, but short presses during yellow intervals can be missed.
- A night-mode button press currently triggers a crossing, although the assignment specifies ignore or defer.
- Button handling and timer waits are polling-based, not interrupt-driven.
- A program-memory traffic-phase lookup table is not implemented.

See **[Implementation notes](docs/IMPLEMENTATION_NOTES.md)** and **Section 7.4** of the report for the requirement-by-requirement comparison. Planned improvements should not be mistaken for implemented functionality.

## Contributors

- **M. Lahinth** — normal vehicle signal sequencing and ambient-light-based night mode.
- **U. Lathussoban** — pedestrian request and countdown subsystem.

**Academic year:** 2026 · **Group:** 14 · **Module:** IE3064

## Attribution and intended use

Educational project documentation and source code only. No open-source reuse license has been granted. This is not a certified traffic-safety controller. Respect the university's academic-integrity requirements and the authors' rights.
