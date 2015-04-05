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
