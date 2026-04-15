---
layout: page
title: ActiveScaffoldCamera
date: 2025-02-18 11:57:07.000000000 +01:00
permalink: "/plugins/activescaffoldcamera/"
---

ActiveScaffoldCamera
====================

Adds a camera interface to forms

ActiveScaffoldCamera
--------------------

Adds a camera interface to forms, letting users take snapshots directly from their devices and upload them.

### Description

ActiveScaffoldCamera adds a camera interface to ActiveScaffold forms, allowing users to capture and upload photos directly from their devices. It is ideal for applications requiring photo verification, profile pictures, or document scanning.

###  

### Installation

Add the following line to your `Gemfile`:

```
gem 'active_scaffold_camera'
```

Then run:

```
bundle install
```

### Usage & Options

Enable the camera functionality in your controller:

```
class ProfilesController < ApplicationController
  active_scaffold :profile do |config|
    config.actions << :camera
  end
end
```
### Example Code

```
config.camera.capture_mode = 'photo'
config.camera.quality = 80
```