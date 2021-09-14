# Changelog

## 1.0.0 (September 13, 2021)

* Initial release

## 1.1.0 (September 14, 2021)

* ::hex_to_rgb
  * change default rounding 5 => 3 for Alpha channel  
    *reason: 3 digits is enough for a lossless conversion `0..255` -> `0..1` -> `0..255`*
  * for the Alpha channel you can now set rounding as the second argument:  
  `Decolmor::hex_to_rgb(hex, 2)`
  * support short version of HEX  
  e.g: `#CF3`, `0F9`, `#0F9F`
