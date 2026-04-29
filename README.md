
# Overview
[![Build status](https://github.com/activescaffold/active_scaffold/actions/workflows/ci.yml/badge.svg)](https://github.com/activescaffold/active_scaffold/actions/workflows/ci.yml)
[![Maintainability](https://qlty.sh/gh/activescaffold/projects/active_scaffold/maintainability.svg)](https://qlty.sh/gh/activescaffold/projects/active_scaffold)
[![Code Coverage](https://qlty.sh/gh/activescaffold/projects/active_scaffold/coverage.svg)](https://qlty.sh/gh/activescaffold/projects/active_scaffold)
[![Gem Version](https://badge.fury.io/rb/active_scaffold.svg)](https://badge.fury.io/rb/active_scaffold)
[![Translation Status](https://hosted.weblate.org/widget/activescaffold/svg-badge.svg)](https://hosted.weblate.org/engage/activescaffold/)
[![Inline docs](https://inch-ci.org/github/activescaffold/active_scaffold.svg?branch=master)](https://inch-ci.org/github/activescaffold/active_scaffold)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

ActiveScaffold provides a quick and powerful user interfaces for CRUD (create, read, update, delete) operations for Rails applications. It offers additonal features including searching, pagination & layout control.  Rails >= 6.1.0 is supported, ruby >= 3.0 required.

## Branch Details

master supports rails >= 7.2.x and ruby >= 3.2.0  
4-2-stable supports rails >= 7.2.x and ruby >= 3.2.0

These versions are not supported anymore:  
4-1-stable supports rails >= 7.0.x and <= 7.2.x, and ruby >= 3.1.0  
4-0-stable supports rails >= 6.1.x and <= 7.2.x, and ruby >= 2.5.0  
3-7-stable supports rails >= 5.2.x and <= 7.1.x, and ruby >= 2.5.0  
3-6-stable supports rails >= 4.2.x and <= 6.1.x, and ruby >= 2.3.0  
3-5-stable supports rails >= 4.0.x and <= 5.1.x, and ruby >= 2.0.0  
3-4-stable supports rails >= 3.2.x and <= 4.2.x, and ruby >= 1.9.3  
3-3-stable supports rails 3.2.x and ruby >= 1.8  
rails-3.2 supports Rails 3.1 & 3.2, and is the current source of the 3.2.x line of gems.

## Quick Start
To get started with a new Rails project

Added to Gemfile

```ruby
gem 'active_scaffold'
```

Add jquery-rails to Gemfile, or handle jquery with other tools like webpack or importmap. Also it's possible to load jquery in your layout before application.js using CDN (e.g. jquery-rails-cdn). You can replace @rails/ujs with jquery_ujs, although @rails/ujs should work (never load both).

```ruby
gem 'jquery-rails'
```

For rails 7.x, install generator will add `active_scaffold` to `config/importmap.rb`, `app/javascript/application.js`, and `active_scaffold/manifest.js` to `app/assets/config/manifest.js`. It will add `jquery` and `jquery_ujs` to all the 3 files if jquery-rails gem is available.

For rails 6.1, install generator will create `app/assets/javascripts/application.js`, add it, and `active_scaffold/manifest.js`, to `app/assets/config/manifest.js` and add `javascript_include_tag` in the layout, as ActiveScaffold doesn't work with webpack. It will add `jquery` to `app/assets/javascripts/application.js` too if query-rails gem is available, although Jquery may be loaded by packs too and it will work, it won't add `jquery_ujs` or `@rails/ujs` as it's added to `app/javascript/packs/application.js` by default.

-- TODO: Add notes about dartsass-rails for propshaft or dartsass-sprockets for sprockets.

Run the following commands

```console
bundle install
rails g active_scaffold:install
rails db:create
rails g active_scaffold:resource Model [attrs]
rails db:migrate
```    

Run the app and visit localhost:3000/<plural_model>

It's recommended to call `clear_helpers` in ApplicationController, as some helpers defined by ActiveScaffold, such as active_scaffold_enum_options, options_for_association_conditions, association_klass_scoped, are usually overrided for different controllers, and it may cause issues when all helper modules are available to every controller, specially when models have associations or columns with the same name but need different code for those overrided helper methods.

## Stylesheet Loading

ActiveScaffold provides flexible stylesheet loading to work with both Sprockets and Propshaft, choose which want you want adding `dartsass-sprockets` or `dartsass-rails` to your Gemfile.
ActiveScaffold has SASS variables to define the colours, but, from version 4.3, the values are moved to CSS variables. It's still possible to change the colours with the old SASS variables, but they may be removed in the future.

### With Propshaft + dartsass-rails

Traditionally, ActiveScaffold loaded all CSS needed, from itself and other ActiveScaffold plugins, and every other library integrated with bridges, such as RecordSelect, Chosen or TinyMCE. It was done using css.erb files, but with propshaft erb is not supported, so a SCSS file is generated when app boots in development and running `rake assets:precompile` on the deployment. There is a task to generate them, `active_scaffold:assets:generate`.

Also, when using jquery-ui-rails gem, the CSS is generated from the erb in the gem in the same way.

```scss
// In application.scss
@use 'active_scaffold/core' with (
// set values to variables
);
```


### With Sprockets + dartsass-sprockets

Add `@use` to application.scss, it will load all CSS needed, jQuery UI if jquery-ui-rails gem is installed, and CSS for other ActiveScaffold plugins and bridges.

```scss
@use 'active_scaffold' with (
// set values to variables
);
```

In this case, if you want more flexibility, you have to use `@use` with each individual CSS file that ActiveScaffold provides:

```scss
@use 'active_scaffold/variables' with (
// set values to variables
);
@use 'active_scaffold/colours';
@use 'active_scaffold/layout';
@use 'active_scaffold/images';
// load CSS for other ActiveScaffold plugins and bridges
```

## Javascript Loading

There are 2 options to load JS with propshaft, using importmaps or loading the files individually.

### Propshaft + importmaps

When using importmaps, add active_scaffold to importmap, it should have jquery and jquery_ujs or rails_ujs too:

```ruby
pin 'active_scaffold', to: 'active_scaffold/load.js'
pin 'jquery'
pin 'jquery_ujs'
```

In the app/javascript/application.js, import jquery, jquery_ujs or rails_ujs and active_scaffold:

```js
import 'jquery'
import 'jquery_ujs'
import 'active_scaffold'
```

In the layout, load the importmap modules and call active_scaffold_javascript_tag, that includes some script tags which was in js.erb when using sprockets, so JS ActiveScaffold dependencies are loaded (jquery UI if using jquery-ui-rails, and JS for other ActiveScaffold plugins and bridges): 

```erb
    <%= javascript_importmap_tags %>
    <%= active_scaffold_javascript_tag %>
```

### Propshaft

If you're not using importmaps, then you can load the JS files individually, but you only need to load jquery and jquery_ujs or rails_ujs, and then call active_scaffold_javascript_tag:

```erb
    <%= javascript_include_tag 'jquery', 'jquery_ujs' %>
    <%= active_scaffold_javascript_tag %>
```

### With Sprockets

For the JS, you can keep using `//= require active_scaffold` in your application.js

It's possible to use importmaps too, add active_scaffold to importmap, that should have jquery and jquery_ujs or rails_ujs too:

```ruby
pin 'active_scaffold'
pin 'jquery'
pin 'jquery_ujs'
```

In the app/javascript/application.js, import jquery, jquery_ujs or rails_ujs and active_scaffold:

```js
import 'jquery'
import 'jquery_ujs'
import 'active_scaffold'
```

In the layout, load the importmap modules, in this case we are not using `to` in the importmap, so the js.erb file will be used, that include some generated code, and calling active_scaffold_javascript_tag is not needed.

Threadsafe
----------

Threadsafe is enabled always since 4.0, and it can't be disabled.  

Breaking Changes
----------------

When upgrading from 3.x, add `active_scaffold/manifest.js` to `app/assets/config/manifest.js` to prevent issues with assets.

Changing column settings on a request has changed, it must use `active_scaffold_config.columns.override(:name)` at least the first time. After calling `columns.override(:name)`, calling it again or calling `columns[:name]` will return the overrided column. It also supports a block. See [Per Request Configuration](https://github.com/activescaffold/active_scaffold/wiki/Per-Request-Configuration) for examples and more comprehensive explanation.

Changing columns for an action (e.g. add or exclude) on a request must use active_scaffold_config.action.override_columns, e.g. active_scaffold_config.list.override_columns, the first time, or use assignment.

If you have a `_form_association_record` partial view overrided, use `record` local variable instead of `form_association_record`.

If you have code rendering `form_association_record` partial, then pass `record` local variable, or use `as: :record` if using render with collection key.

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

## Contributing to ActiveScaffold

- Edit the translations directly on the [active_scaffold](http://www.localeapp.com/projects/public?search=active_scaffold) project on Locale.
- **That's it!**
- The maintainer will then pull translations from the Locale project and push to Github.

Happy translating!

### Powered by
[![RubyMine logo](https://resources.jetbrains.com/storage/products/company/brand/logos/RubyMine.png)](https://jb.gg/OpenSource)
