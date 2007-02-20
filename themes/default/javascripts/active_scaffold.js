if (typeof Prototype == 'undefined')
{
  warning = "ActiveScaffold Error: Prototype could not be found. Please make sure that your application's layout includes prototype.js (e.g. <%= javascript_include_tag :defaults %>) *before* it includes active_scaffold.js (e.g. <%= active_scaffold_includes %>).";
  alert(warning);
}

/*
 * Simple utility methods
 */

var ActiveScaffold = {
  stripe: function(tableBody) {
    var even = false;
    var tableBody = $(tableBody);
    var tableRows = tableBody.getElementsByTagName("tr");
    var length = tableBody.rows.length;

    for (var i = 0; i < length; i++) {
      var tableRow = tableBody.rows[i];
      //Make sure to skip rows that are create or edit rows or messages
      if (!tableRow.hasClassName("create")
        && !tableRow.hasClassName("update")
        && !tableRow.hasClassName("inline-adapter")
        && !tableRow.hasClassName("active-scaffold-totals")) {

        if (even) {
          tableRow.addClassName("even");
        } else {
          tableRow.removeClassName("even");
        }
        even = !even;
      }
    }
  },
  toggleEmptyMessage: function(tableBody, emptyMessageElement) {
    // Check to see if this was the last element in the list
    if ($(tableBody).rows.length == 0) {
      $(emptyMessageElement).show();
    } else {
			$(emptyMessageElement).hide();
		}
  },
  removeSortClasses: function(active_scaffoldId) {
    $$('#' + active_scaffoldId + ' td.sorted').each(function(element) {
      element.removeClassName("sorted");
    });
    $$('#' + active_scaffoldId + ' th.sorted').each(function(element) {
      element.removeClassName("sorted");
      element.removeClassName("asc");
      element.removeClassName("desc");
    });
  },
  decrement_record_count: function(active_scaffoldId) {
    count = $$('#' + active_scaffoldId + ' span.active-scaffold-records').first();
    count.innerHTML = parseInt(count.innerHTML) - 1;
  },
  increment_record_count: function(active_scaffoldId) {
    count = $$('#' + active_scaffoldId + ' span.active-scaffold-records').first();
    count.innerHTML = parseInt(count.innerHTML) + 1;
  }
}

/*
 * Add-ons/Patches to Prototype
 */

/* patch to support replacing TR/TD/TBODY in Internet Explorer, courtesy of http://dev.rubyonrails.org/ticket/4273 */
Element.replace = function(element, html) {
  element = $(element);
  if (element.outerHTML) {
    try {
    element.outerHTML = html.stripScripts();
    } catch (e) {
      var tn = element.tagName;
      if(tn=='TBODY' || tn=='TR' || tn=='TD')
      {
              var tempDiv = document.createElement("div");
              tempDiv.innerHTML = '<table id="tempTable" style="display: none">' + html.stripScripts() + '</table>';
              element.parentNode.replaceChild(tempDiv.getElementsByTagName(tn).item(0), element);
      }
      else throw e;
    }
  } else {
    var range = element.ownerDocument.createRange();
    range.selectNodeContents(element);
    element.parentNode.replaceChild(range.createContextualFragment(html.stripScripts()), element);
  }
  setTimeout(function() {html.evalScripts()}, 10);
};

/*
 * URL modification support. Incomplete functionality.
 */
Object.extend(String.prototype, {
  append_params: function(params) {
    url = this;
    if (url.indexOf('?') == -1) url += '?';
    else if (url.indexOf('&') != url.length) url += '&';

    url += $H(params).collect(function(item) {
      return item.key + '=' + item.value;
    }).join('&');

    return url;
  }
});

/*
 * Nested Form... sorta
 */



Form.Pseudo = Class.create();
Form.Pseudo.prototype = {
  initialize: function(element, options) {
    this.element = $(element);
    this.href = $$("#" + this.element.id + " .form-action")[0].href;
    this.setOptions(options);

    // Put hook on buttons
    this.submitButtons = $$("#" + this.element.id + " .submit");
    for (var i=0; i < this.submitButtons.length; i++) {
      Event.observe(this.submitButtons[i], 'click', this.onSubmit.bindAsEventListener(this));
    }

    // find action uri for request
    this.formElements = Form.getElements(this.element);
    for (var i=0; i < this.formElements.length; i++) {
      Event.observe(this.formElements[i], 'keydown', this.onKeyPress.bindAsEventListener(this));
    }
  },

  setOptions: function(options) {
	this.options = { asynchronous: true,
                     evalScripts: true,
                     onLoading: this.onLoading.bindAsEventListener(this),
                     onLoaded: this.onComplete.bindAsEventListener(this) };
    Object.extend(this.options, options || {});
  },

  onKeyPress: function(event) {
    if (event.keyCode == Event.KEY_RETURN) {
      this.onSubmit(event);
    }
  },

  onLoading: function(request) {
    Form.disable(this.element);
  },

  onComplete: function(request) {
    Form.enable(this.element);
  },

  onSubmit: function(event) {
    var params = Object.extend(this.options, { parameters: Form.serialize(this.element) });
    new Ajax.Request(this.href, params);
    Event.stop(event);
  }
}

var PsuedoForm = {
  clear: function(element) {
    this.element = $(element);

    this.formElements = Form.getElements(this.element);
    for (var i=0; i < this.formElements.length; i++) {
      if (this.formElements[i].type.toLowerCase() != 'submit') {
        this.formElements[i].value = "";
      }
    }
  }
}

/**
 * A set of links. As a set, they can be controlled such that only one is "open" at a time, etc.
 */
Abstract.ActiveScaffoldActions = function(){}
Abstract.ActiveScaffoldActions.prototype = {
  initialize: function(links, target, loading_indicator) {
    this.target = $(target);
    this.loading_indicator = $(loading_indicator);
    this.links = links.collect(function(link) {
      return this.instantiate_link(link);
    }.bind(this));
  },

  instantiate_link: function(link) {
    throw 'unimplemented'
  }
}

/**
 * A DataStructures::ActionLink, represented in JavaScript.
 * Concerned with AJAX-enabling a link and adapting the result for insertion into the table.
 */
Abstract.ActiveScaffoldActionLink = function(){}
Abstract.ActiveScaffoldActionLink.prototype = {
  initialize: function(a, target, loading_indicator) {
    this.tag = $(a);
    this.url = this.tag.href;
    this.target = target;
    this.loading_indicator = loading_indicator;
    this.hide_target = false;
    this.position = this.tag.getAttribute('position');

    this.onclick = this.tag.onclick;
    this.tag.onclick = null;
    this.tag.observe('click', function(event) {
      this.open();
      Event.stop(event);
    }.bind(this));


    this.tag.action_link = this;
  },

  open: function() {
    if (this.is_disabled()) return;
    if (this.onclick && !this.onclick()) return;//e.g. confirmation messages
    this.disable();
    this.loading_indicator.show();
    new Ajax.Request(this.url, {
      asynchronous: true,
      evalScripts: true,

      onSuccess: function(request) {
        if (this.position) {
          this.insert(request.responseText);
          if (this.hide_target) this.target.hide();
        }
      }.bind(this),

      onFailure: function(request) {
        this.enable()
      }.bind(this),

      onComplete: function(request) {
        this.loading_indicator.hide();
      }.bind(this)
    });
  },

  insert: function(content) {
    throw 'unimplemented'
  },

  close: function() {
    this.enable();
    this.adapter.remove();
    if (this.hide_target) this.target.show();
  },

  get_new_adapter_id: function() {
    var id = 'adapter_';
    var i = 0;
    while ($(id + i)) i++;
    return id + i;
  },

  enable: function() {
    return this.tag.removeClassName('disabled');
  },

  disable: function() {
    return this.tag.addClassName('disabled');
  },

  is_disabled: function() {
    return this.tag.hasClassName('disabled');
  }
}

/**
 * Concrete classes for record actions
 */
var ActiveScaffoldRecordActions = Class.create();
ActiveScaffoldRecordActions.prototype = Object.extend(new Abstract.ActiveScaffoldActions(), {
  instantiate_link: function(link) {
    var l = new ActiveScaffoldRecordActionLink(link, this.target, this.loading_indicator);
    if (l.position) l.url = l.url.append_params({adapter: '_list_inline_adapter'});
    l.set = this;
    return l;
  }
});

var ActiveScaffoldRecordActionLink = Class.create();
ActiveScaffoldRecordActionLink.prototype = Object.extend(new Abstract.ActiveScaffoldActionLink(), {
  insert: function(content) {
    this.set.links.each(function(item) {
      if (item.url != this.url && item.is_disabled() && item.adapter) item.close();
    }.bind(this));

    if (this.position == 'replace') {
      this.position = 'after';
      this.hide_target = true;
    }

    if (this.position == 'after') {
      new Insertion.After(this.target, content);
      this.adapter = this.target.next();
    }
    else if (this.position == 'before') {
      new Insertion.Before(this.target, content);
      this.adapter = this.target.previous();
    }
    else {
      return false;
    }

    this.adapter.down('a.inline-adapter-close').observe('click', function(event) {
      this.close_with_refresh();
      Event.stop(event);
    }.bind(this));

    new Effect.Highlight(this.adapter.down('td'));
  },

  close_with_refresh: function() {
    new Ajax.Request(this.target.getAttribute('from'), {
      asynchronous: true,
      evalScripts: true,

      onSuccess: function(request) {
        Element.replace(this.target, request.responseText);
        var new_target = $(this.target.id);
        if (this.target.hasClassName('even')) new_target.addClassName('even');
        this.target = new_target;
        this.close();
      }.bind(this)
    });
  }
});

/**
 * Concrete classes for table actions
 */
var ActiveScaffoldTableActions = Class.create();
ActiveScaffoldTableActions.prototype = Object.extend(new Abstract.ActiveScaffoldActions(), {
  instantiate_link: function(link) {
    var l = new ActiveScaffoldTableActionLink(link, this.target, this.loading_indicator);
    l.url = l.url.append_params({adapter: '_list_inline_adapter'});
    return l;
  }
});

var ActiveScaffoldTableActionLink = Class.create();
ActiveScaffoldTableActionLink.prototype = Object.extend(new Abstract.ActiveScaffoldActionLink(), {
  insert: function(content) {
    if (this.position == 'top') {
      new Insertion.Top(this.target, content);
      this.adapter = this.target.immediateDescendants().first();
    }
    else {
      throw 'Unknown position "' + this.position + '"'
    }

    this.adapter.down('a.inline-adapter-close').observe('click', function(event) {
      this.close();
      Event.stop(event);
    }.bind(this));

    new Effect.Highlight(this.adapter.down('td'));
  }
});