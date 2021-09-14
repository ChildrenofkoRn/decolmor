FactoryBot.define do
  factory :alpha, class: Hash do
    skip_create

    samples = [0, 1, 64, 128, 191, 254, 255]

    values = samples.each_with_object(Hash.new) do |value, hash|
      hex = "%02X" % value
      range_01  = (value / 255.to_f).round(3)
      hash[hex] = {rgb: range_01, rgb_255: value}
    end

    initialize_with { values }
  end
end
