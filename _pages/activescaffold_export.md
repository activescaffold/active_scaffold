---
layout: page
title: ActiveScaffoldExport
date: 2025-02-18 11:34:51.000000000 +01:00
permalink: "/plugins/activescaffoldexport/"
parent: Plugins
---

ActiveScaffoldExport
====================

It's an essential tool for generating reports or sharing data with external systems.

ActiveScaffoldExport
--------------------

Add export functionality to your ActiveScaffold interfaces, supporting formats like CSV and Excel.
It's an essential tool for generating reports or sharing data with external systems.

### Description

ActiveScaffoldExport adds export functionality to your ActiveScaffold interfaces, allowing users to export data in formats like CSV and Excel. This is essential for generating reports or sharing data with other systems efficiently.

### Installation

```
gem 'active_scaffold_export'
```

Then run:

```
bundle install
```

### Usage & Options

Enable export in your controller:

```
class ProductsController < ApplicationController
  active_scaffold :product do |config|
    config.actions << :export
    config.export.columns = [:name, :price, :category]
  end
end
```
Customize additional options:

```
config.export.default_full_download = true
config.export.force_quotes = true
config.export.delimiter = ';'
config.export.include_header = true
```
### Example Code

To export products filtered by category:

```
class ProductsController < ApplicationController
  active_scaffold :product do |config|
    config.actions << :export
    config.export.columns = [:name, :price]
  end
  def before_export_save(file)
    file.write("Filtered by category: #{params[:category]}n")
  end
  def conditions_for_collection
    ['category = ?', params[:category]] if params[:category]
  end
end
```
