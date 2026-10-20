(function() {
  function setupChoices(container) {
    if (typeof window.Choices === 'undefined') return;

    var choices_options = ActiveScaffold.config.choices_options || {};
    jQuery('select.as-choices', container).addBack('select.as-choices').each(function() {
      if (this.activeScaffoldChoices) {
        if (typeof this.activeScaffoldChoices.refresh === 'function') {
          this.activeScaffoldChoices.refresh();
        } else {
          this.activeScaffoldChoices.destroy();
          this.activeScaffoldChoices = new window.Choices(this, choices_options);
        }
      } else {
        this.activeScaffoldChoices = new window.Choices(this, choices_options);
      }
    });
  }

  ActiveScaffold.setup_callbacks.push(setupChoices);
  setupChoices(document);
})();
