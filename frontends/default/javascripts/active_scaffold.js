if (typeof Prototype == 'undefined')
{
  warning = "ActiveScaffold Error: Prototype could not be found. Please make sure that your application's layout includes prototype.js (e.g. <%= javascript_include_tag :defaults %>) *before* it includes active_scaffold.js (e.g. <%= active_scaffold_includes %>).";
  alert(warning);
}
if (Prototype.Version.substring(0, 8) == '1.5.0_rc')
{
  warning = "ActiveScaffold Error: Prototype 1.5.0_rc is not supported. Please update prototype.js (rake rails:update:javascripts).";
  alert(warning);
}

/*
 * Simple utility methods
 */

var ActiveScaffold = {
  stripe: function(tableBody) {
    var even = false;
    var tableBody = $(tableBody);
    var tableRows = tableBody.down("tr");
    var length = tableBody.rows.length;

    for (var i = 0; i < length; i++) {
      var tableRow = tableBody.rows[i];
      //Make sure to skip rows that are create or edit rows or messages
      if (!tableRow.hasClassName("create")
        && !tableRow.hasClassName("update")
        && !tableRow.hasClassName("inline-adapter")
        && !tableRow.hasClassName("active-scaffold-calculations")) {

        if (even) {
          tableRow.addClassName("even-record");
        } else {
          tableRow.removeClassName("even-record");
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
  removeSortClasses: function(scaffold_id) {
    $$('#' + scaffold_id + ' td.sorted').each(function(element) {
      element.removeClassName("sorted");
    });
    $$('#' + scaffold_id + ' th.sorted').each(function(element) {
      element.removeClassName("sorted");
      element.removeClassName("asc");
      element.removeClassName("desc");
    });
  },
  decrement_record_count: function(scaffold_id) {
    count = $$('#' + scaffold_id + ' span.active-scaffold-records').first();
    count.innerHTML = parseInt(count.innerHTML) - 1;
  },
  increment_record_count: function(scaffold_id) {
    count = $$('#' + scaffold_id + ' span.active-scaffold-records').first();
    count.innerHTML = parseInt(count.innerHTML) + 1;
  },

  server_error_response: '',
  report_500_response: function(active_scaffold_id) {
    messages_container = $(active_scaffold_id).down('td.messages-container');
    new Insertion.Top(messages_container, this.server_error_response);
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
    /* patch to fix <form> replaces in Firefox. see http://dev.rubyonrails.org/ticket/8010 */
    range.selectNodeContents(element.parentNode);
    element.parentNode.replaceChild(range.createContextualFragment(html.stripScripts()), element);
  }
  setTimeout(function() {html.evalScripts()}, 10);
  return element;
};

/*
 * URL modification support. Incomplete functionality.
 */
Object.extend(String.prototype, {
  append_params: function(params) {
    url = this;
    if (url.indexOf('?') == -1) url += '?';
    else if (url.lastIndexOf('&') != url.length) url += '&';

    url += $H(params).collect(function(item) {
      return item.key + '=' + item.value;
    }).join('&');

    return url;
  }
});

/*
 * Prototype's implementation was throwing an error instead of false
 */
Element.Methods.Simulated = {
  hasAttribute: function(element, attribute) {
    var t = Element._attributeTranslations;
    attribute = t.names[attribute] || attribute;
    // Return false if we get an error here
    try {
      return $(element).getAttributeNode(attribute).specified;
    } catch (e) {
      return false;
    }
  }
};

/**
 * A set of links. As a set, they can be controlled such that only one is "open" at a time, etc.
 */
ActiveScaffold.Actions = new Object();
ActiveScaffold.Actions.Abstract = function(){}
ActiveScaffold.Actions.Abstract.prototype = {
  initialize: function(links, target, loading_indicator, options) {
    this.target = $(target);
    this.loading_indicator = $(loading_indicator);
    this.options = options;
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
ActiveScaffold.ActionLink = new Object();
ActiveScaffold.ActionLink.Abstract = function(){}
ActiveScaffold.ActionLink.Abstract.prototype = {
  initialize: function(a, target, loading_indicator) {
    this.tag = $(a);
    this.url = this.tag.href;
    this.target = target;
    this.loading_indicator = loading_indicator;
    this.hide_target = false;
    this.position = this.tag.getAttribute('position');
		this.page_link = this.tag.getAttribute('page_link');

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

    if (this.tag.hasAttribute( "dhtml_confirm")) {
      if (this.onclick) this.onclick();
      return;
    } else {
      if (this.onclick && !this.onclick()) return;//e.g. confirmation messages
      this.open_action();
    }
  },

	open_action: function() {
		if (this.position) this.disable();

		if (this.page_link) {
			window.location = this.url;
		} else {
			this.loading_indicator.style.visibility = 'visible';
	    new Ajax.Request(this.url, {
	      asynchronous: true,
	      evalScripts: true,

	      onSuccess: function(request) {
	        if (this.position) {
	          this.insert(request.responseText);
	          if (this.hide_target) this.target.hide();
	        } else {
	          request.evalResponse();
	        }
	      }.bind(this),

	      onFailure: function(request) {
	        ActiveScaffold.report_500_response(this.scaffold_id());
	        if (this.position) this.enable()
	      }.bind(this),

	      onComplete: function(request) {
	        this.loading_indicator.style.visibility = 'hidden';
	      }.bind(this)
			});
		}
	},

  insert: function(content) {
    throw 'unimplemented'
  },

  close: function() {
    this.enable();
    this.adapter.remove();
    if (this.hide_target) this.target.show();
  },

  register_cancel_hooks: function() {
    // anything in the insert with a class of cancel gets the closer method, and a reference to this object for good measure
    var self = this;
    this.adapter.getElementsByClassName('cancel').each(function(elem) {
      elem.observe('click', this.close_handler.bind(this));
      elem.link = self;
    }.bind(this))
  },

  reload: function() {
    this.close();
    this.open();
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
  },

  scaffold_id: function() {
    return this.tag.up('div.active-scaffold').id;
  }
}

/**
 * Concrete classes for record actions
 */
ActiveScaffold.Actions.Record = Class.create();
ActiveScaffold.Actions.Record.prototype = Object.extend(new ActiveScaffold.Actions.Abstract(), {
  instantiate_link: function(link) {
    var l = new ActiveScaffold.ActionLink.Record(link, this.target, this.loading_indicator);
    l.refresh_url = this.options.refresh_url;
    if (l.position) l.url = l.url.append_params({adapter: '_list_inline_adapter'});
    l.set = this;
    return l;
  }
});

ActiveScaffold.ActionLink.Record = Class.create();
ActiveScaffold.ActionLink.Record.prototype = Object.extend(new ActiveScaffold.ActionLink.Abstract(), {
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

    this.adapter.down('a.inline-adapter-close').observe('click', this.close_handler.bind(this));
    this.register_cancel_hooks();

    new Effect.Highlight(this.adapter.down('td'));
  },

  close_handler: function(event) {
    this.close_with_refresh();
    if (event) Event.stop(event);
  },

  /* it might simplify things to just override the close function. then the Record and Table links could share more code ... wouldn't need custom close_handler functions, for instance */
  close_with_refresh: function() {
    new Ajax.Request(this.refresh_url, {
      asynchronous: true,
      evalScripts: true,

      onSuccess: function(request) {
        Element.replace(this.target, request.responseText);
        var new_target = $(this.target.id);
        if (this.target.hasClassName('even-record')) new_target.addClassName('even-record');
        this.target = new_target;
        this.close();
      }.bind(this),

      onFailure: function(request) {
        ActiveScaffold.report_500_response(this.scaffold_id());
      }
    });
  },

  enable: function() {
    this.set.links.each(function(item) {
      if (item.url != this.url) return;
      item.tag.removeClassName('disabled');
    }.bind(this));
  },

  disable: function() {
    this.set.links.each(function(item) {
      if (item.url != this.url) return;
      item.tag.addClassName('disabled');
    }.bind(this));
  }
});

/**
 * Concrete classes for table actions
 */
ActiveScaffold.Actions.Table = Class.create();
ActiveScaffold.Actions.Table.prototype = Object.extend(new ActiveScaffold.Actions.Abstract(), {
  instantiate_link: function(link) {
    var l = new ActiveScaffold.ActionLink.Table(link, this.target, this.loading_indicator);
    if (l.position) l.url = l.url.append_params({adapter: '_list_inline_adapter'});
    return l;
  }
});

ActiveScaffold.ActionLink.Table = Class.create();
ActiveScaffold.ActionLink.Table.prototype = Object.extend(new ActiveScaffold.ActionLink.Abstract(), {
  insert: function(content) {
    if (this.position == 'top') {
      new Insertion.Top(this.target, content);
      this.adapter = this.target.immediateDescendants().first();
    }
    else {
      throw 'Unknown position "' + this.position + '"'
    }

    this.adapter.down('a.inline-adapter-close').observe('click', this.close_handler.bind(this));
    this.register_cancel_hooks();

    new Effect.Highlight(this.adapter.down('td'));
  },

  close_handler: function(event) {
    this.close();
    if (event) Event.stop(event);
  }
});