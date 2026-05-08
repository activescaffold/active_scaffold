---
title: "RESTful Scaffolding"
category: "Getting Started"
---

## Introduction
ActiveScaffold handle all the REST operations. Active scaffold supports by default the following formats:
- HTML
- js
- XML
- json
- yaml

ActiveScaffold defines a number of methods above and beyond the standard RESTful CRUD. All of this extra configuration has been packaged up in a flag that you can set in your routes.rb. To configure a RESTful scaffold, make a resources entry like the below:

{% highlight ruby -%}
resources :users, concerns: :active_scaffold
{%- endhighlight %}

## Examples
We suppose a common "thing" resource.

### GET the thing with id 1 in XML
GET `http://my-server/things/1.xml`
### GET the thing with id 3 in YAML
GET `http://my-server/things/3.yaml`
### GET the things with property "special" in YAML
GET `http://my-server/things.yaml?property=special`
### PUT a new thing in XML
- PUT `http://my-server/things.xml`
- data = `<?xml version='1.0' encoding='UTF-8'?><record><designation>special thing</designation><quantity>3</quantity></record>`
- content_type => :xml

**NOTE**: you must use "record" as the root element, regardless of the name of your resource.
### PUT a new thing in JSON
- PUT `http://my-server/things.json`
- data = `{record:{"designation":"special thing","quantity":3}}`
- content_type => :json

**NOTE**: you must use "record" as the root element, regardless of the name of your resource.
