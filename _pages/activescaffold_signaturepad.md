---
layout: page
title: ActiveScaffoldSignaturePad
date: 2025-02-18 11:51:33.000000000 +01:00
permalink: "/plugins/activescaffoldsignaturepad/"
parent: Plugins
---

ActiveScaffoldSignaturePad
==========================

Integrates a signature pad into forms

ActiveScaffoldSignaturePad
--------------------------

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
    config.actions << :signaturepad
  end
end
```
### Example Code

```
config.signaturepad.width = 400
config.signaturepad.height = 200
```
