load_class(__FILE__)

RSpec.describe Decolmor do

  describe 'we can include the module into the class' do
    let(:dummy_class) { Class.new { include Decolmor } }

    it "class contains the module Decolmor" do
      expect( dummy_class.include?(Decolmor) ).to eq true
    end

    it "methods will be available into our class as class methods" do
      expect { dummy_class.hsx_round = 3 }.to change { dummy_class.hsx_round }.from(1).to(3)
    end
  end

  describe 'we can set rounding globally for convert to HSL/HSV/HSB/CMYK' do
    after(:each) do
      Decolmor.hsx_round = 1
    end

    let(:colors) { FactoryBot.build(:colors_map, round: 2) }

    it ".hsx_round by default 1" do
      expect( Decolmor.hsx_round ).to eq 1
    end

    it ".hsx_round= changes hsx_round" do
      expect { Decolmor.hsx_round = 2 }.to change { Decolmor.hsx_round }.from(1).to(2)
    end
  end

  context 'HEX <==> RGB(A)' do
    describe ".hex_to_rgb" do
      let(:colors) { FactoryBot.build(:colors_map) }
      let(:alphas) { FactoryBot.build(:alpha) }

      it "HEX w prefix # to RGB" do
        colors.each_pair do |hex, values|
          expect( Decolmor.hex_to_rgb(hex) ).to eq values[:rgb]
        end
      end

      it "HEX w/o prefix # to RGB" do
        colors.each_pair do |hex, values|
          hex = hex.delete('#')
          expect( Decolmor.hex_to_rgb(hex) ).to eq values[:rgb]
        end
      end

      it "HEX w alpha channel and prefix # to RGBA" do
        docs "alpha into range 0..1 and rounding 3"
        color = colors.keys.sample
        alphas.each_pair do |hex_alpha, alpha|
          hex = format('%s%s', color, hex_alpha)
          rgba = colors[color][:rgb] + [alpha[:rgb]]
          expect( Decolmor.hex_to_rgb(hex) ).to eq rgba
        end
      end

      it "set rounding for alpha channel" do
        color = colors.keys.sample
        alphas.each_pair do |hex_alpha, alpha|
          rounding = 2
          hex = format('%s%s', color, hex_alpha)
          rgba = colors[color][:rgb] + [alpha[:rgb].round(rounding)]
          expect( Decolmor.hex_to_rgb(hex, rounding) ).to eq rgba
        end
      end

      it "set range 0..255 for alpha channel" do
        color = colors.keys.sample
        alphas.each_pair do |hex_alpha, alpha|
          hex = format('%s%s', color, hex_alpha)
          expect( Decolmor.hex_to_rgb(hex, alpha_255: true).last ).to eq alpha[:rgb_255]
        end
      end

      it "HEX w alpha channel and w/o prefix # to RGBA" do
        color = colors.keys.sample

        alphas.each_pair do |hex_alpha, alpha|
          hex = format('%s%s', color, hex_alpha).delete('#')
          rgba = colors[color][:rgb] + [alpha[:rgb]]
          expect( Decolmor.hex_to_rgb(hex) ).to eq rgba
        end
      end

      it "HEX short version to RGB(A)" do
        colors = {'6FC' => [102, 255, 204], '#9C3' => [153, 204, 51], '36FF' => [51, 102, 255, 1]}

        colors.each_pair do |hex_short, rgb|
          expect( Decolmor.hex_to_rgb(hex_short) ).to eq rgb
        end
      end
    end

    describe ".rgb_to_hex" do
      let(:colors) { FactoryBot.build(:colors_map) }
      let(:alphas) { FactoryBot.build(:alpha) }

      it "RGB converts to HEX" do
        colors.each_pair do |hex, values|
          expect( Decolmor.rgb_to_hex(values[:rgb]) ).to eq hex
        end
      end

      it "RGBA converts to HEX w alpha" do
        color = colors.keys.sample

        alphas.each_pair do |hex_alpha, alpha|
          hex = format('%s%s', color, hex_alpha)
          rgba = colors[color][:rgb] + [alpha[:rgb]]
          expect( Decolmor.rgb_to_hex(rgba) ).to eq hex
        end
      end

      it "set range 0..255 for alpha channel" do
        color = colors.keys.sample

        alphas.each_pair do |hex_alpha, alpha|
          hex = format('%s%s', color, hex_alpha)
          rgba = colors[color][:rgb] + [alpha[:rgb_255]]
          expect( Decolmor.rgb_to_hex(rgba, alpha_255: true) ).to eq hex
        end
      end
    end
  end

  
  context 'simple generator RGB, you can set any channel(s)' do
    describe ".new_rgb" do
      it "generate RGB with values into range 0..255" do
        100.times do
          expect( Decolmor.new_rgb ).to all( be_between(0, 255) )
        end
      end

      it "w params generate RGB with established values" do
        docs "alpha isn't generated, but you can set it"
        color = {red: 72, green: 209, blue: 204, alpha: 244}
        # set and check each channel separately
        color.each_with_index do |(key, value), index|
          expect( Decolmor.new_rgb(**{key => value})[index] ).to eq value
        end
        # set all channels
        expect( Decolmor.new_rgb(**color) ).to eq color.values
      end
    end
  end


  context 'RGB(A) to HSL/HSV/HSB' do
    describe ".rgb_to_hsl" do
      let(:colors) { FactoryBot.build(:colors_map) }
      let(:alphas) { FactoryBot.build(:alpha) }

      it "RGB converts to HSL" do
        colors.each_pair do |hex, values|
          expect( Decolmor.rgb_to_hsl(values[:rgb]) ).to eq values[:hsl]
        end
      end

      it "alpha channel pass to HSL unchanged" do
        color = colors.keys.sample
        alphas.each_pair do |_hex_alpha, alpha|
          rgba = colors[color][:rgb] + [alpha[:rgb]]
          expect( Decolmor.rgb_to_hsl(rgba).last ).to eq alpha[:rgb]
        end
      end

      it "you can set rounding for resulting HSL values (default = 1)" do
        docs "round 1 enough for a lossless conversion RGB -> HSL/HSV/HSB -> RGB"
        colors.each_pair do |hex, values|
          expect( Decolmor.rgb_to_hsl(values[:rgb], 0) ).to eq values[:hsl].map(&:round)
        end
      end

      it "setting rounding doesn't affect alpha channel" do
        color = colors.keys.sample
        alphas.each_pair do |_hex_alpha, alpha|
          rgba = colors[color][:rgb] + [alpha[:rgb]]
          # alpha shouldn't be rounded because its range is 0..1
          # if that did happen, we would get 0 or 1 instead of the normal value
          expect( Decolmor.rgb_to_hsl(rgba, 0).last ).to eq alpha[:rgb]
        end
      end
    end

    describe ".rgb_to_hsv" do
      let(:colors) { FactoryBot.build(:colors_map) }
      let(:alphas) { FactoryBot.build(:alpha) }
      let(:colors_round_2) { FactoryBot.build(:colors_map, round: 2) }

      it "RGB converts to HSV" do
        colors.each_pair do |hex, values|
          expect( Decolmor.rgb_to_hsv(values[:rgb]) ).to eq values[:hsv]
        end
      end

      it "alpha channel pass to HSV unchanged" do
        color = colors.keys.sample
        alphas.each_pair do |_hex_alpha, alpha|
          rgba = colors[color][:rgb] + [alpha[:rgb]]
          expect( Decolmor.rgb_to_hsv(rgba).last ).to eq alpha[:rgb]
        end
      end

      it "you can set rounding for resulting HSV values (default = 1)" do
        colors_round_2.each_pair do |hex, values|
          expect( Decolmor.rgb_to_hsv(values[:rgb], 0) ).to eq values[:hsv].map(&:round)
        end
      end

      it "setting rounding doesn't affect alpha channel" do
        color = colors.keys.sample
        alphas.each_pair do |_hex_alpha, alpha|
          rgba = colors[color][:rgb] + [alpha[:rgb]]
          expect( Decolmor.rgb_to_hsv(rgba, 0).last ).to eq alpha[:rgb]
        end
      end
    end

    describe ".rgb_to_hsb" do
      it "alias .rgb_to_hsv" do
        expect( Decolmor.method(:rgb_to_hsb ).original_name).to eq(:rgb_to_hsv)
      end
    end
  end


  context 'HSL/HSV/HSB to RGB(A)' do
    describe ".hsl_to_rgb" do
      let(:colors) { FactoryBot.build(:colors_map) }
      let(:alphas) { FactoryBot.build(:alpha) }

      it "HSL converts to RGB" do
        colors.each_pair do |_hex, values|
          expect( Decolmor.hsl_to_rgb(values[:hsl]) ).to eq values[:rgb]
        end
      end

      it "alpha channel pass to RGB unchanged" do
        color = colors.keys.sample
        alphas.each_pair do |_hex_alpha, values|
          hsla = colors[color][:hsl] + [values[:rgb]]
          expect( Decolmor.hsl_to_rgb(hsla).last ).to eq values[:rgb]
        end
      end
    end

    describe ".hsv_to_rgb" do
      let(:colors) { FactoryBot.build(:colors_map) }
      let(:alphas) { FactoryBot.build(:alpha) }

      it "HSV converts to RGB" do
        colors.each_pair do |_hex, values|
          expect( Decolmor.hsv_to_rgb(values[:hsv]) ).to eq values[:rgb]
        end
      end

      it "alpha channel pass to RGB unchanged" do
        color = colors.keys.sample
        alphas.each_pair do |_hex_alpha, values|
          hsva = colors[color][:hsv] + [values[:rgb]]
          expect( Decolmor.hsv_to_rgb(hsva).last ).to eq values[:rgb]
        end
      end
    end

    describe ".hsb_to_rgb" do
      it "alias .hsv_to_rgb" do
        expect( Decolmor.method(:hsb_to_rgb ).original_name).to eq(:hsv_to_rgb)
      end
    end
  end


  context 'Alternative implementation HSL/HSV/HSB to RGB(A)' do
    describe ".hsl_to_rgb_alt" do
      let(:colors) { FactoryBot.build(:colors_map) }
      let(:alphas) { FactoryBot.build(:alpha) }

      it "HSL converts to RGB" do
        colors.each_pair do |_hex, values|
          expect( Decolmor.hsl_to_rgb_alt(values[:hsl]) ).to eq values[:rgb]
        end
      end

      it "alpha channel pass to RGB unchanged" do
        color = colors.keys.sample
        alphas.each_pair do |_hex_alpha, values|
          hsla = colors[color][:hsl] + [values[:rgb]]
          expect( Decolmor.hsl_to_rgb_alt(hsla).last ).to eq values[:rgb]
        end
      end

      it "if hue not a range member 0..360 return identical RGB values (colorless)" do
        colors.each_pair do |hex, values|
          hsl = values[:hsl]
          hsl[0] += 360
          expect( Decolmor.hsl_to_rgb_alt(hsl).uniq.size ).to eq 1
        end
      end
    end

    describe ".hsv_to_rgb_alt" do
      let(:colors) { FactoryBot.build(:colors_map) }
      let(:alphas) { FactoryBot.build(:alpha) }

      it "HSV converts to RGB" do
        colors.each_pair do |_hex, values|
          expect( Decolmor.hsv_to_rgb_alt(values[:hsv]) ).to eq values[:rgb]
        end
      end

      it "alpha channel pass to RGB unchanged" do
        color = colors.keys.sample
        alphas.each_pair do |_hex_alpha, values|
          hsva = colors[color][:hsv] + [values[:rgb]]
          expect( Decolmor.hsv_to_rgb_alt(hsva).last ).to eq values[:rgb]
        end
      end

      it "if hue not a range member 0..360 return identical RGB values (colorless)" do
        colors.each_pair do |_hex, values|
          hsl = values[:hsl]
          hsl[0] -= 360
          expect( Decolmor.hsl_to_rgb_alt(hsl).uniq.size ).to eq 1
        end
      end
    end

    describe ".hsb_to_rgb_alt" do
      it "alias .hsv_to_rgb_alt" do
        expect( Decolmor.method(:hsb_to_rgb_alt ).original_name).to eq(:hsv_to_rgb_alt)
      end
    end
  end


  context 'HSL <==> HSV (HSB)' do
    describe ".hsl_to_hsv" do
      # as for lossless conversion need to use float value with 2 decimal places
      let(:colors) { FactoryBot.build(:colors_map, round: 2) }
      let(:alphas) { FactoryBot.build(:alpha) }

      it "HSL converts to HSV" do
        colors.each_pair do |hex_, values|
          hsv = values[:hsv].map { |value| value.round(1) }
          expect( Decolmor.hsl_to_hsv(values[:hsl]) ).to eq hsv
        end
      end

      it "alpha channel pass to HSV unchanged" do
        color = colors.keys.sample
        alphas.each_pair do |_hex_alpha, alpha|
          hsla = colors[color][:hsl] + [alpha[:rgb]]
          expect( Decolmor.hsl_to_hsv(hsla).last ).to eq alpha[:rgb]
        end
      end

      it "you can set rounding for resulting HSV values (default = 1)" do
        colors.each_pair do |_hex, values|
          expect( Decolmor.hsl_to_hsv(values[:hsl], 0) ).to eq values[:hsv].map(&:round)
        end
      end

      it "setting rounding doesn't affect alpha channel" do
        color = colors.keys.sample
        alphas.each_pair do |_hex_alpha, alpha|
          hsla = colors[color][:hsl] + [alpha[:rgb]]
          expect( Decolmor.hsl_to_hsv(hsla, 0).last ).to eq alpha[:rgb]
        end
      end
    end

    describe ".hsl_to_hsb" do
      it "alias .hsl_to_hsv" do
        expect( Decolmor.method(:hsl_to_hsb).original_name ).to eq(:hsl_to_hsv)
      end
    end

    describe ".hsv_to_hsl" do
      # as for lossless conversion need to use float value with 2 decimal places
      let(:colors) { FactoryBot.build(:colors_map, round: 2) }
      let(:alphas) { FactoryBot.build(:alpha) }

      it "HSV converts to HSL" do
        colors.each_pair do |_hex, values|
          hsl = values[:hsl].map { |value| value.round(1) }
          expect( Decolmor.hsv_to_hsl(values[:hsv]) ).to eq hsl
        end
      end

      it "alpha channel pass to HSL unchanged" do
        color = colors.keys.sample
        alphas.each_pair do |_hex_alpha, alpha|
          hsva = colors[color][:hsv] + [alpha[:rgb]]
          expect( Decolmor.hsv_to_hsl(hsva).last ).to eq alpha[:rgb]
        end
      end

      it "you can set rounding for resulting HSL values (default = 1)" do
        colors.each_pair do |_hex, values|
          expect( Decolmor.hsv_to_hsl(values[:hsv], 0) ).to eq values[:hsl].map(&:round)
        end
      end

      it "setting rounding doesn't affect alpha channel" do
        color = colors.keys.sample
        alphas.each_pair do |_hex, alpha|
          hsva = colors[color][:hsv] + [alpha[:rgb]]
          expect( Decolmor.hsv_to_hsl(hsva, 0).last ).to eq alpha[:rgb]
        end
      end
    end

    describe ".hsb_to_hsl" do
      it "alias .hsv_to_hsl" do
        expect( Decolmor.method(:hsb_to_hsl).original_name ).to eq(:hsv_to_hsl)
      end
    end
  end


  context 'RGB(A) <==> CMYK' do
    describe ".rgb_to_cmyk" do
      let(:colors) { FactoryBot.build(:colors_map) }
      let(:alphas) { FactoryBot.build(:alpha) }

      it "RGB converts to CMYK" do
        colors.each_pair do |hex_, values|

          cmyk = values[:cmyk].map {|arr| arr.round(1) }
          expect( Decolmor.rgb_to_cmyk(values[:rgb]) ).to eq cmyk
        end
      end

      it "alpha channel pass to HSL unchanged" do
        color = colors.keys.sample
        alphas.each_pair do |_hex_alpha, alpha|
          rgba = colors[color][:rgb] + [alpha[:rgb]]
          expect( Decolmor.rgb_to_cmyk(rgba).last ).to eq alpha[:rgb]
        end
      end

      it "you can set rounding for resulting CMYK values (default = 1)" do
        colors.each_pair do |hex, values|
          expect( Decolmor.hsv_to_hsl(values[:hsv], 0) ).to eq values[:hsl].map(&:round)
        end
      end

      it "setting rounding doesn't affect alpha channel" do
        color = colors.keys.sample
        alphas.each_pair do |_hex_alpha, alpha|
          rgba = colors[color][:rgb] + [alpha[:rgb]]
          expect( Decolmor.rgb_to_cmyk(rgba, 0).last ).to eq alpha[:rgb]
        end
      end
    end

    describe ".cmyk_to_rgb" do
      let(:colors) { FactoryBot.build(:colors_map) }
      let(:alphas) { FactoryBot.build(:alpha) }

      it "CMYK converts to RGB" do
        colors.each_pair do |hex_, values|
          expect( Decolmor.cmyk_to_rgb(values[:cmyk]) ).to eq values[:rgb]
        end
      end

      it "alpha channel pass to RGB unchanged" do
        color = colors.keys.sample
        alphas.each_pair do |_hex_alpha, values|
          cmyka = colors[color][:cmyk] + [values[:rgb]]
          expect( Decolmor.cmyk_to_rgb(cmyka).last ).to eq values[:rgb]
        end
      end
    end
  end

end
