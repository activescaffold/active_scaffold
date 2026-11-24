
# Overview
[![Build status](https://github.com/activescaffold/active_scaffold/actions/workflows/ci.yml/badge.svg)](https://github.com/activescaffold/active_scaffold/actions/workflows/ci.yml)
[![Maintainability](https://qlty.sh/gh/activescaffold/projects/active_scaffold/maintainability.svg)](https://qlty.sh/gh/activescaffold/projects/active_scaffold)
[![Code Coverage](https://qlty.sh/gh/activescaffold/projects/active_scaffold/coverage.svg)](https://qlty.sh/gh/activescaffold/projects/active_scaffold)
[![Gem Version](https://badge.fury.io/rb/active_scaffold.svg)](https://badge.fury.io/rb/active_scaffold)
[![Translation Status](https://hosted.weblate.org/widget/activescaffold/svg-badge.svg)](https://hosted.weblate.org/engage/activescaffold/)
[![Inline docs](https://inch-ci.org/github/activescaffold/active_scaffold.svg?branch=master)](https://inch-ci.org/github/activescaffold/active_scaffold)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

ActiveScaffold provides a quick and powerful user interfaces for CRUD (create, read, update, delete) operations for Rails applications. It offers additonal features including searching, pagination & layout control. Rails >= 8.1.0 is supported, ruby >= 3.3 required.

## Branch Details

master supports rails >= 8.1.x and ruby >= 3.3.0
4-4-stable supports rails >= 7.2.x and <= 8.1.x, and ruby >= 3.2.0
4-3-stable supports rails >= 7.2.x and <= 8.1.x, and ruby >= 3.2.0

These versions are not supported anymore:  
4-2-stable supports rails >= 7.2.x and <= 8.1.x, and ruby >= 3.2.0
4-1-stable supports rails >= 7.0.x and <= 7.2.x, and ruby >= 3.1.0  
4-0-stable supports rails >= 6.1.x and <= 7.2.x, and ruby >= 2.5.0  
3-7-stable supports rails >= 5.2.x and <= 7.1.x, and ruby >= 2.5.0  
3-6-stable supports rails >= 4.2.x and <= 6.1.x, and ruby >= 2.3.0  
3-5-stable supports rails >= 4.0.x and <= 5.1.x, and ruby >= 2.0.0  
3-4-stable supports rails >= 3.2.x and <= 4.2.x, and ruby >= 1.9.3  
3-3-stable supports rails 3.2.x and ruby >= 1.8  
rails-3.2 supports Rails 3.1 & 3.2, and is the current source of the 3.2.x line of gems.

## ORM Support

Active Record is the only fully supported ORM.

ActiveScaffold has a limited Mongoid compatibility layer for model metadata and read-query construction. Master checks
that Mongoid 9.1 fields and associations can be configured on Rails 8.1, and has unit coverage for Mongoid-specific
filtering, searching, sorting, pagination, includes, and association counts. This is not an end-to-end Mongoid CRUD
test suite, and a MongoDB-backed integration application is not currently included.

Create and update are not supported for Mongoid models. Those paths depend on Active Record-specific validation,
association, and save extensions which are installed only on Active Record models. Delete happens to use the generic
`destroy` API, but is not covered by Mongoid integration tests and must also be considered unsupported. Association
forms, nested writes, inline updates, and other write features have the same limitation.

Even read-only scaffolds are not currently plug-and-play: authorization and label extensions are installed on Active
Record models only. Applications experimenting with Mongoid must provide the corresponding model/controller hooks and
should limit the scaffold to read actions. The following is a starting point, not a declaration of full support:

```ruby
gem 'mongoid', '~> 9.1'

# In the ActiveScaffold controller configuration:
config.actions.exclude :create, :update, :delete, :nested, :subform
```

ActiveScaffold's Mongoid compatibility tests use model and association metadata without requiring a running MongoDB
server. Applications still need MongoDB for persistence and queries.

ActiveMongoid is not supported. Its final release depends on the obsolete `bson_ext` native extension, which does not
build on the Ruby versions supported by master, and it has no release compatible with the current Mongoid API.

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

On supported Rails versions (8.1 and newer), the install generator adds the ActiveScaffold route concerns and the lines required to load its JavaScript and stylesheets for the detected asset pipeline. With import maps, this includes both the pins in `config/importmap.rb` and the imports in `app/javascript/application.js`. With Propshaft, it adds the required helpers to the application layout; with Sprockets, it updates the asset manifests instead.

For Dart Sass, the generator adds the appropriate `@use` line to `app/assets/stylesheets/application.scss`. It can also update an older `application.css` or `application.css.erb` that contains Sprockets require directives. If `jquery-rails` is installed, the generator adds `jquery` and `jquery_ujs` to the same JavaScript setup. The exact lines for each supported setup are described in [Stylesheet Loading](#stylesheet-loading) and [Javascript Loading](#javascript-loading).

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

In the layout, load the importmap modules and call active_scaffold_javascript_tag, that includes some script tags that were in js.erb when using sprockets, so JS ActiveScaffold dependencies are loaded (jquery UI if using jquery-ui-rails, and JS for other ActiveScaffold plugins and bridges): 

```erb
    <%= javascript_importmap_tags %>
    <%= active_scaffold_javascript_tag %>
```

### Propshaft without import maps

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

### Testing JavaScript in ActiveScaffold plugins

ActiveScaffold includes an opt-in Rails system-test application for plugin JavaScript. It is not loaded by
ActiveScaffold in applications. A plugin test suite can load it explicitly after loading the plugin:

```ruby
require 'rails'
require 'active_scaffold'
require 'my_active_scaffold_plugin'
require 'active_scaffold/test_support/javascript'

class PluginJavascriptTest < ActiveScaffold::TestSupport::Javascript::TestCase
  def fixture_html
    '<div class="my-plugin">Plugin fixture</div>'
  end

  def test_initializes_the_fixture
    visit_javascript_fixture

    assert_javascript 'document.querySelector(".my-plugin").pluginInitialized'
    assert_no_javascript_errors
  end
end
```

Load the plugin before the test support so its engine and assets are present when the reusable application boots.
Plugin test bundles must include `propshaft`, `jquery-rails`, `capybara`, `selenium-webdriver`, and `puma`. These are
test dependencies and do not need to be runtime dependencies of the plugin. The base uses a headless Chrome browser
and the real Rails asset paths, jQuery, UJS, ActiveScaffold loader, and registered plugin assets. It also provides
`insert_fixture_html`, `trigger_active_scaffold_event`, `assert_javascript`, and `assert_no_javascript_errors`.

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

The default response formats are `html`, `js`, `json`, and `xml`. To change them for the application, configure the defaults in an initializer before controllers are loaded:

```ruby
ActiveScaffold::Config::Core.default_formats = %i[html js]
```

Override these defaults for an individual controller inside its `active_scaffold` block:

```ruby
active_scaffold do |config|
  config.default_formats = %i[html js]
end
```

The existing `config.formats` and action settings such as `config.list.formats` add formats to these defaults. Removing a format from `default_formats` does not disable it if it is explicitly added elsewhere. Actions with a fixed set of formats, such as JavaScript subform rendering, keep their own formats.

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

A ruby translation project managed on [Weblate](http://weblate.org/) that's open to all!

## Contributing to ActiveScaffold

- Edit the translations directly on the [active_scaffold](https://hosted.weblate.org/engage/activescaffold/) project on Weblate.
- **That's it!**
- Weblate will send a PR to Github.

Happy translating!

### Powered by
[![RubyMine logo](https://resources.jetbrains.com/storage/products/company/brand/logos/RubyMine.png)](https://jb.gg/OpenSource)

### API association exports

JSON and XML responses export each readable associated record as a hash containing its
primary key and `to_label`. Unreadable singular records become `null`; unreadable records
in collections are omitted. The primary key and label do not require column authorization checks.
By default, associations are not expanded recursively, and no associated scaffold
configuration is loaded.

Override `api_association_options(column, record)` to return the options passed directly to
Rails' `serializable_hash`, including `only:`, `except:`, `methods:`, and `include:`. For example:

```ruby
protected

def api_association_options(column, record)
  if column.name == :company
    {only: [record.class.primary_key, :name], methods: [:to_label]}
  else
    super
  end
end
```

The serializer checks associated record read authorization but does not authorize the fields
selected by these options. If additional fields need column read authorization, filter them
explicitly in the override:

```ruby
protected

def api_association_options(column, record)
  options = super
  if column.name == :company
    columns = %i[name email].select do |name|
      record.authorized_for?(crud_type: :read, column: name)
    end
    options = options.merge(only: Array(options[:only]) + columns)
  end
  options
end
```

This preserves the default primary key and label and checks permissions only for the extra
fields. Choose label and virtual methods that expose data appropriate for your API.

Applications can explicitly request nested data using `include:` (singular):

```ruby
def api_association_options(column, record)
  options = super
  if column.name == :company
    options = options.merge(include: {address: {only: [:city, :country]}})
  end
  options
end
```

Nested includes use Rails' normal serialization. Applications are responsible for authorizing
all nested records and fields they request. `serializable_hash` does not check those permissions;
using an unrestricted `include:` can export every database attribute of nested records.
For JSON, the parent uses `as_json` to preserve its model root, while associated records use
`serializable_hash`, matching Rails' nested `include:` behavior and avoiding extra model roots.

The legacy full-attribute association output and its `unsafe_api_associations` compatibility
setting from 4.4 are removed in 4.5. Remove that setting when upgrading.
