var action_link_close = ActiveScaffold.ActionLink.Abstract.prototype.close;       
ActiveScaffold.ActionLink.Abstract.prototype.close = function() {
  jQuery(this.adapter).find('textarea.mceEditor').each(function(index, elem) {         
    tinyMCE.execCommand('mceRemoveEditor', false, jQuery(elem).attr('id'));
  });
  action_link_close.apply(this);  
};
