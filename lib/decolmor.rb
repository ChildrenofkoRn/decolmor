require 'decolmor/main'
require 'decolmor/version'

module Decolmor
  #========= Set default rounding for HSL/HSV/HSB/CMYK conversion ========

  # round 1 enough for lossless conversion RGB -> HSL/HSV/HSB -> RGB
  # for lossless conversion HSL <==> HSV (HSB) better to use round 2
  #
  HSX_ROUND = 1
end
