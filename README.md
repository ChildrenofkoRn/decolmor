# Decolmor
[![badge-gem][badge-gem]][gem]
[![badge-build][badge-build]][github-workflow]
[![badge-codecov][badge-codecov]][codecov]
[![badge-license][badge-license]][license]

Gem for converting color spaces from/to: HEX/RGB/HSL/HSV/HSB/HSI/CMYK  
The Alpha channel (transparency) is supported.  
There is also a simple RGB generator.  

[News][news] . [Recent releases][releases] . [Changelog][changelog] . [Wiki][wiki]

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

See [WIKI](https://github.com/ChildrenofkoRn/decolmor/wiki/Examples) for more examples.

## Rounding for HSL/HSV/HSB/HSI/CMYK
By default, rounding 1 is used to convert to HSL/HSV/HSB/HSI/CMYK.  
This is enough to loselessly convert RGB -> HSL/HSV/HSB/HSI/CMYK -> RGB:
 * _for HSI this is not quite true ~2k (of 16.6M) RGB colors will be slightly different, rounding 2 fixes this._
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

## HEX to
 - with & without prefix `#`
 - short HEX are supported (including Alpha)
 - can be set rounding for the Alpha channel

## Alpha channel
When converting from HEX to RGBA Alpha channel is converted to a value from the range `0..1` with rounding 3:  
 - 3 digits is enough for a lossless conversion `0..255` -> `0..1` -> `0..255`
```ruby
    Decolmor.hex_to_rgb('#19988BB8')           # => [25, 152, 139, 0.722]
    Decolmor.hex_to_rgb([25, 152, 139, 0.722)  # => "#19988BB8"
```
Consequently, when converting to HEX from RGBA, Alpha from the range `0..1` is assumed.  
But you can set range 0..255 for alpha channel:
```ruby
    Decolmor.hex_to_rgb('#19988BB8', alpha_255: true)          # => [25, 152, 139, 184]
    Decolmor.rgb_to_hex([25, 152, 139, 184], alpha_255: true)  # => "#19988BB8"
```
You can also set rounding for Alpha channel as a second argument:
```ruby
    Decolmor.hex_to_rgb('#19988BB8', 2)  # => [25, 152, 139, 0.72]
```
This only works for converting from HEX.  
In other cases (conversions between RGB/HSL/HSV/HSB/HSI/CMYK) Alpha channel remains unchanged.

## HSL, HSI, HSV or HSB
**HSL**, **HSI**, **HSV** - are three _different_ color spaces.  
They have only one common parameter **HUE**.    
**S** - **Suturation**, despite the same name, is _different_ in all three spaces,  
like the last component: **Lightness** / **Intensity** / **Value** (**Brightness**).

**HSB** is an alternative name for **HSV**, it is the same thing.  
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

The results of the two implementations are identical, but the alternative versions (postfix `_alt`) are slightly slower.

## Attention for CMYK !
Unfortunately, there is no simple formula for linear RGB to/from CMYK conversion.  
This implementation is a simplified/dirty/simulation.  
CMYK is used for printing and the correct conversion will be non-linear, based on the color profile for the particular printing device.  
Therefore, the CMYK conversion results will not match Adobe products.  
**BUT:**  
Conversion from/to HEX/RGB/HSL/HSV/HSB/HSI is simple and is described by formulas.  
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
 - RGB(A) to HSL/HSV/HSB/HSI
   - rgb_to_hsl
   - rgb_to_hsv
   - rgb_to_hsb
   - rgb_to_hsi
 - HSL/HSV/HSB/HSI to RGB(A)
   - hsl_to_rgb
   - hsv_to_rgb
   - hsb_to_rgb
   - hsi_to_rgb
 - Alternative implementation HSL/HSV/HSB to RGB(A) (a little slower)
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
 - HEX => HSL/HSV/HSB/HSI/CMYK
   - hex_to_hsl
   - hex_to_hsv
   - hex_to_hsb
   - hex_to_hsi
   - hex_to_cmyk
 - HSL/HSV/HSB/HSI/CMYK => HEX 
   - hsl_to_hex
   - hsv_to_hex
   - hsb_to_hex
   - hsi_to_hex
   - cmyk_to_hex

## License
MIT License  
Copyright (c) 2021 ChildrenofkoRn  
[LICENSE](https://github.com/ChildrenofkoRn/decolmor/blob/master/LICENSE)



  [gem]: https://rubygems.org/gems/decolmor "gem version"
  [badge-gem]: https://img.shields.io/gem/v/decolmor?color=bri&label=gem%20version&logo=ruby&logoColor=f01f7a "gem version"
  [codecov]: https://codecov.io/gh/ChildrenofkoRn/decolmor "codecov"
  [badge-codecov]: https://codecov.io/gh/ChildrenofkoRn/decolmor/branch/main/graph/badge.svg?token=5P4OQUXC3N "codecov"
  [github-workflow]: https://github.com/ChildrenofkoRn/decolmor/actions/workflows/build.yml "build"
  [badge-build]: https://img.shields.io/github/workflow/status/ChildrenofkoRn/decolmor/build/main "build status"
  [license]: https://github.com/ChildrenofkoRn/decolmor/blob/main/LICENSE "MIT"
  [badge-license]: https://img.shields.io/github/license/ChildrenofkoRn/decolmor?color=%23239393 "license"


  [changelog]: https://github.com/ChildrenofkoRn/decolmor/blob/main/CHANGELOG.md "changelog"
  [news]: https://github.com/ChildrenofkoRn/decolmor/blob/main/NEWS.md "news"
  [releases]: https://github.com/ChildrenofkoRn/decolmor/releases "releases"
  [wiki]: https://github.com/ChildrenofkoRn/decolmor/wiki "wiki"
