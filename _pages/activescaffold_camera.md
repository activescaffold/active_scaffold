---
layout: page
title: ActiveScaffoldCamera
date: 2025-02-18 11:57:07.000000000 +01:00
permalink: "/plugins/activescaffoldcamera/"
parent: Plugins
hero_heading: Camera UI for ActiveScaffold
hero_lead: Adds camera input to forms
---

Adds a camera interface to forms, letting users take snapshots directly from their devices and upload them.

### Description

ActiveScaffoldCamera adds a camera interface to ActiveScaffold forms, allowing users to capture and upload photos directly from their devices. It is ideal for applications requiring photo verification, profile pictures, or document scanning.

###  

### Installation

Add the following line to your `Gemfile`:

{% highlight ruby -%}
gem 'active_scaffold_camera'
{%- endhighlight %}

Then run:

{% highlight shell -%}
bundle install
{%- endhighlight %}

### Usage & Options

Enable the camera functionality in your controller:

{% highlight ruby -%}
class ProfilesController < ApplicationController
  active_scaffold :profile do |config|
    config.columns[:id_card].form_ui = :snapshot, {source: -1}
  end
end
{%- endhighlight %}

Available options: video_not_supported, audio_not_supported, media_forbidden, source

Source can be set to use a specific source instead of displaying source selector. It must be the source index, and it can be negative index to start from end. If no device on that index, first device will be used.

The other options are error messages. If video_not_supported, audio_not_supported or media_forbidden are symbols they will be translated (using `as_` method, so it must be on `active_scaffold` namespace). They have a default translation.

### Save image

Snapshot form_ui sends a data url, encoded on base64, of the image, so it should be saved on column of blob type.
