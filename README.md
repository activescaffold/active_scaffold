Overview
========
[![Build status](https://travis-ci.org/activescaffold/active_scaffold.svg?branch=master)](https://travis-ci.org/activescaffold/active_scaffold)
[![Code Climate](https://codeclimate.com/github/activescaffold/active_scaffold/badges/gpa.svg)](https://codeclimate.com/github/activescaffold/active_scaffold)
[![Test Coverage](https://codeclimate.com/github/activescaffold/active_scaffold/badges/coverage.svg)](https://codeclimate.com/github/activescaffold/active_scaffold)
[![Dependency Status](https://gemnasium.com/activescaffold/active_scaffold.svg)](https://gemnasium.com/activescaffold/active_scaffold)
[![Gem Version](https://badge.fury.io/rb/active_scaffold.svg)](https://badge.fury.io/rb/active_scaffold)
[![Inline docs](https://inch-ci.org/github/activescaffold/active_scaffold.svg?branch=master)](https://inch-ci.org/github/activescaffold/active_scaffold)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

ActiveScaffold provides a quick and powerful user interfaces for CRUD (create, read, update, delete) operations for Rails applications. It offers additonal features including searching, pagination & layout control.  Rails 3.2 and 4.x are supported, ruby >= 1.9 required. For rails 4 is recommended >= 4.0.5.

Branch Details
--------------
rails-3.2 branch on Github supports Rails 3.1 & 3.2, and is the current source of the 3.2.x line of gems. The master branch (3.3.x) has dropped support for Rails 3.1

Quick Start
-----------
To get started with a new Rails project

Added to Gemfile

    gem 'active_scaffold'

Run the following commands

    bundle install
    bundle exec rake db:create
    rails g active_scaffold User name:string
    bundle exec rake db:migrate

Add the following line to app/assets/javascripts/application.js

    //= require active_scaffold

Add the following line to /app/assets/stylesheets/application.css

    *= require active_scaffold

Run the app and visit localhost:3000/users 

Configuration
-------------
See Wiki for instructions on customising ActiveScaffold and to find the full API details.

Compatibility Issues
--------------------
jQuery 1.9 deprecates some methods that rails-3.2 branch still uses (NB: jQuery 1.9 is supported in 3.3.x, the master branch). You'll therefore need to ensure you use jQuery 1.8. You can do this by fixing version in your Gemfile:

    gem 'jquery-rails', '2.1.4'

active_scaffold_batch plugin gem (versions 3.2.x) require 3.3.x (master branch). Therefore if you wish to try using active_scaffold_batch with this branch, you'll need to fork the project and edit the runtime dependency in the gemspec file (use at your own discretion)

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
