def remind(msg); say set_color( "REMEMBER ", :red ) + set_color(msg, :yellow) end

# Reset Gemfile
run %Q[echo "source 'https://rubygems.org'" > Gemfile]
run %Q[echo "ruby '2.0.0'" >> Gemfile]

# Core gems
gem 'rails', '4.0.0'
gem 'sass-rails', '~> 4.0.0'
gem 'uglifier', '>= 1.3.0'
gem 'jquery-rails'
gem 'turbolinks'
gem 'jbuilder', '~> 1.2'
gem "slim-rails" if yes?("Use Slim instead of ERB?")
gem 'coffee-rails', '~> 4.0.0' if yes?("Use CoffeeScript?")

# Database
if yes?("Use Postgres instead of SQLite?")
  gem "pg" 
  remind "This script assumes your account has super-user access to Postgres"
  gsub_file "config/database.yml", /adapter: sqlite3/,        "adapter: postgresql"
  gsub_file "config/database.yml", /db\/development.sqlite3/, "#{app_path.underscore}_development"
  gsub_file "config/database.yml", /db\/test.sqlite3/,        "#{app_path.underscore}_test"
  gsub_file "config/database.yml", /db\/production.sqlite3/,  "#{app_path.underscore}_production"
  gsub_file "config/database.yml", /^\s*#.*\n/, ''
  rake "db:create"
else
  gem "sqlite3"
end

# Web server
if yes?("Use Unicorn?")
  gem "unicorn-rails"
  run "curl -s https://raw.github.com/heroku/ruby-rails-unicorn-sample/master/config/unicorn.rb > config/unicorn.rb" # Configure Unicorn
  run "echo 'web: bundle exec unicorn -p $PORT -c ./config/unicorn.rb' >> Procfile" # Setup Procfile
else
  gem 'thin'
  run "echo 'web: bundle exec rails server -p $PORT' >> Procfile" # Setup Procfile
end

# Format Gemfile to make it pretty
insert_into_file "Gemfile", "\n"

gem_group :development, :test do
  gem "rspec-rails" 
  gem "factory_girl_rails"
end

gem_group :production do
  gem "rails_12factor"
end

# Twitter Bootstrap (http://getbootstrap.com/)
if yes?("Download Bootstrap?")
  run "wget -nv https://github.com/twbs/bootstrap/archive/v3.0.0.zip -O bootstrap.zip -O bootstrap.zip"
  run "unzip -q bootstrap.zip -d bootstrap && rm bootstrap.zip"
  run "cp bootstrap/bootstrap-3.0.0/dist/css/bootstrap.css vendor/assets/stylesheets/"
  run "cp bootstrap/bootstrap-3.0.0/dist/js/bootstrap.js vendor/assets/javascripts/"
  run "rm -rf bootstrap"
  insert_into_file "app/assets/stylesheets/application.css", " *= require bootstrap\n", before: " *= require_self\n"
  insert_into_file "app/assets/javascripts/application.js",  "//= require bootstrap\n", after:  "//= require turbolinks\n"
end

# Fontawesome (http://http://fontawesome.io/)
if yes?("Download font-awesome?")
  run "wget -nv http://fontawesome.io/assets/font-awesome-4.0.3.zip -O font-awesome.zip"
  run "unzip -q font-awesome.zip && rm font-awesome.zip"
  run "cp font-awesome-4.0.3/css/font-awesome.css vendor/assets/stylesheets/"
  run "cp -r font-awesome-4.0.3/fonts/ public/fonts"
  run "rm -rf font-awesome-4.0.3"
  insert_into_file "app/assets/stylesheets/application.css", " *= require font-awesome\n",  before: " *= require_self\n"
end

# Setup Foreman (https://github.com/ddollar/foreman)
run "touch .env"
run "echo '.env' >> .gitignore"
run "echo 'STDOUT.sync = true' >> config/environments/development.rb"

# Initialize RSpec
generate("rspec:install")
run "rm -rf test/"

# Initialize Git
git :init
git add: "."
git commit: %Q{ -q -m 'Initial commit' }