if (typeof Prototype == 'undefined')
{
  warning = "ActiveScaffold Error: Prototype could not be found. Please make sure that your application's layout includes prototype.js (e.g. <%= javascript_include_tag :defaults %>) *before* it includes active_scaffold.js (e.g. <%= active_scaffold_includes %>).";
  alert(warning);
}
if (Prototype.Version.substring(0, 3) < '1.6')
{
  warning = "ActiveScaffold Error: Prototype version 1.6.x or higher is required. Please update prototype.js (rake rails:update:javascripts).";
  alert(warning);
}
if (!Element.Methods.highlight) Element.addMethods({highlight: Prototype.emptyFunction});


document.observe("dom:loaded", function() {
  Event.on($(document.body), 'ajax:before', 'form.as_form', function(event) {
    var as_form = event.findElement('form');
    if (as_form) {
      var loading_indicator = $(as_form.id.sub('--form', '-loading-indicator'));
      if (loading_indicator) loading_indicator.style.visibility = 'visible';
      as_form.disable();
    }
    return true;
  });
  Event.on($(document.body), 'ajax:complete', 'form.as_form', function(event) {
    var as_form = event.findElement('form');
    if (as_form) {
      var loading_indicator = $(as_form.id.sub('--form', '-loading-indicator'));
      if (loading_indicator) loading_indicator.style.visibility = 'hidden';
      as_form.enable();
      event.stop();
      return false;
    }
  });
  Event.on($(document.body), 'ajax:failure', 'form.as_form', function(event) {
    var as_div = event.findElement('div.activescaffold');
    if (as_div) {
      ActiveScaffold.report_500_response(as_div)
      event.stop();
      return false;
    }
  });
  Event.on($(document.body), 'ajax:before', 'a.as_action', function(event) {
    var as_action = event.findElement();
    if (as_action.action_link) {
      var action_link = as_action_link;
      if (action_link.loading_indicator) action_link.loading_indicator.style.visibility = 'visible';  
    }
    return true;
  });
  Event.on($(document.body), 'ajax:success', 'a.as_action', function(event) {
    var as_action = event.findElement();
    if (as_action.action_link && event.memo && event.memo.request) {
      var action_link = as_action.action_link;
      if (action_link.position) {
        action_link.insert(event.memo.request.responseText);
        if (action_link.hide_target) action_link.target.hide();
      } else {
        event.memo.request.evalResponse();
      }
      event.stop();
    }
    return true;
  });
  Event.on($(document.body), 'ajax:complete', 'a.as_action', function(event) {
    var as_action = event.findElement();
    if (as_action.action_link) {
      var action_link = as_action_link;
      if (action_link.loading_indicator) action_link.loading_indicator.style.visibility = 'hidden';  
    }
    return true;
  });
  Event.on($(document.body), 'ajax:failure', 'a.as_action', function(event) {
    var as_action = event.findElement();
    if (as_action.action_link) {
      var action_link = as_action_link;
      ActiveScaffold.report_500_response(action_link.scaffold_id());
      if (action_link.position) action_link.enable();
    }
    return true;
  });
  Event.on($(document.body), 'click', 'a.as_cancel', function(event) {
    var as_cancel = event.findElement('.as_adapter');
    if (as_cancel.action_link) {
      var action_link = as_cancel.action_link;
      action_link.close();
      event.stop();
    }
    return true;
  });
});


/*
 * Simple utility methods
 */

var ActiveScaffold = {
  records_for: function(tbody_id) {
    var rows = [];
    var child = $(tbody_id).down('.record');
    while (child) {
      rows.push(child);
      child = child.next('.record');
    }
    return rows;
  },
  stripe: function(tbody_id) {
    var even = false;
    var rows = this.records_for(tbody_id);
    for (var i = 0; i < rows.length; i++) {
      var child = rows[i];
      //Make sure to skip rows that are create or edit rows or messages
      if (child.tagName != 'SCRIPT'
        && !child.hasClassName("create")
        && !child.hasClassName("update")
        && !child.hasClassName("inline-adapter")
        && !child.hasClassName("active-scaffold-calculations")) {

        if (even) child.addClassName("even-record");
        else child.removeClassName("even-record");

        even = !even;
      }
    }
  },
  hide_empty_message: function(tbody, empty_message_id) {
    if (this.records_for(tbody).length != 0) {
      $(empty_message_id).hide();
    }
  },
  reload_if_empty: function(tbody, url) {
    if (this.records_for(tbody).length == 0) {
      new Ajax.Request(url, {
        method: 'get',
        asynchronous: true,
        evalScripts: true
      });
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
    // decrement the last record count, firsts record count are in nested lists
    count = $$('#' + scaffold_id + ' span.active-scaffold-records').last();
    if (count) count.update(parseInt(count.innerHTML, 10) - 1);
  },
  increment_record_count: function(scaffold_id) {
    // increment the last record count, firsts record count are in nested lists
    count = $$('#' + scaffold_id + ' span.active-scaffold-records').last();
    if (count) count.update(parseInt(count.innerHTML, 10) + 1);
  },
  update_row: function(row, html) {
    row = $(row);
    Element.replace(row, html);
    var new_row = $(row.id);
    if (row.hasClassName('even-record')) new_row.addClassName('even-record');
    new_row.highlight();
  },

  server_error_response: '',
  report_500_response: function(active_scaffold_id) {
    messages_container = $(active_scaffold_id).down('td.messages-container');
    new Insertion.Top(messages_container, this.server_error_response);
  }
}

/*
 * DHTML history tie-in
 */
function addActiveScaffoldPageToHistory(url, active_scaffold_id) {
  if (typeof dhtmlHistory == 'undefined') return; // it may not be loaded

  var array = url.split('?');
  var qs = new Querystring(array[1]);
  var sort = qs.get('sort')
  var dir = qs.get('sort_direction')
  var page = qs.get('page')
  if (sort || dir || page) dhtmlHistory.add(active_scaffold_id+":"+page+":"+sort+":"+dir, url);
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
    attribute = (t.names && t.names[attribute]) || attribute;
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
ActiveScaffold.Actions.Abstract = Class.create({
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
});

/**
 * A DataStructures::ActionLink, represented in JavaScript.
 * Concerned with AJAX-enabling a link and adapting the result for insertion into the table.
 */
ActiveScaffold.ActionLink = new Object();
ActiveScaffold.ActionLink.Abstract = Class.create({
  initialize: function(a, target, loading_indicator) {
    this.tag = $(a);
    this.url = this.tag.href;
    this.method = 'get';
    if(this.url.match('_method=delete')){
      this.method = 'delete';
    } else if(this.url.match('_method=post')){
      this.method = 'post';
    } else if(this.url.match('_method=put')){
      this.method = 'put';
    }
    this.target = target;
    this.loading_indicator = loading_indicator;
    this.hide_target = false;
    this.position = this.tag.getAttribute('data-position');
		var ajax_link = this.tag.getAttribute('data-remote');
    
		if (ajax_link == 'true') {
      this.onclick = this.tag.onclick;
      this.tag.onclick = null;
      this.tag.observe('click', function(event) {
        this.open(event);
      }.bind(this));
    }

    this.tag.action_link = this;
  },

  open: function(event) {
    if (this.is_disabled()) {
      if (event) Event.stop(event);
      return;
    }
    
/*
    if (this.tag.hasAttribute( "data-confirm")) {
      if (this.onclick) this.onclick();
      return;
    } else {
      if (this.onclick && !this.onclick()) return;//e.g. confirmation messages
      this.open_action();
    }
*/
  },
  
  insert: function(content) {
    throw 'unimplemented'
  },

  close: function() {
    this.enable();
    this.adapter.remove();
    if (this.hide_target) this.target.show();
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
});

/**
 * Concrete classes for record actions
 */
ActiveScaffold.Actions.Record = Class.create(ActiveScaffold.Actions.Abstract, {
  instantiate_link: function(link) {
    var l = new ActiveScaffold.ActionLink.Record(link, this.target, this.loading_indicator);
    l.refresh_url = this.options.refresh_url;
    if (link.hasClassName('delete')) {
      l.url = l.url.replace(/\/delete(\?.*)?$/, '$1');
      l.url = l.url.replace(/\/delete\/(.*)/, '/destroy/$1');
    }
    if (l.position) {
      l.url = l.url.append_params({adapter: '_list_inline_adapter'});
      l.tag.href = l.url;
    }
    l.set = this;
    return l;
  }
});

ActiveScaffold.ActionLink.Record = Class.create(ActiveScaffold.ActionLink.Abstract, {
  close_previous_adapter: function() {
    this.set.links.each(function(item) {
      if (item.url != this.url && item.is_disabled() && item.adapter) {
        item.enable();
        item.adapter.remove();
      }
    }.bind(this));
  },

  insert: function(content) {
    this.close_previous_adapter();

    if (this.position == 'replace') {
      this.position = 'after';
      this.hide_target = true;
    }

    if (this.position == 'after') {
      this.target.insert({after:content});
      this.adapter = this.target.next();
      this.adapter.addClassName('as_adapter');
      this.adapter.action_link = this;
    }
    else if (this.position == 'before') {
      this.target.insert({before:content});
      this.adapter = this.target.previous();
      this.adapter.addClassName('as_adapter');
      this.adapter.action_link = this;
    }
    else {
      return false;
    }
    this.adapter.down('td').down().highlight();
  },

  close: function($super, updatedRow) {
    if (updatedRow) {
      ActiveScaffold.update_row(this.target, updatedRow);
      $super();
    } else {
      new Ajax.Request(this.refresh_url, {
        asynchronous: true,
        evalScripts: true,
        method: this.method,
        onSuccess: function(request) {
          ActiveScaffold.update_row(this.target, request.responseText);
          $super();
        }.bind(this),
  
        onFailure: function(request) {
          ActiveScaffold.report_500_response(this.scaffold_id());
        }
      });
    }
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
ActiveScaffold.Actions.Table = Class.create(ActiveScaffold.Actions.Abstract, {
  instantiate_link: function(link) {
    var l = new ActiveScaffold.ActionLink.Table(link, this.target, this.loading_indicator);
    if (l.position) {
      l.url = l.url.append_params({adapter: '_list_inline_adapter'});
      l.tag.href = l.url;
    }
    return l;
  }
});

ActiveScaffold.ActionLink.Table = Class.create(ActiveScaffold.ActionLink.Abstract, {
  insert: function(content) {
    if (this.position == 'top') {
      this.target.insert({top:content});
      this.adapter = this.target.immediateDescendants().first();
      this.adapter.addClassName('as_adapter');
      this.adapter.action_link = this;
    }
    else {
      throw 'Unknown position "' + this.position + '"'
    }
    this.adapter.down('td').down().highlight();
  }
});

if (Ajax.InPlaceEditor) {
ActiveScaffold.InPlaceEditor = Class.create(Ajax.InPlaceEditor, {
  setFieldFromAjax: function(url, options) {
    var ipe = this;
    $(ipe._controls.editor).remove();
    new Ajax.Request(url, {
      method: 'get',
      onComplete: function(response) {
        ipe._form.insert({top: response.responseText});
        if (options.plural) {
          ipe._form.getElements().each(function(el) {
            if (el.type != "submit" && el.type != "image") {
              el.name = ipe.options.paramName + '[]';
              el.className = 'editor_field';
            }
          });
        } else {
          var fld = ipe._form.findFirstElement();
          fld.name = ipe.options.paramName;
          fld.className = 'editor_field';
          if (ipe.options.submitOnBlur)
            fld.onblur = ipe._boundSubmitHandler;
          ipe._controls.editor = fld;
        }
      }
    });
  },

  clonePatternField: function() {
    var patternNodes = this.getPatternNodes(this.options.inplacePatternSelector);
    if (patternNodes.editNode == null) {
      alert('did not find any matching node for ' + this.options.editFieldSelector);
      return;
    }

    var fld = patternNodes.editNode.cloneNode(true);
    if (fld.id.length > 0) fld.id += this.options.nodeIdSuffix;
    fld.name = this.options.paramName;
    fld.className = 'editor_field';
    this.setValue(fld, this._controls.editor.value);
    if (this.options.submitOnBlur)
      fld.onblur = this._boundSubmitHandler;
    $(this._controls.editor).remove();
    this._controls.editor = fld;
    this._form.appendChild(this._controls.editor);

    $A(patternNodes.additionalNodes).each(function(node) {
      var patternNode = node.cloneNode(true);
      if (patternNode.id.length > 0) {
        patternNode.id = patternNode.id + this.options.nodeIdSuffix;
      }
      this._form.appendChild(patternNode);
    }.bind(this));
  },
  
  getPatternNodes: function(inplacePatternSelector) {
    var nodes = {editNode: null, additionalNodes: []};
    var selectedNodes = $$(inplacePatternSelector);
    var firstNode = selectedNodes.first();
    
    if (typeof(firstNode) !== 'undefined') {
      // AS inplace_edit_control_container -> we have to select all child nodes
      // Workaround for ie which does not support css > selector
      if (firstNode.className.indexOf('as_inplace_pattern') !== -1) {
        selectedNodes = firstNode.childElements();
      }
      nodes.editNode = selectedNodes.first();
      selectedNodes.shift();
      nodes.additionalNodes = selectedNodes;
    }
    return nodes;
  },
  
  setValue: function(editField, textValue) {
    var function_name = 'setValueFor' + editField.nodeName.toLowerCase();
    if (typeof(this[function_name]) == 'function') {
      this[function_name](editField, textValue);
    } else {
      editField.value = textValue;
    }
  },
  
  setValueForselect: function(editField, textValue) {
    var len = editField.options.length;
    var i = 0;
    while (i < len && editField.options[i].text != textValue) {
      i++;
    }
    if (i < len) {
      editField.value = editField.options[i].value
    }
  }
});
}
