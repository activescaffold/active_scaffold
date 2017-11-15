var action_link_close = ActiveScaffold.ActionLink.Abstract.prototype.close;
ActiveScaffold.ActionLink.Abstract.prototype.close = function() {
  this.adapter.select('textarea.mceEditor').each(function(elem) {
    tinymce.remove('#'+elem.id);
  }); 
  action_link_close.apply(this);
};
document.on('submit', 'form.as_form', function() {
  tinymce.triggerSave();
  this.select('textarea.mceEditor').each(function(elem) { tinymce.remove('#'+elem.id); });
});
/* for persistent update forms */
document.on('ajax:complete', 'form.as_form', function(event) {
  this.select('textarea.mceEditor').each(function(elem) {
    tinyMCE.execCommand('mceAddEditor', false, elem.id);
  });
});