var action_link_close = ActiveScaffold.ActionLink.Abstract.prototype.close;
ActiveScaffold.ActionLink.Abstract.prototype.close = function() {
  this.adapter.select('textarea.mceEditor').each(function(elem) {
    tinyMCE.execCommand('mceRemoveEditor', false, elem.id);
  }); 
  action_link_close.apply(this);
};
