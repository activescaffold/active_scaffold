jQuery(document).ready(function() {
  jQuery(document).on('as:element_updated as:element_created', function(event) {
    jQuery('select.chosen', event.target).chosen();
  });
  jQuery(document).on('as:action_success', 'a.as_action', function(event, action_link) {
    if (action_link.adapter) {
      jQuery('select.chosen', action_link.adapter).chosen();
    }
  });
  jQuery('select.chosen').chosen();
});
