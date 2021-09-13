require File.expand_path('lib/decolmor/version', __dir__)

Gem::Specification.new do |spec|
  spec.name          = 'decolmor'
  spec.version       = Decolmor::VERSION
  spec.licenses      = ['MIT']
  spec.summary       = "Converter color spaces from/to: HEX/RGB/HSL/HSV/HSB/CMYK"
  spec.description   = "Gem for converting color spaces from/to: HEX/RGB/HSL/HSV/HSB/CMYK\n" \
                       "The Alpha channel (transparency) is supported.\n" \
                       "There is also a simple RGB generator."
  spec.authors       = ["ChildrenofkoRn"]
  spec.email         = 'Rick-ROR@ya.ru'
  spec.homepage      = 'https://github.com/ChildrenofkoRn/decolmor'
  spec.require_paths = ['lib']
  spec.files         = Dir['lib/**/*'] +
                       %w(README.md CHANGELOG.md NEWS.md LICENSE
                          decolmor.gemspec Gemfile Rakefile)
  spec.test_files    = Dir['spec/**/*'] + ['.rspec']
  spec.extra_rdoc_files      = %w(README.md LICENSE)

  spec.platform              = Gem::Platform::RUBY
  spec.required_ruby_version = Gem::Requirement.new(">= 2.4.0")

  if spec.respond_to?(:metadata)
    spec.metadata = {
      "homepage_uri"      => spec.homepage.to_s,
      "news_uri"          => "#{spec.homepage}/blob/master/NEWS.md",
      "changelog_uri"     => "#{spec.homepage}/blob/master/CHANGELOG.md",
      "documentation_uri" => "#{spec.homepage}/blob/master/README.md",
      "bug_tracker_uri"   => "#{spec.homepage}/issues",
      "source_code_uri"   => spec.homepage.to_s
    }
  end

  spec.add_development_dependency 'bundler',     '>= 1.17', '< 3.0'
  spec.add_development_dependency 'rake',        '~> 13.0'
  spec.add_development_dependency 'codecov',     '~> 0.2'
  spec.add_development_dependency 'rspec',       '~> 3.8'
  spec.add_development_dependency 'factory_bot', '>= 5.1', '< 7.0'
end
