# Full headlook support on OS X on any game

## Requirements

- Node.js (`brew install node`)
- ControllerMate
- Paired bluetooth enabled Head tracker configured to broadcast Hatire protocol with bluetooth

## How to use

`npm install`
`gulp wisp`
`node node_modules/gulp/bin/gulp.js wisp`

Start with:
`node lib/core.js`

Example output:
```
$ node lib/core.js
Found bluetooth device HC-06 [ 10-14-05-22-02-47 ]
Press x to quit. c to center. Press c to start after Serial port is opened.
Connecting to 10-14-05-22-02-47
Connected to 10-14-05-22-02-47
Beginning frame found:  <Buffer aa aa db 01 9f b8 5e 43 10 3d 18 c2 62 e4 48 41 00 00 00 00 00 00 00 00 00 00 00 00 55 55>
```

Pressing `c` to zero the device on current direction:
```
Zeroed to { yaw: 59.28840637207031,
  pitch: -33.5324592590332,
  roll: 18.99624252319336 }
```

## Setting up ControllerMate

Import the provided .cmate file

...  more instructions to be writen ...

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
