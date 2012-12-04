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
  document.on('click', function(event) {
    $$('.action_group.dyn ul').invoke('remove');
  });
  document.on('ajax:complete', '.action_group.dyn ul a', function() {
    var source = event.findElement();
    var action_link = ActiveScaffold.find_action_link(source);
    if (action_link.loading_indicator) action_link.loading_indicator.css('visibility','hidden');  
    $(source).up('.action_group.dyn ul').remove();
  });
  document.on('ajax:create', 'form.as_form', function(event) {
    var source = event.findElement();
    var as_form = event.findElement('form');
    if (source.nodeName.toUpperCase() == 'INPUT' && source.readAttribute('type') == 'button') {
      // Hack: Prototype or rails.js somehow screw up event handling if someone clicks
      // a button of type button such as Create Another <Association>
      // as a result form is disabled but never reenabled..
    } else {
      if (as_form && as_form.readAttribute('data-loading') == 'true') {
        ActiveScaffold.disable_form(as_form);
      }
    }
    return true;
  });
  document.on('ajax:complete', 'form.as_form', function(event) {
    var as_form = event.findElement('form');
    if (as_form && as_form.readAttribute('data-loading') == 'true') {
      ActiveScaffold.enable_form(as_form);
      event.stop();
      return false;
    }
  });
  document.on('ajax:failure', 'form.as_form', function(event) {
    var as_div = event.findElement('div.active-scaffold');
    if (as_div) {
      ActiveScaffold.report_500_response(as_div)
      event.stop();
      return false;
    }
  });
  document.on('submit', 'form.as_form:not([data-remote])', function(event) {
    var as_form = event.findElement('form');
    if (as_form && as_form.readAttribute('data-loading') == 'true') {
      setTimeout("ActiveScaffold.disable_form('" + as_form.readAttribute('id') + "')", 10);
    }
    return true;
  });
  document.on('ajax:before', 'a.as_action', function(event) {
    var action_link = ActiveScaffold.ActionLink.get(event.findElement());
    if (action_link) {
      if (action_link.is_disabled()) {
        event.stop();
      } else {
        if (action_link.loading_indicator) action_link.loading_indicator.style.visibility = 'visible';
        action_link.disable();
      }
    }
    return true;
  });
  document.on('ajax:success', 'a.as_action', function(event) {
    var action_link = ActiveScaffold.ActionLink.get(event.findElement());
    if (action_link && event.memo && event.memo.request) {
      if (action_link.position) {
        action_link.insert(event.memo.request.transport.responseText);
        if (action_link.hide_target) action_link.target.hide();
      } else {
        //event.memo.request.evalResponse(); // (clyfe) prototype evals the response by itself checking headers, this would eval twice
        action_link.enable();
      }
      event.stop();
    }
    return true;
  });
  document.on('ajax:complete', 'a.as_action', function(event) {
    var action_link = ActiveScaffold.ActionLink.get(event.findElement());
    if (action_link && action_link.loading_indicator) {
      action_link.loading_indicator.style.visibility = 'hidden';  
    }
    return true;
  });
  document.on('ajax:failure', 'a.as_action', function(event) {
    var action_link = ActiveScaffold.ActionLink.get(event.findElement());
    if (action_link) {
      ActiveScaffold.report_500_response(action_link.scaffold_id());
      action_link.enable();
    }
    return true;
  });
  document.on('ajax:before', 'a.as_cancel', function(event) {
    var as_cancel = event.findElement();
    var action_link = ActiveScaffold.find_action_link(as_cancel);
    
    if (action_link) {
      var refresh_data = action_link.tag.readAttribute('data-cancel-refresh') || as_cancel.readAttribute('data-refresh');
      if (refresh_data && action_link.refresh_url) {
        event.memo.url = action_link.refresh_url;
      } else if (!refresh_data || as_cancel.readAttribute('href').blank()) {
        action_link.close();
        event.stop();
      }
    }
    return true;
  });
  document.on('ajax:success', 'a.as_cancel', function(event) {
    var action_link = ActiveScaffold.find_action_link(event.findElement());
    if (action_link) {
      if (action_link.position) {
        action_link.close();
      } else {
        event.memo.request.evalResponse(); 
      }
    }
    return true;
  });
  document.on('ajax:failure', 'a.as_cancel', function(event) {
    var action_link = ActiveScaffold.find_action_link(event.findElement());
    if (action_link) {
      ActiveScaffold.report_500_response(action_link.scaffold_id());
    }
    return true;
  });
  document.on('ajax:before', 'a.as_sort', function(event) {
    var as_sort = event.findElement();
    var history_controller_id = as_sort.readAttribute('data-page-history');
    if (history_controller_id) addActiveScaffoldPageToHistory(as_sort.readAttribute('href'), history_controller_id);
    as_sort.up('th').addClassName('loading');
    return true;
  });
  document.on('ajax:failure', 'a.as_sort', function(event) {
    var as_scaffold = event.findElement('.active-scaffold');
    ActiveScaffold.report_500_response(as_scaffold);
    return true;
  });
  document.on('mouseover', 'td.in_place_editor_field', function(event) {
      event.findElement('td.in_place_editor_field').select('span').invoke('addClassName', 'hover');
  });
  document.on('mouseout', 'td.in_place_editor_field', function(event) {
      event.findElement('td.in_place_editor_field').select('span').invoke('removeClassName', 'hover');
  });
  document.on('click', 'td.in_place_editor_field', function(event) {
    var td = event.findElement('td.in_place_editor_field'),
        span = td.down('span.in_place_editor_field');
    td.removeClassName('empty');
    
    if (typeof(span.inplace_edit) === 'undefined') {
      var options = {htmlResponse: false,
                     onEnterHover: null,
                     onLeaveHover: null,
                     onComplete: null,
                     params: '',
                     externalControl: td.down('.handle'),
                     ajaxOptions: {method: 'post'}},
          csrf_param = $$('meta[name=csrf-param]')[0],
          csrf_token = $$('meta[name=csrf-token]')[0],
          my_parent = span.up(),
          column_heading = null;

      if(!(my_parent.nodeName.toLowerCase() === 'td' || my_parent.nodeName.toLowerCase() === 'th')){
          my_parent = span.up('td');
      }
          
      if (my_parent.nodeName.toLowerCase() === 'td') {
        var heading_selector = '.' + span.up().readAttribute('class').split(' ')[0] + '_heading';
        column_heading = span.up('.active-scaffold').down(heading_selector);
      } else if (my_parent.nodeName.toLowerCase() === 'th') {
        column_heading = my_parent;
      }
          
      var render_url = column_heading.readAttribute('data-ie-render-url'),
          mode = column_heading.readAttribute('data-ie-mode'),
          record_id = span.readAttribute('data-ie-id') || '';
        
      ActiveScaffold.read_inplace_edit_heading_attributes(column_heading, options);
      
      if (span.readAttribute('data-ie-url')) {
        options.url = span.readAttribute('data-ie-url');
      } else {
        options.url = column_heading.readAttribute('data-ie-url');
      }
      options.url = options.url.sub('__id__', record_id);
       
      if (csrf_param) options['params'] = csrf_param.readAttribute('content') + '=' + csrf_token.readAttribute('content');

      if (span.up('div.active-scaffold').readAttribute('data-eid')) {
        if (options['params'].length > 0) {
          options['params'] += "&";
        }
        options['params'] += ("eid=" + span.up('div.active-scaffold').readAttribute('data-eid'));
      }
            
      if (mode === 'clone') {
        options.nodeIdSuffix = record_id;
        options.inplacePatternSelector = '#' + column_heading.readAttribute('id') + ' .as_inplace_pattern';
        options['onFormCustomization'] = new Function('element', 'form', 'element.clonePatternField();');
      }
      
      if (render_url) {
        var plural = false;
        if (column_heading.readAttribute('data-ie-plural')) plural = true;
        options['onFormCustomization'] = new Function('element', 'form', 'element.setFieldFromAjax(' + "'" + render_url.sub('__id__', record_id) + "', {plural: " + plural + '});');
      }
      
      if (mode === 'inline_checkbox') {
        ActiveScaffold.process_checkbox_inplace_edit(span.down('input[type="checkbox"]'), options);
      } else {
        ActiveScaffold.create_inplace_editor(span, options);
      }
    }
    return true;
  });
  document.on('ajax:before', 'a.as_paginate', function(event) {
    var as_paginate = event.findElement();
    var loading_indicator = as_paginate.up().down('img.loading-indicator');
    var history_controller_id = as_paginate.readAttribute('data-page-history');
    
    if (history_controller_id) addActiveScaffoldPageToHistory(as_paginate.readAttribute('href'), history_controller_id);
    if (loading_indicator) loading_indicator.style.visibility = 'visible';
    return true;
  });
  document.on('ajax:failure', 'a.as_paginate', function(event) {
    var as_scaffold = event.findElement('.active-scaffold');
    ActiveScaffold.report_500_response(as_scaffold);
    return true;
  });
  document.on('ajax:complete', 'a.as_paginate', function(event) {
    var as_paginate = event.findElement();
    var loading_indicator = as_paginate.up().down('img.loading-indicator');
    
    if(loading_indicator) loading_indicator.style.visibility = 'hidden';  
    return true;
  });
  document.on('ajax:before', 'a.as_add_existing, a.as_replace_existing', function(event) {
    var button = event.findElement();
    var url =  button.readAttribute('href').sub('--ID--', button.previous().getValue());
    event.memo.url = url;
    return true;
  });
  document.on('change', 'input.update_form, textarea.update_form, select.update_form', function(event) {
    var element = event.findElement();
    ActiveScaffold.update_column(element, element.readAttribute('data-update_url'), element.hasAttribute('data-update_send_form'), element.readAttribute('id'), element.getValue());
    return true;
  });
  document.on('recordselect:change', 'input.recordselect.update_form', function(event) {
    var element = event.findElement();
    ActiveScaffold.update_column(element, element.readAttribute('data-update_url'), element.hasAttribute('data-update_send_form'), element.readAttribute('id'), element.memo.id);
    return true;
  });
  document.on('change', 'select.as_search_range_option', function(event) {
    var element = event.findElement();
    Element[element.value == 'BETWEEN' ? 'show' : 'hide'](element.readAttribute('id').sub('_opt', '_between'));
    Element[(element.value == 'null' || element.value == 'not_null') ? 'hide' : 'show'](element.readAttribute('id').sub('_opt', '_numeric'));
    return true;
  });
  document.on('change', 'select.as_search_date_time_option', function(event) {
    var element = event.findElement();
    Element[!(element.value == 'PAST' || element.value == 'FUTURE' || element.value == 'RANGE') ? 'show' : 'hide'](element.readAttribute('id').sub('_opt', '_numeric'));
    Element[(element.value == 'PAST' || element.value == 'FUTURE') ? 'show' : 'hide'](element.readAttribute('id').sub('_opt', '_trend'));
    Element[element.value == 'RANGE' ? 'show' : 'hide'](element.readAttribute('id').sub('_opt', '_range'));
    return true;
  });
  document.on('change', 'select.as_update_date_operator', function(event) {
    var element = event.findElement();
    Element[element.value == 'REPLACE' ? 'show' : 'hide'](element.next());
    Element[element.value == 'REPLACE' ? 'show' : 'hide'](element.next().next());
    Element[element.value == 'REPLACE' ? 'hide' : 'show'](element.next('span'));
    return true;
  });
  document.on("click", "a[data-popup]", function(event, element) {
    if (event.stopped) return;
    window.open($(element).href);
    event.stop();
  });
  document.on("click", ".hover_click", function(event, element) {
    var ul_element = element.down('ul');
    if (ul_element.getStyle('display') === 'none') {
      ul_element.style.display = 'block';
    } else {
      ul_element.style.display = 'none';
    }
     
    return true;
  });
  document.on("click", ".hover_click a.as_action", function(event, element) {
    var element = element.up('.hover_click').down('ul');
    if (element) {
      element.style.display = 'none';
    }
    return true;
  });
  document.on('click', '.messages a.close', function(event, element) {
    ActiveScaffold.hide(element.up('.message'));
    event.stop();
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
  hide_empty_message: function(tbody) {
    if (this.records_for(tbody).length != 0) {
      var empty_message_nodes = $(tbody).up().select('tbody.messages p.empty-message')
      empty_message_nodes.invoke('hide');
    }
  },
  reload_if_empty: function(tbody, url) {
    if (this.records_for(tbody).length == 0) {
      this.reload(url);
    }
  },
  reload: function(url) {
    new Ajax.Request(url, {
      method: 'get',
      asynchronous: true,
      evalScripts: true
    });
  },
  removeSortClasses: function(scaffold) {
    scaffold = $(scaffold)
    scaffold.select('td.sorted').each(function(element) {
      element.removeClassName("sorted");
    });
    scaffold.select('th.sorted').each(function(element) {
      element.removeClassName("sorted");
      element.removeClassName("asc");
      element.removeClassName("desc");
    });
  },
  decrement_record_count: function(scaffold) {
    // decrement the last record count, firsts record count are in nested lists
    scaffold = $(scaffold)
    count = scaffold.select('span.active-scaffold-records').last();
    if (count) count.update(parseInt(count.innerHTML, 10) - 1);
  },
  increment_record_count: function(scaffold) {
    // increment the last record count, firsts record count are in nested lists
    scaffold = $(scaffold)
    count = scaffold.select('span.active-scaffold-records').last();
    if (count) count.update(parseInt(count.innerHTML, 10) + 1);
  },
  update_row: function(row, html) {
    row = $(row);
    var new_row = this.replace(row, html)
    if (row.hasClassName('even-record')) new_row.addClassName('even-record');
    ActiveScaffold.highlight(new_row);
  },
  
  replace: function(element, html) {
    element = $(element)
    Element.replace(element, html);
    element = $(element.readAttribute('id'));
    return element;
  },
    
  replace_html: function(element, html) {
    element = $(element);
    element.update(html);
    return element;
  },
  
  remove: function(element, callback) {
    $(element).remove();
    if (callback) callback();
  },
  
  update_inplace_edit: function(element, value, empty) {
    this.replace_html(element, value);
    if (empty) $(element).up('td').addClassName('empty');
  },
  
  hide: function(element) {
    $(element).hide();
  },
  
  show: function(element) {
    $(element).show();
  },
  
  reset_form: function(element) {
    $(element).reset();
  },
  
  disable_form: function(as_form) {
    as_form = $(as_form)
    var loading_indicator = $(as_form.readAttribute('id').sub('-form', '-loading-indicator'));
    if (loading_indicator) loading_indicator.style.visibility = 'visible';
    as_form.disable();
  },
  
  enable_form: function(as_form) {
    as_form = $(as_form)
    var loading_indicator = $(as_form.readAttribute('id').sub('-form', '-loading-indicator'));
    if (loading_indicator) loading_indicator.style.visibility = 'hidden';
    as_form.enable();
  },
  
  focus_first_element_of_form: function(form_element) {
    Form.focusFirstElement(form_element);
  },  
  
  create_record_row: function(active_scaffold_id, html, options) {
    tbody = $(active_scaffold_id).down('tbody.records');

    var new_row = null;
    
    if (options.insert_at == 'top') {
      tbody.insert({top: html});
      new_row = tbody.firstDescendant();
    } else if (options.insert_at == 'bottom') {
      var last_row = tbody.childElements().reverse().detect(function(node) { return node.hasClassName('record') || node.hasClassName('inline-adapter')});
      if (last_row) {
        last_row.insert({after: html});
      } else {
        tbody.insert({bottom: html});
      }
      new_row = Selector.findChildElements(tbody, ['tr.record']).last();
    } else if (typeof options.insert_at == 'object') {
      var insert_method, get_method, row, id;
      if (options.insert_at.after) {
        insert_method = 'after';
        get_method = 'next';
      } else {
        insert_method = 'before';
        get_method = 'previous';
      }
      if (id = options.insert_at[insert_method]) row = $(id);
      if (row) {
        row.insert({insert_method: html});
        new_row = row[get_method]();
      }
    }
    
    this.stripe(tbody);
    this.hide_empty_message(tbody);
    this.increment_record_count(tbody.up('div.active-scaffold'));
    ActiveScaffold.highlight(new_row);
  },
    
  create_record_row_from_url: function(action_link, url, options) {
    new Ajax.Request(url, {
      method: 'get',
      onComplete: function(response) {
        ActiveScaffold.create_record_row(action_link.scaffold(), row, options);
        action_link.close();
      }
    });
  },
  
  delete_record_row: function(row, page_reload_url) {
    row = $(row);
    var tbody = row.up('tbody.records');
    
    var current_action_node = row.down('td.actions a.disabled');
    
    if (current_action_node) {
      var action_link = ActiveScaffold.ActionLink.get(current_action_node);
      if (action_link) {
        action_link.close_previous_adapter();
      }
    }
    ActiveScaffold.remove(row, function() {
      tbody = $(tbody);
      ActiveScaffold.stripe(tbody);
      ActiveScaffold.decrement_record_count(tbody.up('div.active-scaffold'));
      ActiveScaffold.reload_if_empty(tbody, page_reload_url);
    });
  },

  delete_subform_record: function(record) {
    var errors = $(record).previous();
    if (errors.hasClassName('association-record-errors')) {
      this.remove(errors);
    }
    var associated = $(record).next();
    this.remove(record);
    while (associated && associated.hasClassName('associated-record')) {
      record = associated;
      associated = $(record).next();
      this.remove(record);
    }
  },

  report_500_response: function(active_scaffold_id) {
    var server_error = $(active_scaffold_id).down('td.messages-container p.server-error');
    if (server_error.visible()) {
      ActiveScaffold.highlight(server_error);
    } else {
      server_error.show();
    }
  },
  
  find_action_link: function(element) {
    element = $(element);
    return ActiveScaffold.ActionLink.get(element.match('.actions a') ? element : element.up('.as_adapter')); 
  },

  display_dynamic_action_group: function(link, html) {
    link = $(link);
    link.next('ul').remove();
    link.up('td').addClassName('action_group dyn');
    link.insert({after: html});
  },
  
  scroll_to: function(element, checkInViewport) {
    if (typeof checkInViewport == 'undefined') checkInViewport = true;
    var form_offset = $(element).viewportOffset().top;
    if (checkInViewport) {
        var docViewTop = document.viewport.getScrollOffsets().top,
            docViewBottom = docViewTop + document.viewport.getHeight();
        // If it's in viewport , don't scroll;
        if (form_offset + $(element).getHeight() <= docViewBottom && form_offset >= docViewTop) return;
    }
    $(element).scrollTo();
  },
  
  process_checkbox_inplace_edit: function(checkbox, options) {
    var checked = checkbox.readAttribute('checked');
    // checked attribute is nt updated
    if (checked !== 'checked') options['params'] += '&value=1';
    new Ajax.Request(options.url, {
      method: 'post',
      parameters: options['params'],
      onCreate: function(response) {
        checkbox.disable();
      },
      onComplete: function(response) {
        checkbox.enable();
      }
    });
  },
  
  read_inplace_edit_heading_attributes: function(column_heading, options) {
    if (column_heading.readAttribute('data-ie-cancel-text')) options.cancelText = column_heading.readAttribute('data-ie-cancel-text');
    if (column_heading.readAttribute('data-ie-loading-text')) options.loadingText = column_heading.readAttribute('data-ie-loading-text');
    if (column_heading.readAttribute('data-ie-saving-text')) options.savingText = column_heading.readAttribute('data-ie-saving-text');
    if (column_heading.readAttribute('data-ie-save-text')) options.okText = column_heading.readAttribute('data-ie-save-text');
    if (column_heading.readAttribute('data-ie-rows')) options.rows = column-heading.readAttribute('data-ie-rows');
    if (column_heading.readAttribute('data-ie-cols')) options.cols = column-heading.readAttribute('data-ie-cols');
    if (column_heading.readAttribute('data-ie-size')) options.size = column-heading.readAttribute('data-ie-size');
  }, 
  
  create_inplace_editor: function(span, options) {
    if (options['params'].length > 0) {
      options['callback'] = new Function('form', 'return Form.serialize(form) + ' + "'&" + options['params'] + "';");
    }
    span.removeClassName('hover');
    span.inplace_edit = new ActiveScaffold.InPlaceEditor(span.readAttribute('id'), options.url, options)
    span.inplace_edit.enterEditMode();
  },
  
  create_visibility_toggle: function(element, options) {
    var toggable = $(element);
    var toggler = toggable.previous();
    var initial_label = (options.default_visible === true) ? options.hide_label : options.show_label;
    
    toggler.insert(' (<a class="visibility-toggle" href="#">' + initial_label + '</a>)');
    toggler.firstDescendant().observe('click', function(event) {
      var element = event.element();
      toggable.toggle(); 
      element.innerHTML = (toggable.style.display == 'none') ? options.show_label : options.hide_label;
      return false;
    });
  },
  
  create_associated_record_form: function(element, content, options) {
    var element = $(element);
    if (options.singular == false) {
      if (!(options.id && $(options.id))) {
        element.insert(content);
      }
    } else {
      var current = $$('#' + element.readAttribute('id') + ' .association-record');
      if (current[0]) {
        this.replace(current[0], content);
      } else {
        element.insert({top: content});
      }
    }
  },
  
  render_form_field: function(source, content, options) {
    var source = $(source);
    var element = source.up('.association-record');
    if (typeof(element) === 'undefined') {
      element = source.up('ol.form');
    }
    element = element.down('.' + options.field_class);

    if (element) {
      if (options.is_subform == false) {
        this.replace(element.up('dl'), content);
      } else {
        this.replace_html(element, content);
      }
    }
  },

  record_select_onselect: function(edit_associated_url, active_scaffold_id, id){
    new Ajax.Request(
      edit_associated_url.sub('--ID--', id), {
        asynchronous: true,
        evalScripts: true,
        onFailure: function(){
          ActiveScaffold.report_500_response(active_scaffold_id.to_json)
        }
      }
    );
  },

  // element is tbody id
  mark_records: function(element, options) {
    var element = $(element);
    if (options.include_checkboxes) {
      var mark_checkboxes = $$('#' + element.readAttribute('id') + ' > tr.record td.marked-column input[type="checkbox"]');
      mark_checkboxes.each(function(item) {
       if(options.checked) {
         item.writeAttribute({ checked: 'checked' });
       } else {
         item.removeAttribute('checked');
       }
       item.writeAttribute('value', ('' + !options.checked));
      });
    }
    if(options.include_mark_all) {
      var mark_all_checkbox = element.previous('thead').down('th.marked-column_heading span input[type="checkbox"]');
      if(options.checked) {
        mark_all_checkbox.writeAttribute({ checked: 'checked' }); 
      } else {
        mark_all_checkbox.removeAttribute('checked');
      }
      mark_all_checkbox.writeAttribute('value', ('' + !options.checked));
    }
  },

  update_column: function(element, url, send_form, source_id, val) {
    if (!element) element = $(source_id);
    
    var as_form = element.up('form.as_form');
    var params = null;

    if (send_form) {
      var selector, base = as_form;
      if (send_form == 'row') base = element.up('.association-record, form');
      if (selector = element.readAttribute('data-update_send_form_selector'))
        params = Form.serializeElements(base.getElementsBySelector(selector), true);
      else if (base != as_form)
        params = Form.serializeElements(base.getElementsBySelector('input, textarea, select'), true);
      else params = as_form.serialize(true);
      params['_method'] = '';
    } else {
        params = {value: val};
    }
    params.source_id = source_id;

    new Ajax.Request(url, {
      method: 'post',
      parameters: params,
      onLoading: function(response) {
        element.next('img.loading-indicator').style.visibility = 'visible';
        as_form.disable();
      },
      onComplete: function(response) {
        element.next('img.loading-indicator').style.visibility = 'hidden';
        as_form.enable();
      },
      onFailure:  function(request) { 
        var as_div = event.findElement('div.active-scaffold');
        if (as_div) {
          ActiveScaffold.report_500_response(as_div)
        }
      }
    });
  },
  
  draggable_lists: function(element) {
    new DraggableLists(element);
  },

  highlight: function(element) {
    element = $(element);
    if (typeof(element.highlight) == 'function') {
      element.highlight(Object.extend({duration: 3}, ActiveScaffold.config.highlight));
    }
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
ActiveScaffold.ActionLink = {
  get: function(element) {
    var element = $(element);
    if (typeof(element.retrieve('action_link')) === 'undefined' && !element.hasClassName('as_adapter')) {
      var parent = element.up('.actions');
      if (typeof(parent) === 'undefined') {
        // maybe an column action_link
        parent = element.up();
      }
      if (parent && parent.nodeName.toUpperCase() == 'TD') {
        // record action
        parent = parent.up('tr.record')
        var loading_indicator = parent.down('td.actions .loading-indicator');
        if (!loading_indicator) loading_indicator = element.parent().find('.loading-indicator');
        new ActiveScaffold.Actions.Record(parent.select('a.as_action'), parent, loading_indicator);
      } else if (parent && parent.nodeName.toUpperCase() == 'DIV') {
        //table action
        new ActiveScaffold.Actions.Table(parent.select('a.as_action'), parent.up('div.active-scaffold').down('tbody.before-header'), parent.down('.loading-indicator'));
      }
      element = $(element);
    }
    return element.retrieve('action_link');
  }
};

ActiveScaffold.ActionLink.Abstract = Class.create({
  initialize: function(a, target, loading_indicator) {
    this.tag = $(a);
    this.url = this.tag.href;
    this.method = this.tag.readAttribute('data-method') || 'get';
    this.target = target;
    this.loading_indicator = loading_indicator;
    this.hide_target = false;
    this.position = this.tag.readAttribute('data-position');
		
    this.tag.store('action_link', this);
  },

  open: function(event) {
    this.tag.click();
  },
  
  insert: function(content) {
    throw 'unimplemented'
  },

  close: function() {
    var link = this;
    ActiveScaffold.remove(this.adapter, function() {
      link.enable();
      if (link.hide_target) link.target.show();
      if (ActiveScaffold.config.scroll_on_close) ActiveScaffold.scroll_to(link.target.id, ActiveScaffold.config.scroll_on_close == 'checkInViewport');
    });
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
    return this.tag.up('div.active-scaffold').readAttribute('id');
  },

  scaffold: function() {
    return this.tag.up('div.active-scaffold');
  },
  
  update_flash_messages: function(messages) {
    message_node = $(this.scaffold_id().sub('-active-scaffold', '-messages'));
    if (message_node) message_node.update(messages);
  },
  
  set_adapter: function(element) {
    this.adapter = element;
    this.adapter.addClassName('as_adapter');
    this.adapter.store('action_link', this);
  },
  
  keep_open: function() {
    return !this.tag.readAttribute('data-keep-open').blank();
  }
});

/**
 * Concrete classes for record actions
 */
ActiveScaffold.Actions.Record = Class.create(ActiveScaffold.Actions.Abstract, {
  instantiate_link: function(link) {
    var l = new ActiveScaffold.ActionLink.Record(link, this.target, this.loading_indicator);
    if (this.target.hasAttribute('data-refresh') && !this.target.readAttribute('data-refresh').blank()) l.refresh_url = this.target.readAttribute('data-refresh');
    
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
      if (item.url != this.url && item.is_disabled() && !item.keep_open() && item.adapter) {
        ActiveScaffold.remove(item.adapter, function () { item.enable(); });
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
      this.set_adapter(this.target.next());
    }
    else if (this.position == 'before') {
      this.target.insert({before:content});
      this.set_adapter(this.target.previous());
    }
    else {
      return false;
    }
    ActiveScaffold.highlight(this.adapter.down('td').down());
  },

  close: function($super, refreshed_content_or_reload) {
    $super();
    if (refreshed_content_or_reload) {
      if (typeof refreshed_content_or_reload == 'string') {
        ActiveScaffold.update_row(this.target, refreshed_content_or_reload);
      } else if (this.refresh_url) {
        var target = this.target;
        new Ajax.Request(this.refresh_url, {
          method: 'get',
          onComplete: function(response) {
            ActiveScaffold.update_row(target, response.responseText);
          }
        });
      }
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
  },

  set_opened: function() {
    if (this.position == 'after') {
      this.set_adapter(this.target.next());
    }
    else if (this.position == 'before') {
      this.set_adapter(this.target.previous());
    }
    this.disable();
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
      this.set_adapter(this.target.immediateDescendants().first());
    }
    else {
      throw 'Unknown position "' + this.position + '"'
    }
    ActiveScaffold.highlight(this.adapter.down('td').down());
  },
});

if (Ajax.InPlaceEditor) {
ActiveScaffold.InPlaceEditor = Class.create(Ajax.InPlaceEditor, {
  initialize: function($super, element, url, options) {
    $super(element, url, options);
    if (this._originalBackground == 'transparent') {
      this._originalBackground = null;
    }
  },
  
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
