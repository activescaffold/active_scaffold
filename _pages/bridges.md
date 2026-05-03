---
layout: home
title: Bridges
date: 2025-01-22 13:40:18.000000000 +01:00
permalink: "/bridges/"
nav_group: main
nav_order: 1
hero_heading: Bridges
hero_lead: Extend and integrate ActiveScaffold functionality effortlessly.
---
<div class="home-section">
<div class="wrapper" markdown="1">
# {{ page.title | escape }}

Bridges are connectors that integrate ActiveScaffold with other Rails gems. They enable seamless communication between ActiveScaffold and external libraries, making it easier to add features like rich text editor, file uploads, authorization or JS widgets such as RecordSelect or Chosen.

Unlike plugins, bridges depend on both ActiveScaffold and the external gem they connect with, working together to provide extended functionality.

### Paperclip Bridge​

Provides seamless support for file attachments using Paperclip, enabling users to upload and manage files directly through ActiveScaffold.

### CarrierWave Bridge​

Integrates CarrierWave for managing file uploads, allowing developers to handle file storage and display effortlessly.

### Dragonfly Bridge

Supports Dragonfly for dynamic asset processing, including image resizing, encoding, and other on-the-fly operations.
</div>
</div>

<div class="home-section home-section--accent">
  <div class="wrapper" markdown="1">
Why use Bridges?
----------------

<div class="home-columns">
<div class="home-column" markdown="1">
<span class="icon"><svg aria-hidden="true" class="e-font-icon-svg e-fas-expand-alt" viewBox="0 0 448 512" xmlns="http://www.w3.org/2000/svg"><path d="M212.686 315.314L120 408l32.922 31.029c15.12 15.12 4.412 40.971-16.97 40.971h-112C10.697 480 0 469.255 0 456V344c0-21.382 25.803-32.09 40.922-16.971L72 360l92.686-92.686c6.248-6.248 16.379-6.248 22.627 0l25.373 25.373c6.249 6.248 6.249 16.378 0 22.627zm22.628-118.628L328 104l-32.922-31.029C279.958 57.851 290.666 32 312.048 32h112C437.303 32 448 42.745 448 56v112c0 21.382-25.803 32.09-40.922 16.971L376 152l-92.686 92.686c-6.248 6.248-16.379 6.248-22.627 0l-25.373-25.373c-6.249-6.248-6.249-16.378 0-22.627z"></path></svg></span>
### Expand Features

Add powerful new functionalities like tracking changes, authorization and file uploads.
</div>

<div class="home-column" markdown="1">
<span class="icon"><svg aria-hidden="true" class="e-font-icon-svg e-far-handshake" viewBox="0 0 640 512" xmlns="http://www.w3.org/2000/svg"><path d="M519.2 127.9l-47.6-47.6A56.252 56.252 0 0 0 432 64H205.2c-14.8 0-29.1 5.9-39.6 16.3L118 127.9H0v255.7h64c17.6 0 31.8-14.2 31.9-31.7h9.1l84.6 76.4c30.9 25.1 73.8 25.7 105.6 3.8 12.5 10.8 26 15.9 41.1 15.9 18.2 0 35.3-7.4 48.8-24 22.1 8.7 48.2 2.6 64-16.8l26.2-32.3c5.6-6.9 9.1-14.8 10.9-23h57.9c.1 17.5 14.4 31.7 31.9 31.7h64V127.9H519.2zM48 351.6c-8.8 0-16-7.2-16-16s7.2-16 16-16 16 7.2 16 16c0 8.9-7.2 16-16 16zm390-6.9l-26.1 32.2c-2.8 3.4-7.8 4-11.3 1.2l-23.9-19.4-30 36.5c-6 7.3-15 4.8-18 2.4l-36.8-31.5-15.6 19.2c-13.9 17.1-39.2 19.7-55.3 6.6l-97.3-88H96V175.8h41.9l61.7-61.6c2-.8 3.7-1.5 5.7-2.3H262l-38.7 35.5c-29.4 26.9-31.1 72.3-4.4 101.3 14.8 16.2 61.2 41.2 101.5 4.4l8.2-7.5 108.2 87.8c3.4 2.8 3.9 7.9 1.2 11.3zm106-40.8h-69.2c-2.3-2.8-4.9-5.4-7.7-7.7l-102.7-83.4 12.5-11.4c6.5-6 7-16.1 1-22.6L367 167.1c-6-6.5-16.1-6.9-22.6-1l-55.2 50.6c-9.5 8.7-25.7 9.4-34.6 0-9.3-9.9-8.5-25.1 1.2-33.9l65.6-60.1c7.4-6.8 17-10.5 27-10.5l83.7-.2c2.1 0 4.1.8 5.5 2.3l61.7 61.6H544v128zm48 47.7c-8.8 0-16-7.2-16-16s7.2-16 16-16 16 7.2 16 16c0 8.9-7.2 16-16 16z"></path></svg></span>
### Integrate Seamlessly

Connect with popular Rails gems like CanCanCan, Paperclip and PaperTrail.
</div>

<div class="home-column" markdown="1">
<span class="icon"><svg aria-hidden="true" class="e-font-icon-svg e-far-clock" viewBox="0 0 512 512" xmlns="http://www.w3.org/2000/svg"><path d="M256 8C119 8 8 119 8 256s111 248 248 248 248-111 248-248S393 8 256 8zm0 448c-110.5 0-200-89.5-200-200S145.5 56 256 56s200 89.5 200 200-89.5 200-200 200zm61.8-104.4l-84.9-61.7c-3.1-2.3-4.9-5.9-4.9-9.7V116c0-6.6 5.4-12 12-12h32c6.6 0 12 5.4 12 12v141.7l66.8 48.6c5.4 3.9 6.5 11.4 2.6 16.8L334.6 349c-3.9 5.3-11.4 6.5-16.8 2.6z"></path></svg></span>
### Save Time

Avoid reinventing the wheel by leveraging pre-built extensions.
</div>

<div class="home-column" markdown="1">
<span class="icon"><svg aria-hidden="true" class="e-font-icon-svg e-fas-paint-brush" viewBox="0 0 512 512" xmlns="http://www.w3.org/2000/svg"><path d="M167.02 309.34c-40.12 2.58-76.53 17.86-97.19 72.3-2.35 6.21-8 9.98-14.59 9.98-11.11 0-45.46-27.67-55.25-34.35C0 439.62 37.93 512 128 512c75.86 0 128-43.77 128-120.19 0-3.11-.65-6.08-.97-9.13l-88.01-73.34zM457.89 0c-15.16 0-29.37 6.71-40.21 16.45C213.27 199.05 192 203.34 192 257.09c0 13.7 3.25 26.76 8.73 38.7l63.82 53.18c7.21 1.8 14.64 3.03 22.39 3.03 62.11 0 98.11-45.47 211.16-256.46 7.38-14.35 13.9-29.85 13.9-45.99C512 20.64 486 0 457.89 0z"></path></svg></span>
### Customize Easily

Tailor bridges to fit the unique requirements of your application.
</div>
</div>
</div>
</div>

<div class="home-section">
<div class="wrapper" markdown="1">
How to Get Started
------------------

1. Add the bridge gem to your Gemfile. For example:
   {% highlight ruby -%}
   gem 'paperclip'
   {%- endhighlight %}

{:start="2"}
2. Run bundle install to install the dependencies:
   {% highlight shell -%}
   bundle install
   {%- endhighlight %}

{:start="3"}
3. Configure the gem in your application according to the documentation.

4. Restart your Rails server and enjoy the new features.
</div>
</div>