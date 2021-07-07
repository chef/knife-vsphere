source "https://rubygems.org"

gemspec

group :debug do
  gem "pry"
  gem "pry-byebug"
  gem "pry-stack_explorer", "~> 0.4.0" # supports Ruby < 2.6
end

group :test do
  gem "chefstyle", "2.0.6"
  if Gem::Version.new(RUBY_VERSION) < Gem::Version.new("2.6")
    gem "chef-zero", "~> 14"
    gem "chef", "~> 15"
  end
  gem "rake"
  gem "rspec", "~> 3.0"
end

group :docs do
  gem "github-markup"
  gem "redcarpet"
  gem "yard"
end
