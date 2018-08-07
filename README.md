Overview
========
[![Build status](https://travis-ci.org/activescaffold/active_scaffold.svg?branch=master)](https://travis-ci.org/activescaffold/active_scaffold)
[![Code Climate](https://codeclimate.com/github/activescaffold/active_scaffold/badges/gpa.svg)](https://codeclimate.com/github/activescaffold/active_scaffold)
[![Test Coverage](https://codeclimate.com/github/activescaffold/active_scaffold/badges/coverage.svg)](https://codeclimate.com/github/activescaffold/active_scaffold)
[![Dependency Status](https://gemnasium.com/activescaffold/active_scaffold.svg)](https://gemnasium.com/activescaffold/active_scaffold)
[![Gem Version](https://badge.fury.io/rb/active_scaffold.svg)](https://badge.fury.io/rb/active_scaffold)
[![Inline docs](https://inch-ci.org/github/activescaffold/active_scaffold.svg?branch=master)](https://inch-ci.org/github/activescaffold/active_scaffold)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

ActiveScaffold provides a quick and powerful user interfaces for CRUD (create, read, update, delete) operations for Rails applications. It offers additonal features including searching, pagination & layout control.  Rails >= 4.0.5 and < 5.2 is supported, ruby >= 2.1 supported, although it should work with ruby >= 2.0.0, it's too old and not tested. Ruby < 2.0.0 won't work.

Branch Details
--------------
3-4-stable supports rails >= 3.2.x and ruby >= 1.9.3  
3-3-stable supports rails >= 3.2.x and ruby >= 1.8  
rails-3.2 supports Rails 3.1 & 3.2, and is the current source of the 3.2.x line of gems.

Quick Start
-----------
To get started with a new Rails project

Added to Gemfile

    gem 'active_scaffold'

For rails >= 5.1, add

    gem 'jquery-rails'

Run the following commands

    bundle install
    rails g active_scaffold:install
    bundle exec rake db:create
    rails g active_scaffold:resource User name:string
    bundle exec rake db:migrate
    
Commands for Rails 5

    bundle install
    rails g active_scaffold:install
    rails db:create
    rails g active_scaffold:resource User name:string
    rails db:migrate
    

Run the app and visit localhost:3000/users

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
