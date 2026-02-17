# SenCar Change Logs

  

SenCar has undergone a lot of changes. These are all of the updates to SenCar 5 after the public release with Solstice RT

  

## Contents

1. [v5.0](#v5.0)

1. [v5.0.1](#v5.0.1)

2. [v5.0.2](#v5.0.2)

3. [v6.0](#v6.0)
  

## v5.0
DEC 23, 2022
The public release of SenCar 5. Starts at 5.0 because it's still technically a version of the old SenTOS Car system, just heavily updated.

  

### v5.0.1
JAN 4, 2023
**Lua:**
- Feature - Added transmission modifiers to `drivemodes.lua`
- Fix - Widget Display now obeys the laws of the Unit. (Widget Display can now use Metric.)
- Fix - Changed app build versions to release because I forgor

**Micro:**
- Fix - Removed the tooltips

### v5.0.2
MAR 20, 2023
**Lua:**
- Fix - Doors open display wouldn't update theme when manually changed

## v6.0
The full release notes for SenCar 6 can be found [here](./car6logfull.md)

### v6.1
- Feature - Hotkey 3 to flash high beams
- Feature - Added new Total Time and Trip Time values to Info app to keep track of time the car has been on
- Rework - Added check engine light when Extras MC is damaged
- Rework - Odometer now preserves value when car gets reloaded
- Fix - Extra options would incorrectly enable if the Extras micro was damaged on non-equipped car

### v6.1.1
- Feature - Added rear distance to reverse camera (If equipped)
- Feature - Added charging indicator to dash (EV only) - Battery icon/percentage turns green

### v6.2
**Lua:**
- Feature - Now monitors various scripts and microcontrollers and will display a warning if any script or controller encounters a fault
- Rework - Rear distance only shows below 50 meters
- Rework - Reorganized Car app options to be in alphabetical order
- Fix - Fixed incorrectly allowing app touch inputs in the reserved screen areas
- Fix - Fixed formatting issue with speed in metric in reverse in Modern and Round dash layout

**Micro:**
- Feature - Cruise Control speed adjustment/resuming. Hold CC button (2 by default) to resume previous cruise speed, use arrow keys to adjust speed while in cruise.