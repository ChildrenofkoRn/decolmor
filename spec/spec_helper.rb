require 'simplecov'

SimpleCov.start do
  add_filter 'spec'
  add_filter 'lib/decolmor/version.rb'

  if ENV['CI']
    require 'codecov'
    formatter SimpleCov::Formatter::Codecov
  else
    formatter SimpleCov::Formatter::MultiFormatter
                .new([SimpleCov::Formatter::HTMLFormatter])
  end

  track_files "**/*.rb"
end


require 'rspec'
require 'factory_bot'

RSpec.configure do |config|

  config.expose_dsl_globally = true

  # Use color in STDOUT
  config.color_mode = :on

  # Use color not only in STDOUT but also in pagers and files
  config.tty = true

  # Use the specified formatter
  config.formatter = :documentation # :progress, :html, :textmate

  config.include FactoryBot::Syntax::Methods

  config.before do
    FactoryBot.reload
  end

  config.before(:suite) do
    FactoryBot.find_definitions
  end
end

def load_class(file)
  klass = File.basename(file).gsub('_spec','')
  require File.expand_path("lib/#{klass}")
end

def docs(message, level=0)
  RSpec.configuration.reporter.message "#{'  ' * level}# #{message}"
end
