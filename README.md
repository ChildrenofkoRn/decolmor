# Decolmor
[![Gem Version](https://badge.fury.io/rb/decolmor.svg)](https://badge.fury.io/rb/decolmor)
[![Build Status](https://app.travis-ci.com/ChildrenofkoRn/decolmor.svg?token=ssJ5zvqjK7iZ4F1TaeQn&branch=main)](https://app.travis-ci.com/ChildrenofkoRn/decolmor)
[![codecov](https://codecov.io/gh/ChildrenofkoRn/decolmor/branch/main/graph/badge.svg?token=5P4OQUXC3N)](https://codecov.io/gh/ChildrenofkoRn/decolmor)

Gem for converting color spaces from/to: HEX/RGB/HSL/HSV/HSB/CMYK  
The Alpha channel (transparency) is supported.  
There is also a simple RGB generator.  

## Install
Add the following line to Gemfile:

```ruby
gem 'decolmor'
```
and run `bundle install` from your shell.

To install the gem manually from your shell, run:

```shell
gem install decolmor
```
### Supported Rubies
 - 2.4
 - 2.5
 - 2.6
 - 2.7
 - 3.0

## Using
```ruby
require 'decolmor'

rgb = [29, 128, 86]
Decolmor.rgb_to_hsb(rgb)
=> [154.5, 77.3, 50.2]
```
or `include` into class:
```ruby
class SomeClass
  include Decolmor
end
SomeClass.rgb_to_hsb(rgb)
=> [154.5, 77.3, 50.2]
```
Gem methods will be available as class methods.

## Rounding for HSL/HSV/HSB/CMYK
By default, rounding 1 is used to convert to HSL/HSV/HSB/CMYK.  
This is enough to loselessly convert RGB -> HSL/HSV/HSB/CMYK -> RGB:
```ruby
    rgb = [224, 23, 131]  
    hsl = Decolmor.rgb_to_hsl(rgb)  # => [327.8, 81.4, 48.4]
    hsv = Decolmor.rgb_to_hsv(rgb)  # => [327.8, 89.7, 87.8]
    Decolmor.hsv_to_rgb(hsv)  # => [224, 23, 131]
    Decolmor.hsl_to_rgb(hsl)  # => [224, 23, 131]
```
If you convert between HSL <==> HSV (HSB) with a rounding of 2, you can get more accurate results.  
This can also be useful if you use HSL/HSB for intermediate changes and then go back to RGB.  
You can change rounding globally:
```ruby
    Decolmor.hsx_round = 2
    Decolmor.rgb_to_hsl(rgb)  # => [154.55, 63.06, 30.78]
    Decolmor.hsx_round        # => 2
```
You can also specify rounding as a second argument when calling the method:
```ruby
    Decolmor.rgb_to_hsl(rgb, 3)  # => [154.545, 63.057, 30.784]
```
In this case, the global rounding will be ignored.
If you need to get integers, use 0.

## HEX to RGB(A)
 - with & without prefix `#`
 - short HEX are supported (including Alpha)
 - can be set rounding for the Alpha channel

## Alpha channel
When converting from HEX to RGBA Alpha channel is converted to a value from the range `0..1` with rounding 3:  
 - 3 digits is enough for a lossless conversion `0..255` -> `0..1` -> `0..255`
```ruby
    Decolmor.hex_to_rgb('#19988BB8')  # => [25, 152, 139, 0.722]
```
Consequently, when converting to HEX from RGBA, Alpha from the range `0..1` is assumed.  
You can also set rounding for Alpha channel as a second argument:
```ruby
    Decolmor.hex_to_rgb('#19988BB8', 2)  # => [25, 152, 139, 0.72]
```
This only works for converting HEX to RGBA.  
In other cases (conversions between RGB/HSL/HSV/HSB/CMYK) Alpha channel remains unchanged.

## HSV or HSB
HSB is an alternative name for HSV, it is the same thing.  
However, for convenience, aliasing methods are made for HSB from HSV.
```ruby
    rgb = [255, 109, 55]  
    Decolmor.rgb_to_hsv(rgb)  # => [16.2, 78.4, 100.0]
    Decolmor.rgb_to_hsb(rgb)  # => [16.2, 78.4, 100.0]
```
## HSL/HSV/HSB to RGB conversion
HSL/HSV/HSB to RGB conversion has two implementations, the gem includes both:
- hsl_to_rgb
- hsv_to_rgb
- hsb_to_rgb

or  
- hsl_to_rgb_alt
- hsv_to_rgb_alt
- hsb_to_rgb_alt

The results of the two implementations are identical, but the alternative versions (postfix `_alt`) are ~1.6X slower.

## Attention for CMYK !
Unfortunately, there is no simple formula for linear RGB to/from CMYK conversion.  
This implementation is a simplified/dirty/simulation.  
CMYK is used for printing and the correct conversion will be non-linear, based on the color profile for the particular printing device.  
Therefore, the CMYK conversion results will not match Adobe products.  
**BUT:**  
Conversion to HEX/RGB/HSL/HSV/HSB is simple and is described by formulas.  
Read more: https://en.wikipedia.org/wiki/HSL_and_HSV  
The results when rounded to an integer will be the same as when using graphics editors, such as CorelDRAW or Adobe Photoshop.

## Supported Methods
 - Setter global rounding for conversion to HSL/HSV/HSB/CMYK
   - hsx_round =
 - HEX <==> RGB(A)
   - hex_to_rgb
   - rgb_to_hex
  - Simple generator RGB, you can set any channel(s)
    - new_rgb
 - RGB(A) to HSL/HSV/HSB
   - rgb_to_hsl
   - rgb_to_hsv
   - rgb_to_hsb
 - HSL/HSV/HSB to RGB(A)
   - hsl_to_rgb
   - hsv_to_rgb
   - hsb_to_rgb
 - Alternative implementation HSL/HSV/HSB to RGB(A) (~1.6X slower)
   - hsl_to_rgb_alt
   - hsv_to_rgb_alt
   - hsb_to_rgb_alt
 - HSL <==> HSV (HSB)
   - hsl_to_hsv
   - hsl_to_hsb
   - hsv_to_hsl
   - hsb_to_hsl
 - RGB(A) <==> CMYK
   - rgb_to_cmyk
   - cmyk_to_rgb

## License
MIT License  
Copyright (c) 2021 ChildrenofkoRn  
[LICENSE](https://github.com/ChildrenofkoRn/decolmor/blob/master/LICENSE)
