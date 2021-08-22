jQuery(document).ready(function() {
  var chosen_options = ActiveScaffold.chosen_options || {};
  jQuery(document).on('as:element_updated as:element_created', function(event) {
    jQuery('select.chosen', event.target).chosen(chosen_options);
  });
  jQuery(document).on('as:action_success', 'a.as_action', function(event, action_link) {
    if (action_link.adapter) {
      jQuery('select.chosen', action_link.adapter).chosen(chosen_options);
    }
  });
  jQuery('select.chosen').chosen(chosen_options);
  jQuery(document).on('turbolinks:load', function($) {
    jQuery('select.chosen').chosen(chosen_options);
  });
});
