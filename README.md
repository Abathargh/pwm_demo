## PWM demo in nim

This is a simple PWM demo in nim, using `avr_io` and an Arduino Uno REV3.

## Requirements

- nim >= 2.0.6
- avr_io >= 0.3.0
- an Arduino Uno, and a couple of push buttons/LED
  - the `up` button is connected on PIN8
  - the `down` button is connected on PIN10
  - the LED is connected on PIN9

## Build & Run

```bash
nimble build && nimble flash
```

## License

BSD-3