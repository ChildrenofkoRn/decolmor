# Changelog

## 1.3.0 (September 27, 2021)

  * Added support HSI <==> RGB  
  > _RGB => HSI when rounding 1 ~2k RGB colors will be slightly different, 2 will fix this_
  * Added methods for HEX <==> HSL/HSV/HSB/HSI/CMYK
  * Fixed incorrect conversion to RGB when HUE == 360  
    it was about the methods:
    * hsl_to_rgb_alt
    * hsv_to_rgb_alt  
    and new:
    * hsi_to_rgb

## 1.2.0 (September 21, 2021)

  * `.hex_to_rgb` now support a returnable alpha in range `0..255`  
    `.rgb_to_hex` now support incoming alpha in range `0..255`  
    use the option: `alpha_255: true`
  * refactor code for methods:
    - hsl_to_rgb
    - hsv_to_rgb
    - hsb_to_rgb
    - hsl_to_rgb_alt
    - hsv_to_rgb_alt
    - hsb_to_rgb_alt  
    Removed some inaccuracies in the math, which didn't affect the result.  
    Code in the _alt methods became clearer.  
    Improved performance, especially _alt methods  
    (but its still a bit slower than the main methods ~1.3X)

## 1.1.2 (September 16, 2021)

* Migrate: Travis CI => Github Actions Workflow
* Fix: returned helper methods to private
* Now the main code is in one file: lib/decolmor/main.rb  
  You can just `include` it in and use it (separately from the gem)

## 1.1.1 (September 16, 2021)

* Now you can `include` the module into your class
    * gem methods will be available as class methods
* Fixed default branch in .gemspec metadata paths

## 1.1.0 (September 14, 2021)

* .hex_to_rgb
  * change default rounding 5 => 3 for Alpha channel  
    *reason: 3 digits is enough for a lossless conversion `0..255` -> `0..1` -> `0..255`*
  * for the Alpha channel now you can set rounding as the second argument:  
  `Decolmor.hex_to_rgb(hex, 2)`
  * support short version of HEX  
  e.g: `#CF3`, `0F9`, `#0F9F`

## 1.0.0 (September 13, 2021)

* Initial release
