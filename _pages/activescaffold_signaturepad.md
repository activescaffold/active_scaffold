---
layout: page
title: ActiveScaffoldSignaturePad
date: 2025-02-18 11:51:33.000000000 +01:00
permalink: "/plugins/activescaffoldsignaturepad/"
parent: Plugins
hero_heading: Signature UI for ActiveScaffold
hero_lead: Integrates a signature pad into forms
---

Integrates a signature pad into forms, enabling users to capture signatures directly within your application.

### Description

ActiveScaffoldSignaturePad integrates a digital signature pad into ActiveScaffold forms, allowing users to sign directly within the interface. This feature is useful for applications requiring digital approvals, agreements, or user authentication via handwritten signatures.

###  

### Installation

Add the following line to your `Gemfile`:

```
gem 'active_scaffold_signaturepad'
```

Then run:

```
bundle install
```

### Usage & Options

Enable the signature pad in your controller:

```
class AgreementsController < ApplicationController
  active_scaffold :agreement do |config|
    config.columns[:signature].form_ui << :signaturepad
    config.columns[:signature].options = {
      :width => 150, # canvas width, default 250
      :height => 55, # canvas height, default 100
      :line_colour => 'transparent' # colour for signature line on canvas, transparent for none
    }
  end
end
```

Available options: `line_colour`, `line_width`, `line_margin`, `line_top`, `bg_colour`, `pen_colour`, `pen_width`, `pen_cap`, `error_message_draw`.

See [jquery.signaturepad doc](https://github.com/thread-pond/signature-pad/blob/main/documentation.md#options) for reference about options.

If `error_message_draw` is a symbol it will be translated (using `as_` method, so it must be on active_scaffold namespace)

### Save image

Signaturepad sends a JSON representation to signature. It can be converted to image on server, adding some code to model:
[https://gist.github.com/branch14/4258871](https://gist.github.com/branch14/4258871)
