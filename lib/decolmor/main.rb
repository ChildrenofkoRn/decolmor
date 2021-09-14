module Decolmor

  #========= HEX <==> RGB(A) =============================================

  def self.hex_to_rgb(hex, alpha_round = 3)
    hex = hex.gsub('#','')
    hex = if [3, 4].include? hex.length
            hex.chars.map{ |char| char * 2 }
          else
            hex.scan(/../)
          end
    rgb = hex.map(&:hex)
    rgb.size == 4 ? rgb + [(rgb.delete_at(3) / 255.to_f).round(alpha_round)] : rgb
  end

  def self.rgb_to_hex(rgb)
    template = rgb.size == 3 ? "#%02X%02X%02X" : "#%02X%02X%02X%02X"
    rgb = rgb[0..2] + [(rgb[3] * 255).round] if rgb.size == 4
    template % rgb
  end

  #=======================================================================

  # simple generator RGB, you can set any channel(s)
  def self.new_rgb(red: nil, green: nil, blue: nil, alpha: nil)
    range = 0..255
    rgb = [red, green, blue].map { |channel| channel || rand(range) }
    alpha.nil? ? rgb : rgb + [alpha]
  end

  #========= RGB(A) to HSL/HSV/HSB =======================================

  def self.rgb_to_hsl(rgb_arr, rounding = hsx_round)
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

  def self.rgb_to_hsv(rgb_arr, rounding = hsx_round)
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


  self.singleton_class.send(:alias_method, :rgb_to_hsb, :rgb_to_hsv)

  #========= HSL/HSV/HSB to RGB(A) =======================================

  def self.hsl_to_rgb(hsl_arr)
    hue, saturation, lightness, alpha = hsl_arr.map(&:to_f)
    # scaling values into range 0..1
    saturation /= 100
    lightness /= 100

    # calculation intermediate values
    a = saturation * [lightness, 1 - lightness].min
    converter = proc do |n|
      k = (n + hue / 30) % 12
      lightness - a * [-1, [k - 3, 9 - k, 1].min].max
    end

    # calculation rgb & scaling into range 0..255
    rgb = [0, 8, 4]
    rgb.map! { |channel| (converter.call(channel) * 255).round }
    alpha.nil? ? rgb : rgb + [alpha]
  end

  def self.hsv_to_rgb(hsv_arr)
    hue, saturation, value, alpha = hsv_arr.map(&:to_f)
    # scaling values into range 0..1
    saturation /= 100
    value /= 100

    # calculation intermediate values
    converter = proc do |n|
      k = (n + hue / 60) % 6
      value - value * saturation * [0, [k, 4 - k, 1].min].max
    end

    # calculation rgb & scaling into range 0..255
    rgb = [5, 3, 1]
    rgb.map! { |channel| (converter.call(channel) * 255).round }
    alpha.nil? ? rgb : rgb + [alpha]
  end

  self.singleton_class.send(:alias_method, :hsb_to_rgb, :hsv_to_rgb)

  #========= Alternative implementation HSL/HSV/HSB to RGB(A) ============

  def self.hsl_to_rgb_alt(hsl_arr)
    hue, saturation, lightness, alpha = hsl_arr.map(&:to_f)
    # scaling values into range 0..1
    saturation /= 100
    lightness /= 100

    # calculation chroma & intermediate values
    chroma = (1 - (2 * lightness - 1).abs) * saturation
    hue /= 60
    x = chroma * (1 - (hue % 2 - 1).abs)

    # possible RGB points
    points = [[chroma, x, 0],
              [x, chroma, 0],
              [0, chroma, x],
              [0, x, chroma],
              [x, 0, chroma],
              [chroma, 0, x]]
    # point selection based on entering HUE input in range
    point = points.each_with_index.detect { |rgb_, n| (n..n + 1).include? hue }&.first
    # if point == nil (hue undefined)
    rgb = point || [0, 0, 0]

    # calculation rgb & scaling into range 0..255
    m = lightness - chroma / 2
    rgb.map! { |channel| ((channel + m) * 255).round }
    alpha.nil? ? rgb : rgb + [alpha]
  end

  def self.hsv_to_rgb_alt(hsv_arr)
    hue, saturation, value, alpha = hsv_arr.map(&:to_f)
    # scaling values into range 0..1
    saturation /= 100
    value /= 100

    # calculation chroma & intermediate values
    chroma = value * saturation
    hue /= 60
    x = chroma * (1 - (hue % 2 - 1).abs)

    # possible RGB points
    points = [[chroma, x, 0],
              [x, chroma, 0],
              [0, chroma, x],
              [0, x, chroma],
              [x, 0, chroma],
              [chroma, 0, x]]
    # point selection based on entering HUE input in range
    point = points.each_with_index.detect { |rgb_, n| (n * (1 / 100.000)...n + 1).include? hue }&.first
    # if point == nil (hue undefined)
    rgb = point || [0, 0, 0]

    # calculation rgb & scaling into range 0..255
    m = value - chroma
    rgb.map! { |channel| ((channel + m) * 255).round }
    alpha.nil? ? rgb : rgb + [alpha]
  end

  self.singleton_class.send(:alias_method, :hsb_to_rgb_alt, :hsv_to_rgb_alt)

  #========= HSL <==> HSV (HSB) ==========================================

  def self.hsl_to_hsv(hsl_arr, rounding = hsx_round)
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

  self.singleton_class.send(:alias_method, :hsl_to_hsb, :hsl_to_hsv)

  def self.hsv_to_hsl(hsv_arr, rounding = hsx_round)
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

  self.singleton_class.send(:alias_method, :hsb_to_hsl, :hsv_to_hsl)

  #========= RGB(A) <==> CMYK ============================================

  def self.rgb_to_cmyk(rgb_arr, rounding = hsx_round)
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

  def self.cmyk_to_rgb(cmyk_arr)
    c, m, y, k = cmyk_arr[0..3].map { |color| color / 100.to_f }
    converter = proc do |channel|
      255 * (1 - channel) * (1 - k)
    end

    # calculation RGB & rounding
    rgb = [c, m, y].map { |channel| converter.call(channel).round }
    cmyk_arr.size == 5 ? rgb + [cmyk_arr.last] : rgb
  end

  private

  #========= helper methods for RGB to HSL/HSB/HSV =======================

  # find greatest and smallest channel values and chroma from RGB
  def self.get_min_max_chroma(red, green, blue)
    cmin = [red, green, blue].min
    cmax = [red, green, blue].max
    # calculation chroma
    chroma = cmax - cmin

    [cmin, cmax, chroma]
  end

  # calculation HUE from RGB
  def self.get_hue(red, green, blue)
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
    hue *= 60
    # make negative HUEs positive behind 360°
    0 <= hue ? hue : hue + 360
  end
end
