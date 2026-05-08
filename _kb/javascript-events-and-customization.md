---
title: "Javascript Events and Customization"
category: "Customization"
---

If you add some form overrides with should have a JS callback, such as clicking an item, you shouldn't add the javascript code to your helper, you would do better setting a class and using unobtrusive js. You can use something like this in a JS file included in your manifest:

{% highlight js -%}
(function($) {
  $(document).on('click', 'your_custom_class', function() {
    // custom code on clicking item
  });
})(jQuery);
{%- endhighlight %}

The example is using jQuery 1.7, but it shouldn't be hard to do the same in Prototype.

If you need to run some JS code on displaying a form, such as adding a icon to show descriptions on hover or clicking, you can bind as:success_action and check action_link.adapter (it could be an action like delete, which doesn't open an adapter). You should run that code on document ready too, because links can be open in a new window.

{% highlight js -%}
(function($) {
  function createTooltipButtons(adapter) {
    $('form.as_form .description', adapter || document).before($('<a href="#" class="tooltip">')).hide();
  }
  $(document).on('click', 'form.as_form .tooltip', function(e) {
    e.preventDefault();
    $(this).next('.description').toggle();
  });
  // as:action_success => action link is clicked and form/nested list is open (form is in action_link.adapter)
  $(document).on('as:action_success', 'a.as_action', function(e, action_link) {
    if (action_link.adapter) {
      createTooltipButtons(action_link.adapter);
    }
  });
  // as:element_updated => form updated because validations fail
  //                       form field changed because a chained field changed
  //                       ajax inplace edit is open
  //                       singular subform is replaced
  //                       list is refreshed
  // as:element_created => subform record in a plural subform is added
  //                       new record row added to list
  $(document).on('as:element_updated as:element_created', function(e) {
    createTooltipButtons(e.target); 
  });
  $(document).ready(function() {
    createTooltipButtons();
  });
})(jQuery);
{%- endhighlight %}
