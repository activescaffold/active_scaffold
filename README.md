
Overview
========
[![Build status](https://travis-ci.com/activescaffold/active_scaffold.svg?branch=master)](https://travis-ci.com/activescaffold/active_scaffold)
[![Code Climate](https://codeclimate.com/github/activescaffold/active_scaffold/badges/gpa.svg)](https://codeclimate.com/github/activescaffold/active_scaffold)
[![Test Coverage](https://codeclimate.com/github/activescaffold/active_scaffold/badges/coverage.svg)](https://codeclimate.com/github/activescaffold/active_scaffold)
[![Dependency Status](https://gemnasium.com/activescaffold/active_scaffold.svg)](https://gemnasium.com/activescaffold/active_scaffold)
[![Gem Version](https://badge.fury.io/rb/active_scaffold.svg)](https://badge.fury.io/rb/active_scaffold)
[![Inline docs](https://inch-ci.org/github/activescaffold/active_scaffold.svg?branch=master)](https://inch-ci.org/github/activescaffold/active_scaffold)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

ActiveScaffold provides a quick and powerful user interfaces for CRUD (create, read, update, delete) operations for Rails applications. It offers additonal features including searching, pagination & layout control.  Rails >= 5.2.0 and Rails < 6.1 is supported, ruby >= 2.5 required.

Branch Details
--------------
3-6-stable supports rails >= 4.2.x and ruby >= 2.3.0
3-5-stable supports rails >= 4.0.x and ruby >= 2.0.0  
3-4-stable supports rails >= 3.2.x and ruby >= 1.9.3  
3-3-stable supports rails >= 3.2.x and ruby >= 1.8  
rails-3.2 supports Rails 3.1 & 3.2, and is the current source of the 3.2.x line of gems.

Quick Start
-----------
To get started with a new Rails project

Added to Gemfile

    gem 'active_scaffold'

For rails >= 5.1, add jquery-rails to Gemfile, and install generator will jquery to application.js before rails-ujs. Also it's possible to load jquery in your layout before application.js using CDN (e.g. jquery-rails-cdn). You can replace rails-ujs with jquery_ujs, although rails-ujs should work (never load both).

    gem 'jquery-rails'

For rails >= 6.0, installer generator will create app/assets/javascripts/application.js, add it to assets.precompile array and add javascript_include_tag in layout, as ActiveScaffold doesn't work with webpack yet. Jquery may be loaded by packs or assets pipeline.

Run the following commands, for rails 4.2

    bundle install
    rails g active_scaffold:install
    bundle exec rake db:create
    rails g active_scaffold:resource Model [attrs]
    bundle exec rake db:migrate
    
Or run the following commands, for rails >= 5

    bundle install
    rails g active_scaffold:install
    rails db:create
    rails g active_scaffold:resource Model [attrs]
    rails db:migrate
    

Run the app and visit localhost:3000/<plural_model>

Threadsafe
----------

Threadsafe can be enabled calling ActiveScaffold.threadsafe! in an initializer.
 It should be enabled on app start and it can't be disabled. Threadsafety is a
 new feature and not well tested yet.  

Configuration
-------------
See Wiki for instructions on customising ActiveScaffold and to find the full API details.

Credits
-------
ActiveScaffold grew out of a project named Ajaxscaffold dating back to 2006. It has had numerous contributors including:

ActiveScaffold Gem/Plugin by Scott Rutherford (scott@caronsoftware.com), Richard White (rrwhite@gmail.com), Lance Ivy (lance@cainlevy.net), Ed Moss, Tim Harper and Sergio Cambra (sergio@programatica.es)

Uses DhtmlHistory by Brad Neuberg (bkn3@columbia.edu)
http://codinginparadise.org

Uses Querystring by Adam Vandenberg
http://adamv.com/dev/javascript/querystring

Uses Paginator by Bruce Williams
http://paginator.rubyforge.org/

Supports RecordSelect by Lance Ivy and Sergio Cambra
http://github.com/scambra/recordselect/


License
=======
Released under the MIT license (included)

---

A ruby translation project managed on [Locale](http://www.localeapp.com/) that's open to all!

## Contributing to active_scaffold

- Edit the translations directly on the [active_scaffold](http://www.localeapp.com/projects/public?search=active_scaffold) project on Locale.
- **That's it!**
- The maintainer will then pull translations from the Locale project and push to Github.

Happy translating!
