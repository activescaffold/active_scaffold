(function() {
  function enableDraggableLists(element) {
    if (element.hasClass('draggable-list')) return;
    element.addClass('draggable-list');
    var list_selected = jQuery(element.get(0).cloneNode(false)).addClass('selected');
    list_selected.attr('id', list_selected.attr('id') + '_selected').insertAfter(element);
    element.find('input:checkbox').each(function(index, item) {
      var li = jQuery(item).closest('li').addClass('draggable-item');
      li.children('label').removeAttr('for');
      if (jQuery(item).is(':checked')) li.appendTo(list_selected);
    });
    var options = {
      hoverClass: 'hover',
      containment: '',
      receive: function(event, ui) {
        var input = jQuery('input:checkbox', ui.item), selected = input.prop('checked');
        input.prop('checked', jQuery(this).hasClass('selected'));
        if (selected != input.prop('checked')) input.trigger('change');
      }
    };
    jQuery(element).sortable(jQuery.extend(options, {connectWith: '#'+list_selected.attr('id')}));
    jQuery(list_selected).sortable(jQuery.extend(options, {connectWith: '#'+element.attr('id')}));
    return element;
  };
  jQuery.fn.draggableLists = function() {
    this.each(function() { enableDraggableLists(jQuery(this)); });
  };
})();
