(function() {
  var action_link_close = ActiveScaffold.ActionLink.Abstract.prototype.close;
  ActiveScaffold.ActionLink.Abstract.prototype.close = function() {
    jQuery(this.adapter).find('textarea.mceEditor').each(function(index, elem) {
      tinyMCE.remove('#' + jQuery(elem).attr('id'));
    });
    action_link_close.apply(this);
  };

  ActiveScaffold.remove_tinymce = function(element) {
    if (typeof(element) == 'string') element = '#' + element;
    element = jQuery(element);
    element.find('textarea.mceEditor').each(function(index, elem) {
      tinymce.remove('#' + elem.id);
    });
  };

  var as_replace = ActiveScaffold.replace,
    as_replace_html = ActiveScaffold.replace_html;

  ActiveScaffold.replace = function(element) {
    this.remove_tinymce(element);
    return as_replace.apply(this, arguments);
  };
  ActiveScaffold.replace_html = function(element) {
    this.remove_tinymce(element);
    return as_replace_html.apply(this, arguments);
  };

  function loadTinyMCE() {
    var global_settings = ActiveScaffold.config.tiny_mce_settings || {};
    var local_settings = jQuery(this).data('tinymce');
    var settings = {};
    for (let key in global_settings) {
      settings[key] = global_settings[key];
    }
    for (let key in local_settings) {
      settings[key] = local_settings[key];
    }
    var id = jQuery(this).attr('id');
    if (tinymce && tinymce.majorVersion >= 6) {
      settings.selector = '#' + id;
      var userSetup = settings.setup ? eval(settings.setup) : function () {};
      settings.setup = function(editor) {
        userSetup(editor);                  // run what the user already had

        /* keep textarea in sync */
        var sync = function() { editor.save(); };  // same as triggerSave()
        editor.on('change input NodeChange Undo Redo', sync);
      };
      tinymce.init(settings);
    } else { // tinyMCE.majorVersion < 6
      settings.init_instance_callback = function(editor) {
        var sync = function () { editor.save(); };   // same as triggerSave()
        editor.on('change input NodeChange Undo Redo', sync);
        if (userInit) userInit(editor);              // run user’s callback too
      };
      tinyMCE.settings = settings;
      tinyMCE.execCommand('mceAddEditor', false, id);
    }
  }
/*const sync = () => editor.save();   // same as triggerSave for this editor
        editor.on('change input NodeChange Undo Redo', sync);*/
  jQuery(document).on('submit', 'form.as_form', function() {
    tinymce.triggerSave();
    jQuery('textarea.mceEditor', this).each(function() { tinymce.remove('#'+jQuery(this).attr('id')); });
  });
  /* for persistent update forms */
  jQuery(document).on('ajax:complete', 'form.as_form', function() {
    jQuery('textarea.mceEditor', this).each(loadTinyMCE);
  });
  /* enable tinymce textarea after form open or page load */
  ActiveScaffold.setup_callbacks.push(function(container) {
    jQuery('textarea.mceEditor', container).each(loadTinyMCE);
  });
})();
