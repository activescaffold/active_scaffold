$(document).ready(function() {
  $('form.as_form').live('ajax:loading', function(event) {
    var as_form = $(this).closest("form");
    if (as_form && as_form.attr('data-loading') == 'true') {
      var loading_indicator = $('#' + as_form.attr('id').replace(/-form$/, '-loading-indicator'));
      if (loading_indicator) loading_indicator.css('visibility','visible');
      $('input[type=submit]', as_form).attr('disabled', 'disabled');
      $("input:disabled", as_form).attr('disabled', 'disabled');
    }
    return true;
  });
  $('form.as_form').live('ajax:complete', function(event) {
    var as_form = $(this).closest("form");
    if (as_form && as_form.attr('data-loading') == 'true') {
      var loading_indicator = $('#' + as_form.attr('id').replace(/-form$/, '-loading-indicator'));
      if (loading_indicator) loading_indicator.css('visibility','hidden');
      $('input[type=submit]', as_form).attr('disabled', '');
      $("input:disabled", as_form).attr('disabled', '');
      //event.stop();
      //return false;
    }
  });
  $('form.as_form').live('ajax:failure', function(event) {
    var as_div = $(this).closest("div.active-scaffold");
    if (as_div) {
      ActiveScaffold.report_500_response(as_div)
      event.stop();
      return false;
    }
  });
  $('a.as_action').live('ajax:before', function(event) {
    var as_action = $(this);
    if (typeof(as_action.get(0).action_link) === 'undefined') {
      var parent = as_action.parent();
      if (parent && parent.get(0).nodeName.toUpperCase() == 'TD') {
        // record action
        parent = parent.closest('tr.record');
        var target = parent.find('a.as_action');
        var loading_indicator = parent.find('td.actions .loading-indicator');
        new ActiveScaffold.Actions.Record(target, parent, loading_indicator);
      } else if (parent && parent.get(0).nodeName.toUpperCase() == 'DIV') {
        //table action
        new ActiveScaffold.Actions.Table(parent.find('a.as_action'), parent.closest('div.active-scaffold').find('tbody.before-header'), parent.find('.loading-indicator'));
      }
      as_action = $(this);
    }
    if (as_action.get(0).action_link) {
      var action_link = as_action.get(0).action_link;
      if (action_link.is_disabled()) {
        return false;
      } else {
        if (action_link.loading_indicator) action_link.loading_indicator.css('visibility','visible');
        action_link.disable();
      }
    }
    return true;
  });
  $('a.as_action').live('ajax:success', function(event, response) {
    var as_action = $(this);
    if (as_action.get(0).action_link) {
      var action_link = as_action.get(0).action_link;
      if (action_link.position) {
        action_link.insert(response);
        if (action_link.hide_target) action_link.target.hide();
      } else {
        action_link.enable();
      }
      //event.stop();
      return true;
    }
    return true;
  });
  $('a.as_action').live('ajax:complete', function(event) {
    var as_action = $(this);
    if (as_action.get(0).action_link) {
      var action_link = as_action.get(0).action_link;
      if (action_link.loading_indicator) action_link.loading_indicator.css('visibility','hidden');  
    }
    return true;
  });
  $('a.as_action').live('ajax:failure', function(event) {
    var as_action = $this;
    if (as_action.get(0).action_link) {
      var action_link = as_action.get(0).action_link;
      ActiveScaffold.report_500_response(action_link.scaffold_id());
      action_link.attr('disabled', '');
    }
    return true;
  });
  $('a.as_cancel').live('ajax:before', function(event) {
    var as_adapter = $(this).closest('.as_adapter');
    var as_cancel = $(this);
    
    if (as_adapter.get(0).action_link) {
      var action_link = as_adapter.get(0).action_link;
      var cancel_url = as_cancel.attr('href');
      var refresh_data = as_cancel.attr('data-refresh');
      if (refresh_data === 'true' && action_link.refresh_url) {
        event.data_url = action_link.refresh_url;
        if (action_link.position) event.data_type = 'html' 
      } else if (refresh_data === 'false' || typeof(cancel_url) == 'undefined' || cancel_url.length == 0) {
        action_link.close();
        return false;
      }
    }
    return true;
  });
  $('a.as_cancel').live('ajax:success', function(event, response) {
    var as_adapter = $(this).closest('.as_adapter');

    if (as_adapter.get(0).action_link) {
      var action_link = as_adapter.get(0).action_link;
      if (action_link.position) {
        action_link.close(response);
      } else {
        response.evalResponse(); 
      }
    }
    return true;
  });
  $('a.as_cancel').live('ajax:failure', function(event) {
    var as_adapter = $(this).closest('.as_adapter');
    if (as_adapter.get(0).action_link) {
      var action_link = as_adapter.get(0).action_link;
      ActiveScaffold.report_500_response(action_link.scaffold_id());
    }
    return true;
  });
  $('a.as_sort').live('ajax:before', function(event) {
    var as_sort = $(this);
    var history_controller_id = as_sort.attr('data-page-history');
    if (history_controller_id) addActiveScaffoldPageToHistory(as_sort.attr('href'), history_controller_id);
    as_sort.closest('th').addClass('loading');
    return true;
  });
  $('a.as_sort').live('ajax:failure', function(event) {
    var as_scaffold = $(this).closest('.active-scaffold');
    ActiveScaffold.report_500_response(as_scaffold);
    return true;
  });
});

/* Simple Inheritance
 http://ejohn.org/blog/simple-javascript-inheritance/
*/
(function(){
  var initializing = false, fnTest = /xyz/.test(function(){xyz;}) ? /\b_super\b/ : /.*/;

  // The base Class implementation (does nothing)
  this.Class = function(){};
 
  // Create a new Class that inherits from this class
  Class.extend = function(prop) {
    var _super = this.prototype;
   
    // Instantiate a base class (but only create the instance,
    // don't run the init constructor)
    initializing = true;
    var prototype = new this();
    initializing = false;
   
    // Copy the properties over onto the new prototype
    for (var name in prop) {
      // Check if we're overwriting an existing function
      prototype[name] = typeof prop[name] == "function" &&
        typeof _super[name] == "function" && fnTest.test(prop[name]) ?
        (function(name, fn){
          return function() {
            var tmp = this._super;
           
            // Add a new ._super() method that is the same method
            // but on the super-class
            this._super = _super[name];
           
            // The method only need to be bound temporarily, so we
            // remove it when we're done executing
            var ret = fn.apply(this, arguments);       
            this._super = tmp;
           
            return ret;
          };
        })(name, prop[name]) :
        prop[name];
    }
   
    // The dummy class constructor
    function Class() {
      // All construction is actually done in the init method
      if ( !initializing && this.init )
        this.init.apply(this, arguments);
    }
   
    // Populate our constructed prototype object
    Class.prototype = prototype;
   
    // Enforce the constructor to be what we expect
    Class.constructor = Class;

    // And make this class extendable
    Class.extend = arguments.callee;
   
    return Class;
  };
})();


/*
 * Simple utility methods
 */

var ActiveScaffold = {
  records_for: function(tbody_id) {
    if (typeof(tbody_id) == 'string') tbody_id = '#' + tbody_id;
    return $(tbody_id).children('.record');
  },
  stripe: function(tbody_id) {
    var even = false;
    var rows = this.records_for(tbody_id);
    
    rows.each(function (index, row_node) {
      row = $(row_node);
      if (row_node.tagName != 'SCRIPT'
        && !row.hasClass("create")
        && !row.hasClass("update")
        && !row.hasClass("inline-adapter")
        && !row.hasClass("active-scaffold-calculations")) {

        if (even) row.addClass("even-record");
        else row.removeClass("even-record");

        even = !even;
      }  
    });
  },
  hide_empty_message: function(tbody) {
    if (this.records_for(tbody).length != 0) {
      var empty_message_node = $(tbody).parent().find('tbody.messages p.empty-message')
      if (empty_message_node) empty_message_node.hide();
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
  removeSortClasses: function(scaffold) {
    if (typeof(scaffold) == 'string') scaffold = '#' + scaffold;
    scaffold = $(scaffold)
    scaffold.find('td.sorted').each(function(element) {
      element.removeClass("sorted");
    });
    scaffold.find('th.sorted').each(function(element) {
      element.removeClass("sorted");
      element.removeClass("asc");
      element.removeClass("desc");
    });
  },
  decrement_record_count: function(scaffold) {
    // decrement the last record count, firsts record count are in nested lists
    if (typeof(scaffold) == 'string') scaffold = '#' + scaffold; 
    scaffold = $(scaffold)
    count = scaffold.find('span.active-scaffold-records').last();
    if (count) count.html(parseInt(count.innerHTML, 10) - 1);
  },
  increment_record_count: function(scaffold) {
    // increment the last record count, firsts record count are in nested lists
    if (typeof(scaffold) == 'string') scaffold = '#' + scaffold;
    scaffold = $(scaffold)
    count = scaffold.find('span.active-scaffold-records').last();
    if (count) count.html(parseInt(count.innerHTML, 10) + 1);
  },
  update_row: function(row, html) {
    var even_row = false;
    var replaced = null;
    if (typeof(row) == 'string') row = '#' + row; 
    row = $(row);
    if (row.hasClass('even-record')) even_row = true;

    replaced = this.replace(row, html);
    if (even_row === true) replaced.addClass('even-record');
    //new_row.highlight();
  },
  
  replace: function(element, html) {
    if (typeof(element) == 'string') element = '#' + element; 
    element = $(element);
    element.replaceWith(html);
    element = $('#' + element.attr('id'));
    return element;
  },
  
  replace_html: function(element, html) {
    if (typeof(element) == 'string') element = '#' + element; 
    element = $(element);
    element.html(html);
    return element;
  },
  
  create_record_row: function(tbody, html) {
    if (typeof(tbody) == 'string') tbody = '#' + tbody;
    tbody = $(tbody);
    tbody.prepend(html);

    var new_row = tbody.children('tr:first-child');
    this.stripe(tbody);
    this.hide_empty_message(tbody);
    this.increment_record_count(tbody.closest('div.active-scaffold'));
    //new_row.highlight();
  },
  
  delete_record_row: function(row, page_reload_url) {
    if (typeof(row) == 'string') row = '#' + row;
    row = $(row);
    var tbody = row.closest('tbody.records');
    
    var current_action_node = row.find('td.actions a.disabled').first();
    if (current_action_node && current_action_node.get(0).action_link) {
      current_action_node.get(0).action_link.close_previous_adapter();
    }
    row.remove();
    this.stripe(tbody);
    this.decrement_record_count(tbody.closest('div.active-scaffold'));
    this.reload_if_empty(tbody, page_reload_url);
  },

  report_500_response: function(active_scaffold_id) {
    server_error = $(active_scaffold_id).find('td.messages-container p.server-error');
    if (!$(server_error).is(':visible')) {
      server_error.show();
    }
  },
  
  find_action_link: function(element) {
    if (typeof(element) == 'string') element = '#' + element;
    var as_adapter = $(element).closest('.as_adapter');
    return as_adapter.get(0).action_link;
  },
  
  scroll_to: function(element) {
    if (typeof(element) == 'string') element = '#' + element;
    var form_offset = $(element).offset(),
        destination = form_offset.top;
    $(document).scrollTop(destination);    
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
 * URL modification support. Incomplete functionality.
 */
String.prototype.append_params = function(params) {
  var url = this;
  if (url.indexOf('?') == -1) url += '?';
  else if (url.lastIndexOf('&') != url.length) url += '&';

  for(var key in params) {
    if (key) url += (key + '=' + params[key] + '&');
  }
  
  // the loop leaves a comma dangling at the end of string, chop it off 
  url = url.substring(0, url.length-1);
  return url;
};


/**
 * A set of links. As a set, they can be controlled such that only one is "open" at a time, etc.
 */
ActiveScaffold.Actions = new Object();
ActiveScaffold.Actions.Abstract = Class.extend({
  init: function(links, target, loading_indicator, options) {
    this.target = $(target);
    this.loading_indicator = $(loading_indicator);
    this.options = options;
    var _this = this; 
    this.links = $.map(links, function(link) {
      var my_link = _this.instantiate_link(link);
      return my_link;
    });
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
ActiveScaffold.ActionLink.Abstract = Class.extend({
  init: function(a, target, loading_indicator) {
    this.tag = $(a);
    this.url = this.tag.attr('href');
    this.method = 'get';
    
    if(this.url.match('_method=delete')){
      this.method = 'delete';
      // action delete is special case cause in ajax world it will be destroy
    } else if(this.url.match('/delete')){
      this.url = this.url.replace('/delete', '');
      this.tag.attr('href', this.url);
      this.method = 'delete';
    } else if(this.url.match('_method=post')){
      this.method = 'post';
    } else if(this.url.match('_method=put')){
      this.method = 'put';
    }
    if (this.method != 'get') this.tag.attr('data-method', this.method);
    this.target = target;
    this.loading_indicator = loading_indicator;
    this.hide_target = false;
    this.position = this.tag.attr('data-position');
		
    this.tag.get(0).action_link = this;
    return this;
  },

  open: function(event) {
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
    return this.tag.removeClass('disabled');
  },

  disable: function() {
    return this.tag.addClass('disabled');
  },

  is_disabled: function() {
    return this.tag.hasClass('disabled');
  },

  scaffold_id: function() {
    return '#' + this.tag.closest('div.active-scaffold').attr('id');
  },
  
  update_flash_messages: function(messages) {
    message_node = $(this.scaffold_id().replace(/-active-scaffold/, '-messages'));
    if (message_node) message_node.html(messages);
  },
  set_adapter: function(element) {
    this.adapter = element;
    this.adapter.addClass('as_adapter');
    this.adapter.get(0).action_link = this;
  },
});

/**
 * Concrete classes for record actions
 */
ActiveScaffold.Actions.Record = ActiveScaffold.Actions.Abstract.extend({
  instantiate_link: function(link) {
    var l = new ActiveScaffold.ActionLink.Record(link, this.target, this.loading_indicator);
    var refresh = this.target.attr('data-refresh');
    if (refresh) l.refresh_url = refresh;
    
    if ($(link).hasClass('delete')) {
      l.url = l.url.replace(/\/delete(\?.*)?$/, '$1');
      l.url = l.url.replace(/\/delete\/(.*)/, '/destroy/$1');
      l.tag.attr('href', l.url);
    }
    if (l.position) {
      l.url = l.url.append_params({adapter: '_list_inline_adapter'});
      l.tag.attr('href', l.url);
    }
    l.set = this;
    return l;
  }
});

ActiveScaffold.ActionLink.Record = ActiveScaffold.ActionLink.Abstract.extend({
  close_previous_adapter: function() {
    var _this = this;
    $.each(this.set.links, function(index, item) {
      if (item.url != _this.url && item.is_disabled() && item.adapter) {
        item.enable();
        item.adapter.remove();
      }
    });
  },

  insert: function(content) {
    this.close_previous_adapter();

    if (this.position == 'replace') {
      this.position = 'after';
      this.hide_target = true;
    }

    if (this.position == 'after') {
      this.target.after(content);
      this.set_adapter(this.target.next());
    }
    else if (this.position == 'before') {
      this.target.before(content);
      this.set_adapter(this.target.prev());
    }
    else {
      return false;
    }
  },

  close: function(refreshed_content) {
    if (refreshed_content) {
      ActiveScaffold.update_row(this.target, refreshed_content);
    }
    this._super();
  },

  enable: function() {
    var _this = this;
    $.each(this.set.links, function(index, item) {
      if (item.url != _this.url) return;
      item.tag.removeClass('disabled');
    });
  },

  disable: function() {
    var _this = this;
    $.each(this.set.links, function(index, item) {
      if (item.url != _this.url) return;
      item.tag.addClass('disabled');
    });
  }
});

/**
 * Concrete classes for table actions
 */
ActiveScaffold.Actions.Table = ActiveScaffold.Actions.Abstract.extend({
  instantiate_link: function(link) {
    var l = new ActiveScaffold.ActionLink.Table(link, this.target, this.loading_indicator);
    if (l.position) {
      l.url = l.url.append_params({adapter: '_list_inline_adapter'});
      l.tag.attr('href', l.url);
    }
    return l;
  }
});

ActiveScaffold.ActionLink.Table = ActiveScaffold.ActionLink.Abstract.extend({
  insert: function(content) {
    if (this.position == 'top') {
      this.target.prepend(content);
      this.set_adapter(this.target.children().first());
    }
    else {
      throw 'Unknown position "' + this.position + '"'
    }
    //this.adapter.find('td').first().children().highlight();
  }
});

if (typeof(Ajax) !== 'undefined' && Ajax.InPlaceEditor) {
ActiveScaffold.InPlaceEditor = Ajax.InPlaceEditor.extend({
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
