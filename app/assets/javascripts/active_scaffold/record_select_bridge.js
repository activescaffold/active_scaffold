(function(global) {
  global.RecordSelect.registerCallback('active_scaffold.add_existing', function(id) {
    global.ActiveScaffold.record_select_onselect(
      this.obj.attr('data-edit-associated-url'),
      this.obj.attr('data-active-scaffold-id'),
      id
    );
  });
})(window);
