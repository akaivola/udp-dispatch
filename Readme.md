# Full headlook support on OS X on any game

## Requirements

- ControllerMate
- Paired bluetooth enabled Head tracker configured to broadcast Hatire protocol with bluetooth

## Background

I wanted to have gyro+magnetograph head tracking in Elite Dangerous on Mac OS X.

What resulted is a generic head look support for any game on Mac OS X.

## Implementation

Your bluetooth enabled head tracker is autodiscovered and connected to, provided it is the only paired bluetooth device.

Hatire -protocol is used for raw serial protocol.

Integration to Mac OS X is done using midi protocol directly to ControllerMate.

The head tracking curve is exponentially scaled. small head movements near center are mitigated and looking to the sides and up/down are exaggerated.

## Hatire protocol
```
  0 // HAT structure
  1 typedef struct  {
  2   int16_t  Begin;    // 2  Debut
  3   uint16_t Cpt;      // 2  Compteur trame or Code info or error
  4   float    rot[3];   // 12 [Y, P, R]    gyro
  5   float    trans[3]; // 12 [x, y, z]    translation not implemented
  6   int16_t  End;      // 2  Fin
  7 } _hat;              // total size =30bytes
```

Offset 4, length 12,
4 byte (32-bit) float.

## Bugs

- Reconnecting by pressing `r` does not seek beginning frame properly and output values get way out of range.
