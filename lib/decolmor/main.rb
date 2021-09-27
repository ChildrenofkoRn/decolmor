module Decolmor

  def self.included(base)
    base.extend ClassMethods
  end

  #========= Set default rounding for HSL/HSV/HSB/CMYK conversion ========

  # round 1 enough for lossless conversion RGB -> HSL/HSV/HSB -> RGB
  # for lossless conversion HSL <==> HSV (HSB) better to use round 2
  #
  HSX_ROUND = 1

  module ClassMethods

    attr_writer :hsx_round

    def hsx_round
      @hsx_round ||= HSX_ROUND
    end

    #========= HEX <==> RGB(A) =============================================

    def hex_to_rgb(hex, alpha_round = 3, alpha_255: false)
      hex = hex.gsub('#','')
      hex = if [3, 4].include? hex.length
              hex.chars.map{ |char| char * 2 }
            else
              hex.scan(/../)
            end
      rgb = hex.map(&:hex)
      if rgb.size == 4
        rgb[3] = (rgb[3] / 255.to_f).round(alpha_round) unless alpha_255
      end

      rgb
    end

    def rgb_to_hex(rgb, alpha_255: false)
      if rgb.size == 3
        "#%02X%02X%02X" % rgb
      else
        rgb[3] = (rgb[3] * 255).round unless alpha_255
        "#%02X%02X%02X%02X" % rgb
      end
    end

    #=======================================================================

    # simple generator RGB, you can set any channel(s)
    def new_rgb(red: nil, green: nil, blue: nil, alpha: nil)
      range = 0..255
      rgb = [red, green, blue].map { |channel| channel || rand(range) }
      alpha.nil? ? rgb : rgb + [alpha]
    end

    #========= RGB(A) to HSL/HSV/HSB =======================================

    def rgb_to_hsl(rgb_arr, rounding = hsx_round)
      # scaling RGB values into range 0..1
      red, green, blue, alpha = rgb_arr.map { |color| color / 255.to_f }

      # calculation intermediate values
      cmin, cmax, chroma = get_min_max_chroma(red, green, blue)

      # calculation HSL values
      hue = get_hue(red, green, blue)
      lightness = (cmax + cmin) / 2
      saturation = chroma == 0 ? 0 : chroma / (1 - (2 * lightness - 1).abs)

      # scaling values to fill 0..100 interval
      saturation *= 100
      lightness *= 100

      # rounding, drop Alpha if not set (nil)
      hsl = [hue, saturation, lightness].map { |x| x.round(rounding) }
      alpha.nil? ? hsl : hsl + [alpha * 255]
    end

    def rgb_to_hsv(rgb_arr, rounding = hsx_round)
      # scaling RGB values into range 0..1
      red, green, blue, alpha = rgb_arr.map { |color| color / 255.to_f }

      # calculation intermediate values
      _cmin, cmax, chroma = get_min_max_chroma(red, green, blue)

      # calculation HSV values
      hue = get_hue(red, green, blue)
      saturation = chroma == 0 ? 0 : chroma / cmax
      value = cmax

      # scaling values into range 0..100
      saturation *= 100
      value *= 100

      # rounding
      hsv = [hue, saturation, value].map { |x| x.round(rounding) }
      alpha.nil? ? hsv : hsv + [alpha * 255]
    end

    alias_method :rgb_to_hsb, :rgb_to_hsv

    #========= HSL/HSV/HSB to RGB(A) =======================================

    def hsl_to_rgb(hsl_arr)
      hue, saturation, lightness, alpha = hsl_arr.map(&:to_f)
      # scaling values into range 0..1
      saturation /= 100
      lightness /= 100

      # calculation intermediate values
      a = saturation * [lightness, 1 - lightness].min

      # calculation rgb & scaling into range 0..255
      rgb = [0, 8, 4]
      rgb.map! do |channel|
        k = (channel + hue / 30) % 12
        channel = lightness - a * [-1, [k - 3, 9 - k, 1].min].max
        (channel * 255).round
      end
      alpha.nil? ? rgb : rgb + [alpha]
    end

    def hsv_to_rgb(hsv_arr)
      hue, saturation, value, alpha = hsv_arr.map(&:to_f)
      # scaling values into range 0..1
      saturation /= 100
      value /= 100

      # calculation rgb & scaling into range 0..255
      rgb = [5, 3, 1]
      rgb.map! do |channel|
        k = (channel + hue / 60) % 6
        channel = value - value * saturation * [0, [k, 4 - k, 1].min].max
        (channel * 255).round
      end
      alpha.nil? ? rgb : rgb + [alpha]
    end

    alias_method :hsb_to_rgb, :hsv_to_rgb

    #========= Alternative implementation HSL/HSV/HSB to RGB(A) ============

    def hsl_to_rgb_alt(hsl_arr)
      hue, saturation, lightness, alpha = hsl_arr.map(&:to_f)
      # scaling values into range 0..1
      saturation /= 100
      lightness /= 100

      # calculation chroma & intermediate values
      hue = (hue % 360) / 60
      chroma = (1 - (2 * lightness - 1).abs) * saturation
      x = chroma * (1 - (hue % 2 - 1).abs)
      point = get_rgb_point(hue, chroma, x)

      # calculation rgb & scaling into range 0..255
      m = lightness - chroma / 2
      rgb = point.map { |channel| ((channel + m) * 255).round }
      alpha.nil? ? rgb : rgb + [alpha]
    end

    def hsv_to_rgb_alt(hsv_arr)
      hue, saturation, value, alpha = hsv_arr.map(&:to_f)
      # scaling values into range 0..1
      saturation /= 100
      value /= 100

      # calculation chroma & intermediate values
      hue = (hue % 360) / 60
      chroma = value * saturation
      x = chroma * (1 - (hue % 2 - 1).abs)
      point = get_rgb_point(hue, chroma, x)

      # calculation rgb & scaling into range 0..255
      m = value - chroma
      rgb = point.map { |channel| ((channel + m) * 255).round }
      alpha.nil? ? rgb : rgb + [alpha]
    end

    alias_method :hsb_to_rgb_alt, :hsv_to_rgb_alt

    #========= RGB <==> HSI ================================================

    def rgb_to_hsi(rgb_arr, rounding = hsx_round)
      # scaling RGB values into range 0..1
      rgb = rgb_arr[0..2].map { |color| color / 255.to_f }
      alpha = rgb_arr[3]

      # calculation HSI values
      hue = get_hue(*rgb)
      intensity = rgb.sum / 3
      saturation = intensity.zero? ? 0 : 1 - rgb.min / intensity

      # scaling values to fill 0..100 interval
      saturation *= 100
      intensity *= 100

      # rounding, drop Alpha if not set (nil)
      hsi = [hue, saturation, intensity].map { |x| x.round(rounding) }
      alpha.nil? ? hsi : hsi + [alpha]
    end

    def hsi_to_rgb(hsi_arr)
      hue, saturation, intensity, alpha = hsi_arr.map(&:to_f)
      # scaling values into range 0..1
      saturation /= 100
      intensity /= 100

      # calculation chroma & intermediate values
      #
      # as 360/60 does not get_rgb_point in any of the ranges 0...1 or 5...6
      # so in the method we use (hue % 360)
      # at the same time solving if hue is not in the 0..360 range
      hue = (hue % 360) / 60
      z = 1 - (hue % 2 - 1).abs
      chroma = (3 * intensity * saturation) / (1 + z)
      x = chroma * z
      point = get_rgb_point(hue, chroma, x)

      # calculation rgb
      m = intensity * (1 - saturation)
      rgb = point.map { |channel|  channel + m }

      # checking rgb on overrange 0..1
      rgb = fix_overrange_rgb(rgb)
      # scaling into range 0..255 & rounding
      rgb.map! { |channel|  (channel * 255).round }

      alpha.nil? ? rgb : rgb + [alpha]
    end

    #========= HSL <==> HSV (HSB) ==========================================

    def hsl_to_hsv(hsl_arr, rounding = hsx_round)
      hue, saturation, lightness, alpha = hsl_arr.map(&:to_f)
      # scaling values into range 0..1
      saturation /= 100
      lightness /= 100

      # calculation value & saturation HSV
      value = lightness + saturation * [lightness, 1 - lightness].min
      saturation_hsv = lightness == 0 ? 0 : 2 * (1 - lightness / value)

      # scaling HSV values & rounding
      hsv = [hue, saturation_hsv * 100, value * 100].map { |x| x.round(rounding) }
      alpha.nil? ? hsv : hsv + [alpha]
    end

    alias_method :hsl_to_hsb, :hsl_to_hsv

    def hsv_to_hsl(hsv_arr, rounding = hsx_round)
      hue, saturation, value, alpha = hsv_arr.map(&:to_f)
      # scaling values into range 0..1
      saturation /= 100
      value /= 100

      # calculation lightness & saturation HSL
      lightness = value * (1 - saturation / 2)
      saturation_hsl = if [0, 1].any? { |v| v == lightness }
                         0
                       else
                         (value - lightness) / [lightness, 1 - lightness].min
                       end

      # scaling HSL values & rounding
      hsl = [hue, saturation_hsl * 100, lightness * 100].map { |x| x.round(rounding) }
      alpha.nil? ? hsl : hsl + [alpha]
    end

    alias_method :hsb_to_hsl, :hsv_to_hsl

    #========= RGB(A) <==> CMYK ============================================

    def rgb_to_cmyk(rgb_arr, rounding = hsx_round)
      # scaling RGB values into range 0..1
      rgb = rgb_arr[0..2].map { |color| color / 255.to_f }
      k = 1 - rgb.max
      converter = proc do |color|
         (1 - k) == 0 ? 0 : (1 - color - k) / (1 - k)
      end

      # calculation CMYK & scaling into percentages & rounding
      c, m, y = rgb.map { |color| converter.call(color) || 0 }
      cmyk = [c, m, y, k].map { |x| (x * 100).round(rounding) }
      rgb_arr.size == 4 ? cmyk + [rgb_arr.last] : cmyk
    end

    def cmyk_to_rgb(cmyk_arr)
      c, m, y, k = cmyk_arr[0..3].map { |color| color / 100.to_f }
      converter = proc do |channel|
        255 * (1 - channel) * (1 - k)
      end

      # calculation RGB & rounding
      rgb = [c, m, y].map { |channel| converter.call(channel).round }
      cmyk_arr.size == 5 ? rgb + [cmyk_arr.last] : rgb
    end

    #========= HEX <==> HSL/HSV/HSB/HSI ========================================

    def hex_to_hsl(hex, rounding = hsx_round, alpha_255: false)
      rgb = hex_to_rgb(hex, alpha_255: alpha_255)
      rgb_to_hsl(rgb, rounding)
    end

    def hsl_to_hex(hsl_arr, alpha_255: false)
      rgb = hsl_to_rgb(hsl_arr)
      rgb_to_hex(rgb, alpha_255: alpha_255)
    end

    def hex_to_hsv(hex, rounding = hsx_round, alpha_255: false)
      rgb = hex_to_rgb(hex, alpha_255: alpha_255)
      rgb_to_hsv(rgb, rounding)
    end

    def hsv_to_hex(hsv_arr, alpha_255: false)
      rgb = hsv_to_rgb(hsv_arr)
      rgb_to_hex(rgb, alpha_255: alpha_255)
    end

    alias_method :hex_to_hsb, :hex_to_hsv
    alias_method :hsb_to_hex, :hsv_to_hex

    def hex_to_hsi(hex, rounding = hsx_round, alpha_255: false)
      rgb = hex_to_rgb(hex, alpha_255: alpha_255)
      rgb_to_hsi(rgb, rounding)
    end

    def hsi_to_hex(hsi_arr, alpha_255: false)
      rgb = hsi_to_rgb(hsi_arr)
      rgb_to_hex(rgb, alpha_255: alpha_255)
    end

    def hex_to_cmyk(hex, rounding = hsx_round, alpha_255: false)
      rgb = hex_to_rgb(hex, alpha_255: alpha_255)
      rgb_to_cmyk(rgb, rounding)
    end

    def cmyk_to_hex(cmyk_arr, alpha_255: false)
      rgb = cmyk_to_rgb(cmyk_arr)
      rgb_to_hex(rgb, alpha_255: alpha_255)
    end


    private

    #========= helper methods ==============================================

    # find greatest and smallest channel values and chroma from RGB
    def get_min_max_chroma(red, green, blue)
      cmin = [red, green, blue].min
      cmax = [red, green, blue].max
      # calculation chroma
      chroma = cmax - cmin

      [cmin, cmax, chroma]
    end

    # calculation HUE from RGB
    def get_hue(red, green, blue)
      _cmin, cmax, chroma = get_min_max_chroma(red, green, blue)

      hue = if chroma == 0
              0
            elsif cmax == red
              # red is max
              ((green - blue) / chroma) % 6
            elsif cmax == green
              # green is max
              (blue - red) / chroma + 2
            else
              # blue is max
              (red - green) / chroma + 4
            end
      hue * 60

      # HUE will never leave the 0..360 range when RGB is within 0..255
      # make negative HUEs positive
      # 0 <= hue ? hue : hue + 360
    end

    # possible RGB points
    # point selection based on entering HUE input in range
    def get_rgb_point(hue, chroma, x)
      case hue
      when 0...1 then [chroma, x, 0]
      when 1...2 then [x, chroma, 0]
      when 2...3 then [0, chroma, x]
      when 3...4 then [0, x, chroma]
      when 4...5 then [x, 0, chroma]
      when 5...6 then [chroma, 0, x]
      # HUE will never leave the 0..359 range because we use (hue % 360)
      # else [0, 0, 0]
      end
    end

    # checking rgb on overrange 0..1
    def fix_overrange_rgb(rgb)
      max = rgb.max
      # so we keep HUE
      # if we had just used clipping [[value, 255].min, 0].max
      # we would have changed HUE
      #
      # Thx to Rotem & Giacomo Catenazzi from stackoverflow
      max > 1 ? rgb.map { |channel|  channel / max } : rgb
    end
  end

  extend ClassMethods
end
