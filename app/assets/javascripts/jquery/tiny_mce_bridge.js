var action_link_close = ActiveScaffold.ActionLink.Abstract.prototype.close;       

(function($){

ActiveScaffold.ActionLink.Abstract.prototype.close = function() {
  $(this.adapter).find('textarea.mceEditor').each(function(index, elem) {         
    tinyMCE.execCommand('mceRemoveControl', false, $(elem).attr('id'));
  });
  action_link_close.apply(this);  
};

})(jQuery);