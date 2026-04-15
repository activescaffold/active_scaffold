---
title: "I’m using ActiveScaffold, but it looks like a regular scaffold (ugly). Why?"
date: "2025-02-17 14:33:42.000000000 +01:00"
---

First thing to check is that you’re including the stylesheet in your layout. Refer back to the steps in <a href="https://github.com/activescaffold/active_scaffold/wiki/Getting-Started" class="internal present">Getting Started</a> to see how to include the stylesheet. And you should check the page source, too, to make sure the `<style>` tag is in there.

If you’ve got that, then check the views directory for your controller. If you’re using a PostsController, then check app/views/posts. Delete (or move) all views out if this directory. There’s a chance you may have run Rails’ built-in scaffold generator, and those views and partials are overriding ActiveScaffold’s own.

Still not working? Come ask in the forums, and mention that you’ve already checked this FAQ.
