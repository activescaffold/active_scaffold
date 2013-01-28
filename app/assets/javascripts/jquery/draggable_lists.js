jQuery.fn.draggable_lists = function() {
  this.addClass('draggable-list');
  var list_selected = jQuery(this.get(0).cloneNode(false)).addClass('selected');
  list_selected.attr('id', list_selected.attr('id') + '_selected').insertAfter(this);
  this.find('input:checkbox').each(function(index, item) {
    var li = jQuery(item).closest('li').addClass('draggable-item');
    li.children('label').removeAttr('for');
    if (jQuery(item).is(':checked')) li.appendTo(list_selected);
    li.draggable({appendTo: 'body', helper: 'clone'});
  });
  jQuery([this, list_selected]).droppable({
    hoverClass: 'hover',
    accept: function(draggable) {
      var parent_id = draggable.parent().attr('id'), id = jQuery(this).attr('id'),
        requested_id = jQuery(this).hasClass('selected') ? id.replace('_selected', '') : id + '_selected';
      return parent_id == requested_id;
    },
    drop: function(event, ui) {
      jQuery(this).append(ui.draggable);
      var input = jQuery('input:checkbox', ui.draggable);
      input.prop('checked', jQuery(this).hasClass('selected'));
      ui.draggable.css({left: '0px', top: '0px'});
    }
  });
  return this;
};
