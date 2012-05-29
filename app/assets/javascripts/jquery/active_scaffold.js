jQuery(document).ready(function() {
  jQuery('form.as_form').live('ajax:beforeSend', function(event) {
    var as_form = jQuery(this).closest("form");
    if (as_form.attr('data-loading') == 'true') {
      ActiveScaffold.disable_form(as_form);
    }
    return true;
  });
  
  jQuery('form.as_form').live('ajax:complete', function(event) {
    var as_form = jQuery(this).closest("form");
    if (as_form.attr('data-loading') == 'true') {
      ActiveScaffold.enable_form(as_form);
    }
  });
  jQuery('form.as_form').live('ajax:error', function(event, xhr, status, error) {
    var as_div = jQuery(this).closest("div.active-scaffold");
    if (as_div.length) {
      ActiveScaffold.report_500_response(as_div);
    }
  });
  jQuery('form.as_form.as_remote_upload').live('submit', function(event) {
    var as_form = jQuery(this).closest("form");
    if (as_form.attr('data-loading') == 'true') {
      setTimeout("ActiveScaffold.disable_form('" + as_form.attr('id') + "')", 10);
    }
    return true;
  });
  jQuery('a.as_action').live('ajax:before', function(event) {
    var action_link = ActiveScaffold.ActionLink.get(jQuery(this));
    if (action_link) {
      if (action_link.is_disabled()) {
        return false;
      } else {
        if (action_link.loading_indicator) action_link.loading_indicator.css('visibility','visible');
        action_link.disable();
      }
    }
    return true;
  });
  jQuery('a.as_action').live('ajax:success', function(event, response) {
    var action_link = ActiveScaffold.ActionLink.get(jQuery(this));
    if (action_link) {
      if (action_link.position) {
        action_link.insert(response);
        if (action_link.hide_target) action_link.target.hide();
      } else {
        action_link.enable();
      }
      jQuery(this).trigger('as:action_success', action_link);
    }
    return true;
  });
  jQuery('a.as_action').live('ajax:complete', function(event) {
    var action_link = ActiveScaffold.ActionLink.get(jQuery(this));
    if (action_link) {
      if (action_link.loading_indicator) action_link.loading_indicator.css('visibility','hidden');  
    }
    return true;
  });
  jQuery('a.as_action').live('ajax:error', function(event, xhr, status, error) {
    var action_link = ActiveScaffold.ActionLink.get(jQuery(this));
    if (action_link) {
      ActiveScaffold.report_500_response(action_link.scaffold_id());
      action_link.enable();
    }
    return true;
  });
  jQuery('a.as_cancel').live('ajax:before', function(event) {
    var as_cancel = jQuery(this);
    var action_link = ActiveScaffold.find_action_link(as_cancel);  
    
    if (action_link) {
      var cancel_url = as_cancel.attr('href');
      var refresh_data = as_cancel.attr('data-refresh');
      if (refresh_data !== 'true' || !cancel_url) {
        action_link.close();
        return false;
      }
    }
    return true;
  });
  jQuery('a.as_cancel').live('ajax:success', function(event, response) {
    var action_link = ActiveScaffold.find_action_link(jQuery(this));

    if (action_link) {
      if (action_link.position) {
        action_link.close();
      } else {
        response.evalResponse(); 
      }
    }
    return true;
  });
  jQuery('a.as_cancel').live('ajax:error', function(event, xhr, status, error) {
    var action_link = ActiveScaffold.find_action_link(jQuery(this));
    if (action_link) {
      ActiveScaffold.report_500_response(action_link.scaffold_id());
    }
    return true;
  });
  jQuery('a.as_sort').live('ajax:before', function(event) {
    var as_sort = jQuery(this);
    var history_controller_id = as_sort.attr('data-page-history');
    if (history_controller_id) addActiveScaffoldPageToHistory(as_sort.attr('href'), history_controller_id);
    as_sort.closest('th').addClass('loading');
    return true;
  });
  jQuery('a.as_sort').live('ajax:error', function(event, xhr, status, error) {
    var as_scaffold = jQuery(this).closest('.active-scaffold');
    ActiveScaffold.report_500_response(as_scaffold);
    return true;
  });
  jQuery('td.in_place_editor_field').live('hover', function(event) {
    var td = jQuery(this), span = td.find('span.in_place_editor_field');
    span.data(); // $ 1.4.2 workaround
    if (event.type == 'mouseenter') {
      if (td.hasClass('empty') || typeof(span.data('editInPlace')) === 'undefined') td.find('span').addClass("hover");
     }
    if (event.type == 'mouseleave') {
      if (td.hasClass('empty') || typeof(span.data('editInPlace')) === 'undefined') td.find('span').removeClass("hover");
    }
    return true;
  });
  jQuery('td.in_place_editor_field').live('click', function(event) {
    var span = jQuery(this).find('span.in_place_editor_field');
    span.data('addEmptyOnCancel', jQuery(this).hasClass('empty'));
    jQuery(this).removeClass('empty');
    if (span.data('editInPlace')) span.trigger('click.editInPlace');
    else ActiveScaffold.in_place_editor_field_clicked(span);
  });
  jQuery('a.as_paginate').live('ajax:before',function(event) {
    var as_paginate = jQuery(this);
    var history_controller_id = as_paginate.attr('data-page-history');
    if (history_controller_id) addActiveScaffoldPageToHistory(as_paginate.attr('href'), history_controller_id);
    as_paginate.prevAll('img.loading-indicator').css('visibility','visible');
    return true;
  });
  jQuery('a.as_paginate').live('ajax:error', function(event, xhr, status, error) {
    var as_scaffold = jQuery(this).closest('.active-scaffold');
    ActiveScaffold.report_500_response(as_scaffold);
    return true;
  });
  jQuery('a.as_paginate').live('ajax:complete', function(event) {
    jQuery(this).prevAll('img.loading-indicator').css('visibility','hidden');
    return true;
  });
  jQuery('a.as_add_existing, a.as_replace_existing').live('ajax:before', function(event) {
    var id = jQuery(this).prev().val();
    if (id) {
      if (!jQuery(this).data('href')) jQuery(this).data('href', jQuery(this).attr('href'));
      jQuery(this).attr('href', jQuery(this).data('href').replace('--ID--', id));
      return true;
    } else return false;
  });
  jQuery('input.update_form:not(.recordselect), textarea.update_form, select.update_form').live('change', function(event) {
    var element = jQuery(this);
    var value = element.is("input:checkbox:not(:checked)") ? null : element.val();
    ActiveScaffold.update_column(element, element.attr('data-update_url'), element.attr('data-update_send_form'), element.attr('id'), value);
    return true;
  });
  jQuery('input.recordselect.update_form').live('recordselect:change', function(event, id, label) {
    var element = jQuery(this);
    ActiveScaffold.update_column(element, element.attr('data-update_url'), element.attr('data-update_send_form'), element.attr('id'), id);
    return true;
  });
  
  jQuery('select.as_search_range_option').live('change', function(event) {
    ActiveScaffold[jQuery(this).val() == 'BETWEEN' ? 'show' : 'hide'](jQuery(this).parent().find('.as_search_range_between'));
    return true;
  });
  
  jQuery('select.as_search_range_option').live('change', function(event) {
    var element = jQuery(this);
    ActiveScaffold[!(element.val() == 'PAST' || element.val() == 'FUTURE' || element.val() == 'RANGE') ? 'show' : 'hide'](element.attr('id').replace(/_opt/, '_numeric'));
    ActiveScaffold[(element.val() == 'PAST' || element.val() == 'FUTURE') ? 'show' : 'hide'](element.attr('id').replace(/_opt/, '_trend'));
    ActiveScaffold[(element.val() == 'RANGE') ? 'show' : 'hide'](element.attr('id').replace(/_opt/, '_range'));
    return true;
  });

  jQuery('select.as_update_date_operator').live('change', function(event) {
    ActiveScaffold[jQuery(this).val() == 'REPLACE' ? 'show' : 'hide'](jQuery(this).next());
    ActiveScaffold[jQuery(this).val() == 'REPLACE' ? 'hide' : 'show'](jQuery(this).next().next());
    return true;
  });

  jQuery('a[data-popup]').live('click', function(e) {
    window.open(jQuery(this).attr('href'));
    e.preventDefault();
  });

  jQuery('.hover_click').live("click", function(event) {
    var element = jQuery(this);
    var ul_element = element.children('ul').first();
    if (ul_element.is(':visible')) {
      element.find('ul').hide();
    } else {
      ul_element.show();
    }
    return false;
  });
  jQuery('.hover_click a.as_action').live('click', function(event) {
    var element = jQuery(this).closest('.hover_click');
    if (element) {
      element.find('ul').hide();
    }
    return true;
  });

  jQuery('.message a.close').live('click', function(e) {
    ActiveScaffold.hide(jQuery(this).closest('.message'));
    e.preventDefault();
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
 $ delayed observer
 (c) 2007 - Maxime Haineault (max@centdessin.com)
 
 Special thanks to Stephen Goguen & Tane Piper.
 
 Slight modifications by Elliot Winkler
*/

if (typeof(jQuery.fn.delayedObserver) === 'undefined') { 
  (function() {
    var delayedObserverStack = [];
    var observed;
   
    function delayedObserverCallback(stackPos) {
      observed = delayedObserverStack[stackPos];
      if (observed.timer) return;
     
      observed.timer = setTimeout(function(){
        observed.timer = null;
        observed.callback(observed.obj.val(), observed.obj);
      }, observed.delay * 1000);
  
      observed.oldVal = observed.obj.val();
    } 
    
    // going by
    // <http://www.cambiaresearch.com/c4/702b8cd1-e5b0-42e6-83ac-25f0306e3e25/Javascript-Char-Codes-Key-Codes.aspx>
    // I think these codes only work when using keyup or keydown
    function isNonPrintableKey(event) {
      var code = event.keyCode;
      return (
        event.metaKey ||
        (code >= 9 && code <= 16) || (code >= 27 && code <= 40) || (code >= 91 && code <= 93) || (code >= 112 && code <= 145)
      );
    }
   
    jQuery.fn.extend({
      delayedObserver:function(delay, callback){
        $this = jQuery(this);
       
        delayedObserverStack.push({
          obj: $this, timer: null, delay: delay,
          oldVal: $this.val(), callback: callback
        });
         
        stackPos = delayedObserverStack.length-1;
       
        $this.keyup(function(event) {
          if (isNonPrintableKey(event)) return;
          observed = delayedObserverStack[stackPos];
            if (observed.obj.val() == observed.obj.oldVal) return;
            else delayedObserverCallback(stackPos);
        });
      }
    });
  })();
};


/*
 * Simple utility methods
 */

var ActiveScaffold = {
  records_for: function(tbody_id) {
    if (typeof(tbody_id) == 'string') tbody_id = '#' + tbody_id;
    return jQuery(tbody_id).children('.record');
  },
  stripe: function(tbody_id) {
    var even = false;
    var rows = this.records_for(tbody_id);
    
    rows.each(function (index, row_node) {
      row = jQuery(row_node);
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
      jQuery(tbody).parent().find('tbody.messages p.empty-message').hide();
    }
  },
  reload_if_empty: function(tbody, url) {
    if (this.records_for(tbody).length == 0) {
      this.reload(url);
    }
  },
  reload: function(url) {
    jQuery.getScript(url);
  },
  removeSortClasses: function(scaffold) {
    if (typeof(scaffold) == 'string') scaffold = '#' + scaffold;
    scaffold = jQuery(scaffold)
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
    scaffold = jQuery(scaffold);
    count = scaffold.find('span.active-scaffold-records').last();
    if (count) count.html(parseInt(count.html(), 10) - 1);
  },
  increment_record_count: function(scaffold) {
    // increment the last record count, firsts record count are in nested lists
    if (typeof(scaffold) == 'string') scaffold = '#' + scaffold;
    scaffold = jQuery(scaffold);
    count = scaffold.find('span.active-scaffold-records').last();
    if (count) count.html(parseInt(count.html(), 10) + 1);
  },
  update_row: function(row, html) {
    var even_row = false;
    var replaced = null;
    if (typeof(row) == 'string') row = '#' + row; 
    row = jQuery(row);
    if (row.hasClass('even-record')) even_row = true;

    replaced = this.replace(row, html);
    if (even_row === true) replaced.addClass('even-record');
    ActiveScaffold.highlight(replaced);
  },
  
  replace: function(element, html) {
    if (typeof(element) == 'string') element = '#' + element; 
    element = jQuery(element);
    element.replaceWith(html);
    if (element.attr('id')) {
      element = jQuery('#' + element.attr('id'));
    }
    element.trigger('as:element_updated');
    return element;
  },
  
  replace_html: function(element, html) {
    if (typeof(element) == 'string') element = '#' + element; 
    element = jQuery(element);
    element.html(html);
    element.trigger('as:element_updated');
    return element;
  },
  
  remove: function(element) {
    if (typeof(element) == 'string') element = '#' + element; 
    jQuery(element).remove();
  },

  update_inplace_edit: function(element, value, empty) {
    if (typeof(element) == 'string') element = '#' + element;
    this.replace_html(jQuery(element), value);
    if (empty) jQuery(element).closest('td').addClass('empty');
  },
  
  hide: function(element) {
    if (typeof(element) == 'string') element = '#' + element;
    jQuery(element).hide();
  },
  
  show: function(element) {
    if (typeof(element) == 'string') element = '#' + element;
    jQuery(element).show();
  },
  
  reset_form: function(element) {
    if (typeof(element) == 'string') element = '#' + element;
    jQuery(element).get(0).reset();
  },
  
  disable_form: function(as_form) {
    if (typeof(as_form) == 'string') as_form = '#' + as_form;
    as_form = jQuery(as_form)
    var loading_indicator = jQuery('#' + as_form.attr('id').replace(/-form$/, '-loading-indicator'));
    if (loading_indicator) loading_indicator.css('visibility','visible');
    jQuery('input[type=submit]', as_form).attr('disabled', 'disabled');
    as_form[0].disabled_fields = jQuery("input:enabled,select:enabled,textarea:enabled", as_form).attr('disabled', 'disabled');
  },
  
  enable_form: function(as_form) {
    if (typeof(as_form) == 'string') as_form = '#' + as_form;
    as_form = jQuery(as_form)
    var loading_indicator = jQuery('#' + as_form.attr('id').replace(/-form$/, '-loading-indicator'));
    if (loading_indicator) loading_indicator.css('visibility','hidden');
    jQuery('input[type=submit]', as_form).removeAttr('disabled');
    as_form[0].disabled_fields.removeAttr('disabled');
  },  
  
  focus_first_element_of_form: function(form_element) {
    if (typeof(form_element) == 'string') form_element = '#' + form_element;
    jQuery(form_element + ":first *:input[type!=hidden]:first").focus();
  },
    
  create_record_row: function(active_scaffold_id, html, options) {
    if (typeof(active_scaffold_id) == 'string') active_scaffold_id = '#' + active_scaffold_id;
    tbody = jQuery(active_scaffold_id).find('tbody.records').first();
    
    if (options.insert_at == 'top') {
      tbody.prepend(html);
      var new_row = tbody.children('tr.record:first-child');
    } else if (options.insert_at == 'bottom') {
      var rows = tbody.children('tr.record, tr.inline-adapter');
      var new_row = null;
      if (rows.length > 0) {
        new_row = rows.last().after(html).next();
      } else {
        new_row = tbody.append(html).children().last();
      }
    }
    this.stripe(tbody);
    this.hide_empty_message(tbody);
    this.increment_record_count(tbody.closest('div.active-scaffold'));
    ActiveScaffold.highlight(new_row);
  },
  
  delete_record_row: function(row, page_reload_url) {
    if (typeof(row) == 'string') row = '#' + row;
    row = jQuery(row);
    var tbody = row.closest('tbody.records');
    
    var current_action_node = row.find('td.actions a.disabled').first();
    if (current_action_node) {
      var action_link = ActiveScaffold.ActionLink.get(current_action_node);
      if (action_link) {
        action_link.close_previous_adapter();
      }
    }
    
    row.remove();
    this.stripe(tbody);
    this.decrement_record_count(tbody.closest('div.active-scaffold'));
    this.reload_if_empty(tbody, page_reload_url);
  },

  delete_subform_record: function(record) {
    if (typeof(record) == 'string') record = '#' + record;
    record = jQuery(record);
    var errors = record.prev();
    if (errors.hasClass('association-record-errors')) {
      this.remove(errors);
    }
    var associated = jQuery(record).next();
    this.remove(record);
    while (associated.hasClass('associated-record')) {
      record = associated;
      associated = jQuery(record).next();
      this.remove(record);
    }
  },

  report_500_response: function(active_scaffold_id) {
    var server_error = jQuery(active_scaffold_id).find('td.messages-container p.server-error').first();
    if (server_error.is(':visible')) {
      ActiveScaffold.highlight(server_error);
    } else {
      server_error.show();
    }
  },
  
  find_action_link: function(element) {
    if (typeof(element) == 'string') element = '#' + element;
    element = jQuery(element);
    return ActiveScaffold.ActionLink.get(element.is('.actions a') ? element : element.closest('.as_adapter'));
  },
  
  scroll_to: function(element, checkInViewport) {
    if (typeof checkInViewport == 'undefined') checkInViewport = true;
    if (typeof(element) == 'string') element = '#' + element;
    var form_offset = jQuery(element).offset().top;
    if (checkInViewport) {
        var docViewTop = jQuery(window).scrollTop(),
            docViewBottom = docViewTop + jQuery(window).height();
        // If it's in viewport , don't scroll;
        if (form_offset + jQuery(element).height() <= docViewBottom && form_offset >= docViewTop) return;
    }
    
    jQuery(document).scrollTop(form_offset);
  },
  
  process_checkbox_inplace_edit: function(checkbox, options) {
    var checked = checkbox.is(':checked');
    if (checked === true) options['params'] += '&value=1';
    jQuery.ajax({
      url: options.url,
      type: "POST",
      data: options['params'],
      dataType: options.ajax_data_type,
      after: function(request){
        checkbox.attr('disabled', 'disabled');
      },
      complete: function(request){
        checkbox.removeAttr('disabled');
      }
    });
  },
  
  read_inplace_edit_heading_attributes: function(column_heading, options) {
    if (column_heading.attr('data-ie_cancel_text')) options.cancel_button = '<button class="inplace_cancel">' + column_heading.attr('data-ie_cancel_text') + "</button>";
    if (column_heading.attr('data-ie_loading_text')) options.loading_text = column_heading.attr('data-ie_loading_text');
    if (column_heading.attr('data-ie_saving_text')) options.saving_text = column_heading.attr('data-ie_saving_text');
    if (column_heading.attr('data-ie_save_text')) options.save_button = '<button class="inplace_save">' + column_heading.attr('data-ie_save_text') + "</button>";
    if (column_heading.attr('data-ie_rows')) options.textarea_rows = column_heading.attr('data-ie_rows');
    if (column_heading.attr('data-ie_cols')) options.textarea_cols = column_heading.attr('data-ie_cols');
    if (column_heading.attr('data-ie_size')) options.text_size = column_heading.attr('data-ie_size');
  }, 
  
  create_inplace_editor: function(span, options) {
    span.removeClass('hover');
    span.editInPlace(options);
    span.trigger('click.editInPlace');
  },
  
  highlight: function(element) {
    if (typeof(element) == 'string') element = jQuery('#' + element);
    if (typeof(element.effect) == 'function') {
      element.effect("highlight", jQuery.extend({}, ActiveScaffold.js_config.highlight), 3000);
    }
  },
  
  create_visibility_toggle: function(element, options) {
    if (typeof(element) == 'string') element = '#' + element;
    var toggable = jQuery(element);
    var toggler = toggable.prev();
    var initial_label = (options.default_visible === true) ? options.hide_label : options.show_label;
    
    toggler.append(' (<a class="visibility-toggle" href="#">' + initial_label + '</a>)');
    toggler.children('a').click(function() {
      toggable.toggle(); 
      jQuery(this).html((toggable.is(':hidden')) ? options.show_label : options.hide_label);
      return false;
    });
  },
  
  create_associated_record_form: function(element, content, options) {
    if (typeof(element) == 'string') element = '#' + element;
    var element = jQuery(element);
    if (options.singular == false) {
      if (!(options.id && jQuery('#' + options.id).size() > 0)) {
        element.append(content);
      }
    } else {
      var current = jQuery('#' + element.attr('id') + ' .association-record')
      if (current[0]) {
        this.replace(current[0], content);
      } else {
        element.prepend(content);
      }
    }
  },
  
  render_form_field: function(source, content, options) {
    if (typeof(source) == 'string') source = '#' + source;
    var source = jQuery(source);
    var element = source.closest('.association-record');
    if (element.length == 0) {
      element = source.closest('form > ol.form');
    }
    element = element.find('.' + options.field_class).first();

    if (element) {
      if (options.is_subform == false) {
        this.replace(element.closest('dl'), content);
      } else {
        this.replace_html(element, content);
      }
    }
  },
  
  sortable: function(element, controller, options, url_params) {
    if (typeof(element) == 'string') element = '#' + element;
    var element = jQuery(element);
    var sortable_options = jQuery.extend({}, options);
    if (options.update === true) {
      url_params.authenticity_token = jQuery('meta[name=csrf-param]').attr('content');
      sortable_options.update = function(event, ui) {
         var url = controller + '/' + options.action + '?'
         url += jQuery(this).sortable('serialize',{key: encodeURIComponent(jQuery(this).attr('id') + '[]'), expression:/^[^_-](?:[A-Za-z0-9_-]*)-(.*)-row$/});
         jQuery.post(url.append_params(url_params));
       }
    }
    element.sortable(sortable_options);
  },

  record_select_onselect: function(edit_associated_url, active_scaffold_id, id){
    jQuery.ajax({
      url: edit_associated_url.split('--ID--').join(id),
      error: function(xhr, textStatus, errorThrown){
        ActiveScaffold.report_500_response(active_scaffold_id)
      }
    });
  },

  // element is tbody id
  mark_records: function(element, options) {
    if (typeof(element) == 'string') element = '#' + element;
    var element = jQuery(element);
    var mark_checkboxes = jQuery('#' + element.attr('id') + ' > tr.record td.marked-column input[type="checkbox"]');
    mark_checkboxes.each(function (index) {
      var item = jQuery(this);
     if(options.checked === true) {
       item.attr('checked', 'checked');
     } else {
       item.removeAttr('checked');
     }
     item.attr('value', ('' + !options.checked));
    });
    if(options.include_mark_all === true) {
      var mark_all_checkbox = element.prev('thead').find('th.marked-column_heading span input[type="checkbox"]');
      if(options.checked === true) {
        mark_all_checkbox.attr('checked', 'checked');
      } else {
        mark_all_checkbox.removeAttr('checked');
      }
      mark_all_checkbox.attr('value', ('' + !options.checked));
    }
  },

  in_place_editor_field_clicked: function(span) {
    span.data(); // $ 1.4.2 workaround
    // test editor is open
    if (typeof(span.data('editInPlace')) === 'undefined') {
      var options = {show_buttons: true,
                     hover_class: 'hover',
                     element_id: 'editor_id',
                     ajax_data_type: "script",
                     delegate: {
                       willCloseEditInPlace: function(span, options, enteredText) {
                         if (span.data('addEmptyOnCancel')) span.closest('td').addClass('empty');
                       }
                     },
                     update_value: 'value'},
          csrf_param = jQuery('meta[name=csrf-param]').first(),
          csrf_token = jQuery('meta[name=csrf-token]').first(),
          my_parent = span.parent(),
          column_heading = null;

      if(!(my_parent.is('td') || my_parent.is('th'))){
        my_parent = span.parents('td').eq(0);
      }

      if (my_parent.is('td')) {
        var column_no = my_parent.prevAll('td').length;
        column_heading = my_parent.closest('.active-scaffold').find('th:eq(' + column_no + ')');
      } else if (my_parent.is('th')) {
        column_heading = my_parent;
      }

      var render_url = column_heading.attr('data-ie_render_url'),
          mode = column_heading.attr('data-ie_mode'),
          record_id = span.attr('data-ie_id');

      ActiveScaffold.read_inplace_edit_heading_attributes(column_heading, options);

      if (span.attr('data-ie_url')) {
        options.url = span.attr('data-ie_url').replace(/__id__/, record_id);
      } else {
        options.url = column_heading.attr('data-ie_url').replace(/__id__/, record_id);
      }

      if (csrf_param) options['params'] = csrf_param.attr('content') + '=' + csrf_token.attr('content');

      if (span.closest('div.active-scaffold').attr('data-eid')) {
        if (options['params'].length > 0) {
          options['params'] += "&";
        }
        options['params'] += ("eid=" + span.closest('div.active-scaffold').attr('data-eid'));
      }

      if (mode === 'clone') {
        options.clone_id_suffix = record_id;
        options.clone_selector = '#' + column_heading.attr('id') + ' .as_inplace_pattern';
        options.field_type = 'clone';
      }

      if (render_url) {
        var plural = false;
        if (column_heading.attr('data-ie_plural')) plural = true;
        options.field_type = 'remote';
        options.editor_url = render_url.replace(/__id__/, record_id)
      }
      if (mode === 'inline_checkbox') {
        ActiveScaffold.process_checkbox_inplace_edit(span.find('input:checkbox'), options);
      } else {
        ActiveScaffold.create_inplace_editor(span, options);
      }
    }
  },
  
  update_column: function(element, url, send_form, source_id, val) {
    if (!element) element = jQuery('#' + source_id);
    var as_form = element.closest('form.as_form');
    var params = null;

    if (send_form) {
      var selector;
      if (selector = element.data('update_send_form_selector'))
        params = as_form.find(selector).serialize();
      else params = as_form.serialize();
      params += '&' + jQuery.param({"source_id": source_id});
    } else {
      params = {value: val};
      params.source_id = source_id;
    }

    jQuery.ajax({
      url: url,
      data: params,
      beforeSend: function(event) {
        element.nextAll('img.loading-indicator').css('visibility','visible');
        ActiveScaffold.disable_form(as_form);
      },
      complete: function(event) {
        element.nextAll('img.loading-indicator').css('visibility','hidden');
        ActiveScaffold.enable_form(as_form);
      },
      error: function (xhr, status, error) {
        var as_div = element.closest("div.active-scaffold");
        if (as_div) {
          ActiveScaffold.report_500_response(as_div);
        }
      }
    });
  },
  
  draggable_lists: function(element) {
    jQuery('#' + element).draggable_lists();
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
    this.target = jQuery(target);
    this.loading_indicator = jQuery(loading_indicator);
    this.options = options;
    var _this = this; 
    this.links = jQuery.map(links, function(link) {
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
ActiveScaffold.ActionLink = {
  get: function(element) {
    if (typeof(element) == 'string') element = '#' + element;
    var element = jQuery(element);
    if (element.length > 0) {
      element.data(); // $ 1.4.2 workaround
      if (typeof(element.data('action_link')) === 'undefined' && !element.hasClass('as_adapter')) {
        var parent = element.closest('.actions');
        if (parent.length === 0) {
          // maybe an column action_link
          parent = element.parent();
        }
        if (parent && parent.is('td')) {
          // record action
          parent = parent.closest('tr.record');
          var target = parent.find('a.as_action');
          var loading_indicator = parent.find('td.actions .loading-indicator');
          new ActiveScaffold.Actions.Record(target, parent, loading_indicator);
        } else if (parent && parent.is('div')) {
          //table action
          new ActiveScaffold.Actions.Table(parent.find('a.as_action'), parent.closest('div.active-scaffold').find('tbody.before-header').first(), parent.find('.loading-indicator').first());
        }
        element = jQuery(element);
      }
      return element.data('action_link');
    } else {
      return null;
    }
  }
};
ActiveScaffold.ActionLink.Abstract = Class.extend({
  init: function(a, target, loading_indicator) {
    this.tag = jQuery(a);
    this.url = this.tag.attr('href');
    this.method = this.tag.attr('data-method') || 'get';
    this.target = target;
    this.loading_indicator = loading_indicator;
    this.hide_target = false;
    this.position = this.tag.attr('data-position');
    this.action = this.tag.attr('data-action');

    this.tag.data('action_link', this);
    return this;
  },

  open: function(event) {
    this.tag.click();
  },
  
  insert: function(content) {
    throw 'unimplemented'
  },

  close: function() {
    this.enable();
    this.adapter.remove();
    if (this.hide_target) this.target.show();
    if (ActiveScaffold.config.scroll_on_close) ActiveScaffold.scroll_to(this.target.attr('id'), ActiveScaffold.config.scroll_on_close == 'checkInViewport');
  },

  get_new_adapter_id: function() {
    var id = 'adapter_';
    var i = 0;
    while (jQuery(id + i)) i++;
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

  scaffold: function() {
    return this.tag.closest('div.active-scaffold');
  },
  
  update_flash_messages: function(messages) {
    message_node = jQuery(this.scaffold_id().replace(/-active-scaffold/, '-messages'));
    if (message_node) message_node.html(messages);
  },
  set_adapter: function(element) {
    this.adapter = element;
    this.adapter.addClass('as_adapter');
    this.adapter.data('action_link', this);
    if (this.refresh_url) jQuery('.as_cancel[data-refresh=true]', this.adapter).attr('href', this.refresh_url);
  }
});

/**
 * Concrete classes for record actions
 */
ActiveScaffold.Actions.Record = ActiveScaffold.Actions.Abstract.extend({
  instantiate_link: function(link) {
    var l = new ActiveScaffold.ActionLink.Record(link, this.target, this.loading_indicator);
    var refresh = this.target.attr('data-refresh');
    if (refresh) l.refresh_url = refresh;
    
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
    jQuery.each(this.set.links, function(index, item) {
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
    ActiveScaffold.highlight(this.adapter.find('td'));
  },

  close: function(refreshed_content) {
    this._super();
    if (refreshed_content) {
      ActiveScaffold.update_row(this.target, refreshed_content);
    }
  },

  enable: function() {
    var _this = this;
    jQuery.each(this.set.links, function(index, item) {
      if (item.url != _this.url) return;
      item.tag.removeClass('disabled');
    });
  },

  disable: function() {
    var _this = this;
    jQuery.each(this.set.links, function(index, item) {
      if (item.url != _this.url) return;
      item.tag.addClass('disabled');
    });
  },
  
  set_opened: function() {
    if (this.position == 'after') {
      this.set_adapter(this.target.next());
    }
    else if (this.position == 'before') {
      this.set_adapter(this.target.prev());
    }
    this.disable();
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
    ActiveScaffold.highlight(this.adapter.find('td').first().children());
  },

  reload: function() {
    this.close();
    this.open();
  },
});
