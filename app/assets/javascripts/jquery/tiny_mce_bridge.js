var tiny_mce_settings = {};

(function() {
  var action_link_close = ActiveScaffold.ActionLink.Abstract.prototype.close;
  ActiveScaffold.ActionLink.Abstract.prototype.close = function() {
    jQuery(this.adapter).find('textarea.mceEditor').each(function(index, elem) {
      tinyMCE.remove('#' + jQuery(elem).attr('id'));
    });
    action_link_close.apply(this);
  };

  function loadTinyMCE() {
    var settings = jQuery(this).data('tinymce');
    for (key in tiny_mce_settings) {
      settings[key] = tiny_mce_settings[key];
    }
    if (settings) tinyMCE.settings = settings;
    tinyMCE.execCommand('mceAddEditor', false, jQuery(this).attr('id'));
  }

  jQuery(document).on('submit', 'form.as_form', function() {
    tinymce.triggerSave();
    jQuery('textarea.mceEditor', this).each(function() { tinymce.remove('#'+jQuery(this).attr('id')); });
  });
  /* for persistent update forms */
  jQuery(document).on('ajax:complete', 'form.as_form', function() {
    jQuery('textarea.mceEditor', this).each(loadTinyMCE);
  });
  /* enable tinymce textarea after form open */
  jQuery(document).on('as:action_success', 'a.as_action', function(event) {
    var action_link = ActiveScaffold.ActionLink.get(jQuery(this));
    if (action_link && action_link.adapter) {
      jQuery(action_link.adapter).find('textarea.mceEditor').each(loadTinyMCE);
    }
  });
})();
