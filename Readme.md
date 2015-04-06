I want to have head tracking in Elite Dangerous Mac OS X.

This is a work in progress to integrate Hatire -protocol using serially-linked head tracker,
opentracker for curve filtering and ControllerMate for virtual joystick axis mapping
for getting head tracking to work in Elite Dangerous Mac Os X port.

I have a DIY head tracking using gyros and outputting gyroscopic data in HATire frame format
over Bluetooth.

Using Wine I can get curves filtering and Accela filter to work by sending UDP packets to and from Opentracker.

TODO:
UDP packets are sent to ControllerMate using MIDI, which maps the MIDI signal to virtual joystick axes.


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
