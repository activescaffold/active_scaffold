---
title: "JS config"
category: "Customization"
---

You can configure some JS options. For it, set them in `ActiveScaffold.js_config` hash, in an initializer or application controller:

{% highlight ruby -%}
  ActiveScaffold.js_config = {...}
{%- endhighlight %}

## Highlight

You can change options for highlight effect.

{% highlight ruby -%}
  # For jquery highlight effect
  ActiveScaffold.js_config[:highlight] = {:color => "#ffff99"}
{%- endhighlight %}

## Scroll on close

When a form is closed, the row can be out of viewport, so you can enable scrolling to the row, either always or when is out of viewport.

{% highlight ruby -%}
  # Scroll element to top when is out of viewport
  ActiveScaffold.js_config = {:scroll_on_close => :checkInViewport}
  # Scroll element to top always
  ActiveScaffold.js_config = {:scroll_on_close => true}
{%- endhighlight %}

By default checkInViewport is set.
