(function() {
  var activeScaffoldInit = function($, undefined) {
    jQuery(document).ready(function($) {
      /* It should not be needed, latest chrome is caching by itself
        if (ActiveScaffold.config.conditional_get) jQuery.ajaxSettings.ifModified = true;
        jQuery(document).on('ajax:beforeSend', function(event, xhr, settings){
          xhr.cacheUrl = settings.url;
        });
        jQuery(document).on('ajax:success', function(event, data, status, xhr){
          var etag=xhr.getResponseHeader("etag");
          if (etag && xhr.status==304) {
            var key = etag + xhr.cacheUrl;
            xhr.responseText=jQuery(document).data(key);
            var conv = jQuery(document).data('type-'+key);
            if (conv) conv(xhr.responseText);
          }
        });
        jQuery(document).ajaxComplete(function(event, xhr, settings){
          var etag=xhr.getResponseHeader("etag");
          if (etag && settings.ifModified && xhr.responseText) {
            var key = etag + xhr.cacheUrl;
            jQuery(document).data(key, xhr.responseText);
            var contentType = xhr.getResponseHeader('Content-Type');
            for(var s in settings.contents) {
              if (settings.contents[s].test(contentType)) {
                var conv = settings.converters['text '+s];
                if (typeof conv == 'function') jQuery(document).data('type-'+key, conv);
                break;
              }
            }
          }
        });
      */
      if (/1\.[2-7]\..*/.test(jQuery().jquery)) {
        var error = 'ActiveScaffold requires jquery 1.8.0 or greater, please use jquery-rails 2.1.x gem or greater';
        if (typeof console != 'undefined') console.error(error);
        else alert(error);
      }

      jQuery(document).on('focus', ':input', function() { ActiveScaffold.last_focus = this; });
      jQuery(document).on('blur', ':input', function(e) { ActiveScaffold.last_focus = e.relatedTarget; });
      jQuery(document).click(function(event) {
        if (!jQuery(event.target).closest('.action_group.dyn').length) {
          jQuery('.action_group.dyn > ul').remove();
        }
      });
      jQuery(document).on('ajax:beforeSend', 'form.as_form', function(event) {
        var as_form = jQuery(this).closest("form");
        if (as_form.data('loading') == true) {
          if (!jQuery(event.target).data('skip-disable-form')) ActiveScaffold.disable_form(as_form);
        }
        return true;
      });

      jQuery(document).on('ajax:complete', 'form.as_form', function(event) {
        var as_form = jQuery(this).closest("form");
        if (as_form.data('loading') == true) {
          ActiveScaffold.enable_form(as_form);
        }
      });
      jQuery(document).on('ajax:complete', 'form.live', function(event) {
        ActiveScaffold.focus_first_element_of_form(jQuery(this).closest("form"));
      });
      jQuery(document).on('keyup keypress', 'form.search.live input', function(e) {
        if (e.keyCode == 13) e.preventDefault();
      });
      jQuery(document).on('ajax:error', 'form.as_form', function(event, xhr, status, error) {
        if (event.detail && !xhr) {
          error = event.detail[0];
          status = event.detail[1];
          xhr = event.detail[2];
        }
        var as_div = jQuery(this).closest("div.active-scaffold");
        if (as_div.length) {
          ActiveScaffold.report_500_response(as_div, xhr);
        }
      });
      jQuery(document).on('submit', 'form.as_form:not([data-remote])', function(event) {
        var as_form = jQuery(this).closest("form"), form_id = as_form.attr('id'), iframe, interval, doc, cookie;
        if (as_form.data('loading') == true) {
          setTimeout(function() { ActiveScaffold.disable_form(form_id); }, 10);
          if (as_form.attr('target')) {
            cookie = 'as_dl_' + new Date().getTime();
            as_form.append(jQuery('<input>', {type: 'hidden', name: '_dl_cookie', value: cookie}));
            iframe = jQuery('iframe[name="' + jQuery(this).attr('target') + '"]')[0];
            interval = setInterval(function() {
              doc = iframe.contentDocument || (iframe.contentWindow && iframe.contentWindow.document);
              if (doc && doc.readyState !== 'loading' && (doc.location.href !== 'about:blank' || document.cookie.split(cookie+'=').length == 2)) {
                ActiveScaffold.enable_form(form_id);
                clearInterval(interval);
                doc.location.replace('about:blank');
                document.cookie = cookie + '=; path=/; expires=' + new Date().toUTCString();
              } else if (!doc) {
                clearInterval(interval);
                document.cookie = cookie + '=; path=/; expires=' + new Date().toUTCString();
              }
            }, 1000);
          }
        }
        return true;
      });
      jQuery(document).on('ajax:before', 'a.as_action[data-prompt]', function(e, xhr, settings){
        var link = jQuery(this), value = prompt(link.data('prompt'));
        if (value) {
          link.data('params', jQuery.param({value: value}));
        } else if (jQuery(this).data('prompt-required')) {
          e.stopImmediatePropagation();
          return false;
        } else {
          link.removeData('params');
        }
        return true;
      });
      jQuery(document).on('ajax:before', 'a.as_action', function(event) {
        var action_link = ActiveScaffold.ActionLink.get(jQuery(this));
        if (action_link) {
          if (action_link.is_disabled()) {
            return false;
          } else {
            if (action_link.position == 'popup') ActiveScaffold.open_popup('<div class="loading"></div>', action_link);
            if (action_link.loading_indicator) action_link.loading_indicator.css('visibility','visible');
            action_link.disable();
          }
        }
        return true;
      });
      jQuery(document).on('ajax:success', 'a.as_action', function(event, response) {
        if (event.detail && !response) response = event.detail[0];
        var action_link = ActiveScaffold.ActionLink.get(jQuery(this));
        if (action_link) {
          if (action_link.position) {
            action_link.insert(response);
            if (action_link.hide_target) action_link.target.hide();
            if (action_link.hide_content) action_link.content.hide();
          } else {
            if (action_link.tag.hasClass('toggle')) {
              action_link.tag.closest('.action_group,.actions').find('.toggle.active').removeClass('active');
              action_link.tag.addClass('active');
            }
            action_link.enable();
          }
          jQuery(this).trigger('as:action_success', action_link);
          if (action_link.loading_indicator) action_link.loading_indicator.css('visibility','hidden');
        }
        return true;
      });
      jQuery(document).on('ajax:error', 'a.as_action', function(event, xhr, status, error) {
        if (event.detail && !xhr) {
          error = event.detail[0];
          status = event.detail[1];
          xhr = event.detail[2];
        }
        var action_link = ActiveScaffold.ActionLink.get(jQuery(this));
        if (action_link) {
          ActiveScaffold.report_500_response(action_link.scaffold_id(), xhr);
          if (action_link.position == 'popup') action_link.close();
          if (action_link.loading_indicator) action_link.loading_indicator.css('visibility','hidden');
          action_link.enable();
        }
        return true;
      });
      jQuery(document).on({
        'ajax:before': function () {
          var $this = jQuery(this), indicator_id = $this.data('loading-indicator-id'),
            $indicator = indicator_id ? jQuery('#' + indicator_id) : jQuery();
          if (!$indicator.length) $indicator = $this.parent().find('.loading-indicator');
          if (!$indicator.length) $indicator = $this.closest('.active-scaffold-header').find('.loading-indicator:first');
          $indicator.css('visibility', 'visible');
          $this.data('url', jQuery('option:selected', this).data('url'));
        }, 'ajax:complete': function () {
          var $this = jQuery(this), indicator_id = $this.data('loading-indicator-id'),
            $indicator = indicator_id ? jQuery('#' + indicator_id) : jQuery();
          if (!$indicator.length) $indicator = $this.parent().find('.loading-indicator');
          if (!$indicator.length) $indicator = $this.closest('.active-scaffold-header').find('.loading-indicator');
          $indicator.css('visibility', 'hidden');
        }
      }, ':input[data-remote="url"]:not(data-url)');
      jQuery(document).on('ajax:before', 'a.as_cancel', function(event) {
        var as_cancel = jQuery(this);
        var action_link = ActiveScaffold.find_action_link(as_cancel);

        if (action_link) {
          var cancel_url = as_cancel.attr('href');
          var refresh_data = action_link.tag.data('cancel-refresh') || as_cancel.data('refresh');
          if (!refresh_data || !cancel_url) {
            action_link.close();
            return false;
          }
        }
        return true;
      });
      jQuery(document).on('ajax:success', 'a.as_cancel', function(event) {
        var link = jQuery(this), action_link = ActiveScaffold.find_action_link(link);

        if (action_link && action_link.position) {
          action_link.close();
        } else if (link.hasClass('reset')) {
          var form = link.closest('form');
          if (form.is('.search')) form.find(':input:visible:not([type=submit])').val('');
          else form.trigger('reset');
        }
        return true;
      });
      jQuery(document).on('ajax:error', 'a.as_cancel', function(event, xhr, status, error) {
        if (event.detail && !xhr) {
          error = event.detail[0];
          status = event.detail[1];
          xhr = event.detail[2];
        }
        var action_link = ActiveScaffold.find_action_link(jQuery(this));
        if (action_link) {
          ActiveScaffold.report_500_response(action_link.scaffold_id(), xhr);
        }
        return true;
      });
      jQuery(document).on('ajax:before', 'a.as_sort', function(event) {
        var as_sort = jQuery(this);
        as_sort.closest('th').addClass('loading');
        return true;
      });
      jQuery(document).on('ajax:error', 'a.as_sort', function(event, xhr, status, error) {
        if (event.detail && !xhr) {
          error = event.detail[0];
          status = event.detail[1];
          xhr = event.detail[2];
        }
        var as_scaffold = jQuery(this).closest('.active-scaffold');
        ActiveScaffold.report_500_response(as_scaffold, xhr);
        jQuery(this).closest('th').removeClass('loading');
        return true;
      });
      jQuery(document).on('mouseenter mouseleave', 'td.in_place_editor_field', function(event) {
        var td = jQuery(this), span = td.find('span.in_place_editor_field');
        if (event.type == 'mouseenter') {
          if (td.hasClass('empty') || typeof(span.data('editInPlace')) === 'undefined') td.find('span').addClass("hover");
        }
        if (event.type == 'mouseleave') {
          if (td.hasClass('empty') || typeof(span.data('editInPlace')) === 'undefined') td.find('span').removeClass("hover");
        }
        return true;
      });
      jQuery(document).on('click', 'td.in_place_editor_field, th.as_marked-column_heading', function(event) {
        var span = jQuery(this).find('span.in_place_editor_field');
        span.data('addEmptyOnCancel', jQuery(this).hasClass('empty'));
        jQuery(this).removeClass('empty');
        if (span.data('editInPlace')) span.trigger('click.editInPlace');
        else ActiveScaffold.in_place_editor_field_clicked(span);
      });
      jQuery(document).on('click', '.file-input-controls .remove-file-btn', function(event) {
        event.preventDefault();
        var btn = jQuery(this), file_line = btn.closest('.file-input-controls');
        if (file_line.find('.remove_file').val('true').length) {
          btn.parent().hide();
          file_line.find('input').show();
          if (file_line.attr('required')) file_line.find('input').attr('required', 'required');
        } else {
          file_line.remove();
        }
        return false;
      });
      jQuery(document).on('change', '.file-input-controls input[type=file]', function(event) {
        var file_line = jQuery(this).closest('.file-input-controls');
        file_line.find('.remove_file').val('false');
      });
      jQuery(document).on('ajax:before', 'a.as_paginate',function(event) {
        var as_paginate = jQuery(this);
        as_paginate.prevAll('img.loading-indicator').css('visibility','visible');
        return true;
      });
      jQuery(document).on('ajax:error', 'a.as_paginate', function(event, xhr, status, error) {
        if (event.detail && !xhr) {
          error = event.detail[0];
          status = event.detail[1];
          xhr = event.detail[2];
        }
        var as_scaffold = jQuery(this).closest('.active-scaffold');
        ActiveScaffold.report_500_response(as_scaffold, xhr);
        return true;
      });
      jQuery(document).on('ajax:complete', 'a.as_paginate', function(event) {
        jQuery(this).prevAll('img.loading-indicator').css('visibility','hidden');
        return true;
      });
      jQuery(document).on('ajax:before', 'a.as_add_existing, a.as_replace_existing', function(event) {
        var prev = jQuery(this).prev();
        if (!prev.is(':input')) prev = prev.find(':input');
        var id = prev.val();
        if (id) {
          if (!jQuery(this).data('href')) jQuery(this).data('href', jQuery(this).attr('href'));
          jQuery(this).attr('href', jQuery(this).data('href').replace('--ID--', id));
          return true;
        } else return false;
      });
      jQuery(document).on('ajax:complete', '.action_group.dyn > ul a', function(event) {
        var action_link = ActiveScaffold.find_action_link(event.target), link = jQuery(event.target);
        if (action_link && action_link.loading_indicator) action_link.loading_indicator.css('visibility', 'hidden');
        setTimeout(function() {
          if (!link.parent().is('.action_group.dyn')) {
            link.closest('.action_group.dyn > ul').remove();
          }
        }, 100);
      });

      jQuery(document).on('change', 'input.update_form:not(.recordselect), textarea.update_form, select.update_form, .checkbox-list.update_form input:checkbox', function(event, additional_params) {
        var element = jQuery(this);
        var form_element;
        var value;
        if (element.is(".checkbox-list input:checkbox")) {
          form_element = element.closest('.checkbox-list');
          if (form_element.is('.draggable-list')) form_element = form_element.closest('.draggable-lists-container').find('.checkbox-list') // draggable lists will have 2 lists
          value = form_element.find(':checked').map(function(item) { return jQuery(this).val(); }).toArray();
          if (!additional_params) additional_params = (element.is(':checked') ? '_added=' : '_removed=') + element.val();
        } else {
          value = element.is("input:checkbox:not(:checked)") ? null : element.val();
          form_element = element;
        }
        ActiveScaffold.update_column(form_element, form_element.data('update_url'), form_element.data('update_send_form'), element.attr('id'), value, additional_params);
        return true;
      });
      jQuery(document).on('click', 'a.refresh-link', function(event) {
        event.preventDefault();
        var element = jQuery(this);
        var form_element = element.prev();
        var value;
        if (form_element.is(".field_with_errors")) form_element = form_element.children().last();
        if (form_element.is(".checkbox-list")) {
          value = form_element.find(':checked').map(function(item) { return jQuery(this).val(); }).toArray();
          form_element = form_element.parent().find("input:checkbox"); // parent is needed for draggable-list, checked list may be empty
        } else value = form_element.is("input:checkbox:not(:checked)") ? null : form_element.val();
        ActiveScaffold.update_column(form_element, element.attr('href'), element.data('update_send_form'), form_element.attr('id'), value);
      });
      jQuery(document).on('click', 'a.visibility-toggle', function(e) {
        var link = jQuery(this), toggable = jQuery('#' + link.data('toggable'));
        e.preventDefault();
        toggable.toggle();
        link.html((toggable.is(':hidden')) ? link.data('show') : link.data('hide'));
        return false;
      });
      jQuery(document).on('recordselect:change', 'input.recordselect.update_form', function(event, id, label) {
        var element = jQuery(this);
        ActiveScaffold.update_column(element, element.data('update_url'), element.data('update_send_form'), element.attr('id'), id);
        return true;
      });

      jQuery(document).on('change', 'select.as_search_range_option', function(event) {
        var element = jQuery(this);
        ActiveScaffold[element.val() == 'BETWEEN' ? 'show' : 'hide'](element.closest('dd').find('.as_search_range_between'));
        ActiveScaffold[(element.val() == 'null' || element.val() == 'not_null') ? 'hide' : 'show'](element.attr('id').replace(/_opt/, '_numeric'));
        return true;
      });

      jQuery(document).on('change', 'select.as_search_date_time_option', function(event) {
        var element = jQuery(this);
        ActiveScaffold[!(element.val() == 'PAST' || element.val() == 'FUTURE' || element.val() == 'RANGE') ? 'show' : 'hide'](element.attr('id').replace(/_opt/, '_numeric'));
        ActiveScaffold[(element.val() == 'PAST' || element.val() == 'FUTURE') ? 'show' : 'hide'](element.attr('id').replace(/_opt/, '_trend'));
        ActiveScaffold[(element.val() == 'RANGE') ? 'show' : 'hide'](element.attr('id').replace(/_opt/, '_range'));
        return true;
      });

      jQuery(document).on('click', '.active-scaffold .sub-form a.destroy', function(event) {
        event.preventDefault();
        ActiveScaffold.remove(jQuery(this).closest('.sub-form-record'));
      });

      jQuery(document).on("click", '.hover_click', function(event) {
        var element = jQuery(this);
        var ul_element = element.children('ul').first();
        if (ul_element.is(':visible')) {
          element.find('ul').hide();
        } else {
          ul_element.show();
        }
        return false;
      });
      jQuery(document).on('click', '.hover_click a.as_action', function(event) {
        var element = jQuery(this).closest('.hover_click');
        if (element.length) {
          element.find('ul').hide();
        }
        return true;
      });

      jQuery(document).on('click', '.message a.close', function(e) {
        ActiveScaffold.hide(jQuery(this).closest('.message'));
        e.preventDefault();
      });

      jQuery(document).on('click', 'form.as_form .no-color', function() {
        var color_field = jQuery(this).parent().next(':input');
        color_field.attr('type', jQuery(this).prop('checked') ? 'hidden' : 'color');
        if (jQuery(this).prop('checked')) color_field.val('');
      });

      jQuery(document).on('click', '.hide-new-subform, .show-new-subform', function(e) {
        var $this = jQuery(this), line = $this.closest('.form-element'),
          subform = line.find('#' + $this.data('subform-id')), radio = false, hide, select;
        if ($this.is('[type=radio]')) {
          radio = true;
          hide = $this.is('.hide-new-subform');
        } else {
          e.preventDefault();
          hide = subform.is(':visible');
        }
        if ($this.data('select-id')) {
          select = line.find('#' + $this.data('select-id'));
          if (select.hasClass('recordselect') || select.is('.no-options')) select = select.next(':hidden').addBack();
        }
        if (hide) {
          subform.hide().find("input:enabled,select:enabled,textarea:enabled").prop('disabled', true);
          if (select) select.show().prop('disabled', false);
          if (radio) {
            $this.closest('.form-element').find('[name="' + $this.attr('name') + '"].show-new-subform').prop('disabled', false);
          } else $this.html($this.data('select-text'));
        } else {
          if (select) select.hide().prop('disabled', true);
          subform.show().find("input:disabled,select:disabled,textarea:disabled").prop('disabled', false);
          if (radio) $this.prop('disabled', true);
          else {
            $this.data('select-text', $this.html());
            $this.html($this.data('subform-text'));
          }
        }
      });

      jQuery(document).on('input paste', 'form.search.live input[type=search]', $.debounce((ActiveScaffold.config.live_search_delay || 0.5) * 1000, function() {
        jQuery(this).parent().find('[type=submit]').click();
      }));

      jQuery(document).on('click', 'form.search [data-reset]', function(e){
        e.preventDefault();
        var form = jQuery(this).closest('form.search');
        form.find(
          'input:not([type=button]):not([type=submit]):not([type=reset]):not([type=hidden]),' +
          'textarea, select:has(option[value=""])'
        ).val('');
        form.find('select.as_search_range_option').each(function() { jQuery(this).val(jQuery(this).find('option:first').val()) });
        form.find('select.as_search_date_time_option').val('BETWEEN');
      });

      jQuery(document).on('click', '.active-scaffold .tabbed .nav-tabs a', function(e) {
        if (typeof jQuery().tab == 'function') return; // bootstrap tab plugin is loaded and will handle tabs
        e.preventDefault();
        var tab_ctrl = jQuery(this), tabbed = tab_ctrl.closest('.tabbed')
        tabbed.find('.nav-tabs .active').removeClass('active');
        tabbed.find('.tab-content .active').removeClass('in active');
        tab_ctrl.closest('li').addClass('active');
        jQuery(tab_ctrl.attr('href')).addClass('in active');
      });

      jQuery(document).on('turbolinks:before-visit turbo:before-visit', function() {
        if (history.state.active_scaffold) {
          history.replaceState({turbolinks: true, url: document.location.href}, '', document.location.href);
        }
      });

      jQuery(window).on('popstate', function(e) {
        var state = e.originalEvent.state;
        if (!state || !state.active_scaffold) return;
        jQuery.ajax({
          url: document.location.href,
          data: jQuery.extend({'_popstate': true}, state.active_scaffold),
          dataType: 'script',
          cache: true
        });
        jQuery('.active-scaffold:first th .as_sort:first').closest('th').addClass('loading');
      });

      // call setup on document.ready if Turbolinks not enabled
      if ((typeof(Turbolinks) == 'undefined' || !Turbolinks.supported) && typeof(Turbo) == 'undefined') {
        ActiveScaffold.setup_history_state();
        ActiveScaffold.setup(document);
      }
      if (ActiveScaffold.config.warn_changes) ActiveScaffold.setup_warn_changes();
      jQuery(document).on('as:element_updated as:element_created', function(e, action_link) {
        ActiveScaffold.setup(e.target);
      });
      jQuery(document).on('as:element_removed', function(e, action_link) {
        setTimeout(ActiveScaffold.update_floating_form_footer); // delay so form is already removed
      });
      jQuery(document).on('as:action_success', 'a.as_action', function(e, action_link) {
        if (action_link.adapter) ActiveScaffold.setup(action_link.adapter);
      });
      jQuery(document).on('as:element_updated', '.active-scaffold', function(e) {
        if (e.target != this) return;
        var search = jQuery(this).find('form.search');
        if (search.length) ActiveScaffold.focus_first_element_of_form(search);
      });
      jQuery(document).on('click', '.active-scaffold form .check-all', function(e) {
        e.preventDefault();
        ActiveScaffold.update_all_checkboxes(jQuery(this), true);
      });
      jQuery(document).on('click', '.active-scaffold form .uncheck-all', function(e) {
        e.preventDefault();
        ActiveScaffold.update_all_checkboxes(jQuery(this), false);
      });
      jQuery(document).on('click', '.descriptions-click .description:not(.visible)', function(e) {
        e.preventDefault();
        $(this).addClass('visible');
      });
      jQuery(document).on('click', '.descriptions-click .description.visible .close', function(e) {
        e.preventDefault();
        $(this).closest('.description').removeClass('visible');
      });
    });

    jQuery(document).on('turbolinks:load turbo:load', function($) {
      ActiveScaffold.setup(document);
    });


    /* Simple JavaScript Inheritance for ES 5.1
     * based on http://ejohn.org/blog/simple-javascript-inheritance/
     *  (inspired by base2 and Prototype)
     * MIT Licensed.
     */
    (function(global) {
      "use strict";
      var fnTest = /xyz/.test(function(){xyz;}) ? /\b_super\b/ : /.*/;

      // The base Class implementation (does nothing)
      function BaseClass(){}

      // Create a new Class that inherits from this class
      BaseClass.extend = function(props) {
        var _super = this.prototype;

        // Set up the prototype to inherit from the base class
        // (but without running the init constructor)
        var proto = Object.create(_super);

        // Copy the properties over onto the new prototype
        for (var name in props) {
          // Check if we're overwriting an existing function
          proto[name] = typeof props[name] === "function" &&
          typeof _super[name] == "function" && fnTest.test(props[name])
            ? (function(name, fn){
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
            })(name, props[name])
            : props[name];
        }

        // The new constructor
        var newClass = typeof proto.init === "function"
          ? proto.hasOwnProperty("init")
            ? proto.init // All construction is actually done in the init method
            : function SubClass(){ _super.init.apply(this, arguments); }
          : function EmptyClass(){};

        // Populate our constructed prototype object
        newClass.prototype = proto;

        // Enforce the constructor to be what we expect
        proto.constructor = newClass;

        // And make this class extendable
        newClass.extend = BaseClass.extend;

        return newClass;
      };

      // export
      global.Class = BaseClass;
    })(window);

    /*
     * Simple utility methods
     */

    window.ActiveScaffold = {
      last_focus: null,
      setup_callbacks: [],
      setup: function(container) {
        /* setup some elements on page/form load */
        ActiveScaffold.load_embedded(container);
        ActiveScaffold.enable_js_form_buttons(container);
        ActiveScaffold.auto_paginate(container);
        ActiveScaffold.draggable_lists('.draggable-lists', container);
        ActiveScaffold.sliders(container);
        ActiveScaffold.disable_optional_subforms(container);
        ActiveScaffold.update_floating_form_footer(); // check other forms too, state may change
        if (container != document) {
          jQuery('[data-rs-type]', container).each(function() { RecordSelect.from_attributes(jQuery(this)); });
        }
        ActiveScaffold.setup_callbacks.forEach(function(callback) { callback(container); });
      },
      setup_history_state: function() {
        if (!jQuery('.active-scaffold').length) return;
        var data = {}, current_search_item = jQuery('.active-scaffold .filtered-message[data-search]');
        if (current_search_item.length) {
          // store user settings enabled, update state with current page, search and sorting
          var sorted_columns = jQuery('th.sorted');
          data.page = jQuery('.active-scaffold-pagination .current').text();
          data.search = current_search_item.data('search');
          if (sorted_columns.length == 1) {
            data.sort = sorted_columns.attr('class').match(/(.+)-column/)[1];
            data.sort_direction = sorted_columns.hasClass('asc') ? 'asc' : 'desc';
          } else { // default search
            jQuery.extend(data, {sort: '', sort_direction: ''});
          }
        }
        ActiveScaffold.add_to_history(document.location.href, data, true);
      },
      auto_paginate: function(element) {
        var paginate_link = jQuery('.active-scaffold-pagination.auto-paginate a:first', element);
        if (paginate_link.length) {
          var pagination = paginate_link.closest('.auto-paginate');
          pagination.find('.as_paginate').hide();
          pagination.find('.loading-indicator').css({visibility: 'visible'});
          ActiveScaffold.auto_load_page(paginate_link.attr('href'), {auto_pagination: true});
        }
      },
      auto_load_page: function(href, params) {
        jQuery.get(href, params, null, 'script');
      },
      enable_js_form_buttons: function(element) {
        jQuery('.as-js-button', element).show();
      },
      disable_optional_subforms: function(element) {
        jQuery('.sub-form.optional', element).each(function () {
          var $this = jQuery(this), toggle = $this.find('>.visibility-toggle');
          if (toggle.length) {
            var hide = toggle.text() == toggle.data('show');
            $this.find('> [id] > .sub-form-record > .associated-record dl:first').each(function (i) {
              var parent = jQuery(this).parent(), div_id = toggle.data('toggable') + i;
              parent.children().wrapAll('<div id="' + div_id + '">');
              if (hide) parent.find('> div').hide();
              parent.prepend(toggle.clone().data('toggable', div_id));
            });
            toggle.remove();
          }
          if ($this.is(':visible')) {
            var line = $this.closest('.form-element'), toggle = line.find('.show-new-subform[data-subform-id="' + $this.attr('id') + '"]').first();
            if (toggle.is('[type=radio]')) toggle.prop('disabled', true);
            else if (toggle.data('select-id')) {
              var select = line.find('#' + toggle.data('select-id'));
              if (select.hasClass('recordselect') || select.is('.no-options')) select = select.next(':hidden').addBack();
              select.hide().prop('disabled', true);
            }
          } else $this.find("input:enabled,select:enabled,textarea:enabled").prop('disabled', true);
        });
      },
      sliders: function(element) {
        jQuery('.as-slider', element).each(function() {
          var opts = jQuery(this).data('slider');
          jQuery(this).slider(opts);
          if (opts.disabled) jQuery(this).find('.ui-slider-handle').hide();
        });
      },
      load_embedded: function(element) {
        jQuery('.active-scaffold-component .load-embedded', element).each(function(index, item) {
          item = jQuery(item);
          var indicator = item.closest('.active-scaffold-component').find('.loading-indicator');
          indicator.css({visibility: 'visible'});
          item.closest('.active-scaffold-component').load(item.attr('href'), function(response, status, xhr) {
            if (status == 'error') {
              indicator.css({visibility: 'hidden'});
              indicator.after(jQuery('<p>').html(item.data('error-msg')).addClass("error-message message server-error"));
            } else jQuery(this).trigger('as:element_updated');
          });
        });
      },
      reload_embedded: function(element_or_selector) {
        var item = jQuery(element_or_selector);
        item.load(item.data('refresh'), function() {
          jQuery(this).trigger('as:element_updated');
        });
      },

      records_for: function(tbody_id) {
        if (typeof(tbody_id) == 'string') tbody_id = '#' + tbody_id;
        return jQuery(tbody_id).children('.record');
      },
      stripe: function(tbody_id) {
        var even = false;
        var rows = this.records_for(tbody_id);

        rows.each(function (index, row_node) {
          var row = jQuery(row_node);
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
      show_empty_message: function(tbody) {
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
        scaffold.find('td.sorted').each(function(index, element) {
          jQuery(element).removeClass("sorted");
        });
        scaffold.find('th.sorted').each(function(index, element) {
          element = jQuery(element);
          element.removeClass("sorted");
          element.removeClass("asc");
          element.removeClass("desc");
        });
      },
      add_to_history: function(url, data, replace) {
        if (!history || !history.pushState) return;
        data = {active_scaffold: data};
        if (replace) history.replaceState(data, null, url);
        else history.pushState(data, null, url);
      },
      decrement_record_count: function(scaffold) {
        // decrement the last record count, firsts record count are in nested lists
        if (typeof(scaffold) == 'string') scaffold = '#' + scaffold;
        scaffold = jQuery(scaffold);
        var count = scaffold.find('span.active-scaffold-records').last();
        if (count) count.html(parseInt(count.html(), 10) - 1);
      },
      increment_record_count: function(scaffold) {
        // increment the last record count, firsts record count are in nested lists
        if (typeof(scaffold) == 'string') scaffold = '#' + scaffold;
        scaffold = jQuery(scaffold);
        var count = scaffold.find('span.active-scaffold-records').last();
        if (count) count.html(parseInt(count.html(), 10) + 1);
      },
      update_row: function(row, html) {
        var even_row = false;
        var replaced = null;
        if (typeof(row) == 'string') row = '#' + row;
        row = jQuery(row);
        if (row.hasClass('even-record')) even_row = true;

        replaced = this.replace(row, html);
        if (replaced) {
          if (even_row === true) replaced.addClass('even-record');
          ActiveScaffold.highlight(replaced);
        }
      },

      replace: function(element, html) {
        if (typeof(element) == 'string') element = '#' + element;
        element = jQuery(element);
        var new_element = typeof(html) == 'string' ? jQuery.parseHTML(jQuery.trim(html), true) : html;
        new_element = jQuery(new_element);
        if (element.length) {
          element.replaceWith(new_element);
          new_element.trigger('as:element_updated');
          return new_element;
        } else return null;
      },

      replace_html: function(element, html) {
        if (typeof(element) == 'string') element = '#' + element;
        element = jQuery(element);
        if (element.length) {
          element.html(html);
          element.trigger('as:element_updated');
        }
        return element;
      },

      append: function(element, html) {
        if (typeof(element) == 'string') element = '#' + element;
        element = jQuery(element);
        element.append(html);
        element.trigger('as:element_updated');
        return element;
      },

      remove: function(element, callback) {
        if (typeof(element) == 'string') element = '#' + element;
        jQuery(element).trigger('as:element_removed').remove();
        if (callback) callback();
      },

      update_inplace_edit: function(element, value, empty) {
        if (typeof(element) == 'string') element = '#' + element;
        this.replace_html(jQuery(element), value);
        jQuery(element).closest('td')[empty ? 'addClass' : 'removeClass']('empty');
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

      disable_form: function(as_form, skip_loading_indicator) {
        if (typeof(as_form) == 'string') as_form = '#' + as_form;
        as_form = jQuery(as_form);
        var loading_indicator = jQuery('#' + as_form.attr('id').replace(/-form$/, '-loading-indicator'));
        if (!skip_loading_indicator && loading_indicator) loading_indicator.css('visibility','visible');
        jQuery('input[type=submit]', as_form).attr('disabled', 'disabled');
        jQuery('.sub-form a.destroy', as_form).addClass('disabled');
        if (jQuery.fn.droppable) jQuery('.draggable-list', as_form).sortable('disable');
        // data-remote-disabled attr instead of set data because is used to in selector later
        jQuery("input:enabled,select:enabled,textarea:enabled", as_form).attr('disabled', 'disabled').attr('data-remove-disabled', true);
      },

      enable_form: function(as_form, skip_loading_indicator) {
        if (typeof(as_form) == 'string') as_form = '#' + as_form;
        as_form = jQuery(as_form)
        var loading_indicator = jQuery('#' + as_form.attr('id').replace(/-form$/, '-loading-indicator'));
        if (!skip_loading_indicator && loading_indicator) loading_indicator.css('visibility','hidden');
        jQuery('input[type=submit]', as_form).removeAttr('disabled');
        jQuery('.sub-form a.destroy.disabled', as_form).removeClass('disabled');
        if (jQuery.fn.droppable) jQuery('.draggable-list', as_form).sortable('enable');
        jQuery("input[data-remove-disabled],select[data-remove-disabled],textarea[data-remove-disabled]", as_form).removeAttr('disabled data-remove-disabled');
      },

      focus_first_element_of_form: function(form_element, form_selector) {
        if (typeof(form_element) == 'string') form_element = '#' + form_element;
        if (typeof(form_selector) == 'undefined') form_selector = jQuery(form_element).is('form') ? '' : 'form ';
        var input = jQuery(form_selector + ":input:visible:first", jQuery(form_element));
        if (input.is('.no-autofocus :input')) return;
        input.focus();
        try {
          if (input[0] && input[0].value) input[0].selectionStart = input[0].selectionEnd = input[0].value.length;
        } catch(e) {}
      },

      create_record_row: function(active_scaffold_id, html, options) {
        if (typeof(active_scaffold_id) == 'string') active_scaffold_id = '#' + active_scaffold_id;
        var tbody = jQuery(active_scaffold_id).find(options.body_selector || 'tbody.records').first(), new_row;

        if (options.insert_at == 'top') {
          tbody.prepend(html);
          new_row = tbody.children('tr.record:first-child');
        } else if (options.insert_at == 'bottom') {
          var rows = tbody.children('tr.record, tr.inline-adapter');
          if (rows.length > 0) {
            new_row = rows.last().after(html).next();
          } else {
            new_row = tbody.append(html).children().last();
          }
        } else if (typeof options.insert_at == 'object') {
          var insert_method, get_method, row, id;
          if (options.insert_at.after) {
            insert_method = 'after';
            get_method = 'next';
          } else {
            insert_method = 'before';
            get_method = 'prev';
          }
          if (id = options.insert_at[insert_method]) row = tbody.children('#' + id);
          if (row && row.length) {
            new_row = row[insert_method](html)[get_method]();
          }
        }
        this.stripe(tbody);
        this.hide_empty_message(tbody);
        this.increment_record_count(tbody.closest('div.active-scaffold'));
        this.highlight(new_row);
        new_row.trigger('as:element_created');
      },

      create_record_row_from_url: function(action_link, url, options) {
        jQuery.get(url, function(row) {
          ActiveScaffold.create_record_row(action_link.scaffold(), row, options);
          action_link.close();
        });
      },

      delete_record_row: function(row, page_reload_url, body_selector) {
        if (typeof(row) == 'string') row = '#' + row;
        row = jQuery(row);
        var tbody = row.closest(body_selector || 'tbody.records');

        row.find('a.disabled').each(function() {;
          var action_link = ActiveScaffold.ActionLink.get(this);
          if (action_link) action_link.close();
        });

        ActiveScaffold.remove(row, function() {
          ActiveScaffold.stripe(tbody);
          ActiveScaffold.decrement_record_count(tbody.closest('div.active-scaffold'));
          if (page_reload_url) ActiveScaffold.reload_if_empty(tbody, page_reload_url);
          else ActiveScaffold.show_empty_message(tbody);
        });
      },

      report_500_response: function(active_scaffold_id, xhr) {
        var server_error = jQuery(active_scaffold_id).find('.messages-container p.server-error').first();
        if (server_error.is(':visible')) {
          ActiveScaffold.highlight(server_error);
        } else {
          server_error.show();
        }
        if (xhr) server_error.find('.error-500')[xhr.status < 500 ? 'hide' : 'show']();
        ActiveScaffold.scroll_to(server_error, ActiveScaffold.config.scroll_on_close == 'checkInViewport');
      },

      find_action_link: function(element) {
        if (typeof(element) == 'string') element = '#' + element;
        element = jQuery(element);
        return ActiveScaffold.ActionLink.get(element.is('.actions a') ? element : element.closest('.as_adapter'));
      },

      display_dynamic_action_group: function(link, html) {
        var container;
        if (typeof(link) == 'string') link = jQuery('#' + link);
        if (link.parent('.actions').length) link.wrap(jQuery('<div>'));
        container = link.parent().addClass('action_group dyn');
        if (ActiveScaffold.config.dynamic_group_parent_class) {
          container.addClass(ActiveScaffold.config.dynamic_group_parent_class);
        }
        container.find('> ul.dynamic-menu').remove();
        container.append(html);
      },

      scroll_to: function(element, checkInViewport) {
        if (typeof checkInViewport == 'undefined') checkInViewport = true;
        if (typeof(element) == 'string') element = '#' + element;
        element = jQuery(element);
        if (!element.length) return;
        if (checkInViewport && element.visible()) return;
        jQuery(document).scrollTop(element.offset().top);
      },

      process_checkbox_inplace_edit: function(checkbox, options) {
        var checked = checkbox.is(':checked'), td = checkbox.closest('td');
        if (checked === true) options['params'] += '&value=1';
        jQuery.ajax({
          url: options.url,
          type: "POST",
          data: options['params'],
          dataType: options.ajax_data_type,
          beforeSend: function(request, settings) {
            if (options.beforeSend) options.beforeSend.call(checkbox, request, settings);
            checkbox.attr('disabled', 'disabled');
            td.closest('tr').find('td.actions .loading-indicator').css('visibility','visible');
          },
          complete: function(request){
            checkbox.removeAttr('disabled');
          },
          success: function(request){
            td.closest('tr').find('td.actions .loading-indicator').css('visibility','hidden');
          }
        });
      },

      read_inplace_edit_heading_attributes: function(column_heading, options) {
        if (column_heading.data('ie-cancel-text')) options.cancel_button = '<button class="inplace_cancel">' + column_heading.data('ie-cancel-text') + "</button>";
        if (column_heading.data('ie-loading-text')) options.loading_text = column_heading.data('ie-loading-text');
        if (column_heading.data('ie-saving-text')) options.saving_text = column_heading.data('ie-saving-text');
        if (column_heading.data('ie-save-text')) options.save_button = '<button class="inplace_save">' + column_heading.data('ie-save-text') + "</button>";
        if (column_heading.data('ie-rows')) options.textarea_rows = column_heading.data('ie-rows');
        if (column_heading.data('ie-cols')) options.textarea_cols = column_heading.data('ie-cols');
        if (column_heading.data('ie-size')) options.text_size = column_heading.data('ie-size');
        if (column_heading.data('ie-use-html')) options.use_html = column_heading.data('ie-use-html');
      },

      create_inplace_editor: function(span, options) {
        span.removeClass('hover');
        span.editInPlace(options);
        span.trigger('click.editInPlace');
      },

      highlight: function(element) {
        if (typeof(element) == 'string') element = jQuery('#' + element);
        if (typeof(element.effect) == 'function') {
          element.effect("highlight", jQuery.extend({}, ActiveScaffold.config.highlight), 3000);
        }
      },

      create_associated_record_form: function(element, content, options) {
        if (typeof(element) == 'string') element = '#' + element;
        var element = jQuery(element);
        content = jQuery(content);
        if (options.singular == false) {
          if (!(options.id && jQuery('#' + options.id).size() > 0)) {
            var tfoot = element.children('tfoot');
            if (tfoot.length) tfoot.before(content);
            else element.append(content);
          }
        } else {
          var current = jQuery('#' + element.attr('id') + ' .sub-form-record')
          if (current[0]) {
            this.replace(current[0], content);
          } else {
            element.prepend(content);
          }
        }
        content.trigger('as:element_created');
        ActiveScaffold.focus_first_element_of_form(content, '');
      },

      render_form_field: function(source, content, options) {
        if (typeof(source) == 'string') source = '#' + source;
        var source = jQuery(source);
        var element, container = source.closest('.sub-form-record'), selector = '';
        if (container.length === 0) {
          container = source.closest('form > ol.form');
          selector = '>';
        }
        if (options.traverse) {
          selector = '';
          options.traverse.forEach(function(step) {
            if (step === '__root__') container = container.closest('form');
            else container = container.find(step);
          });
        }
        // find without entering new subforms
        element = container.find(selector + ':not(.sub-form) .' + options.field_class);
        if (container.is('.sub-form-record'))
          element = element.filter(function() { return jQuery(this).closest('.sub-form-record').get(0) === container.get(0); });
        else element = element.filter(function() { return jQuery(this).closest('.sub-form-record').length === 0; });
        if (element.length)
          element = element.first().closest('.form-element');
        else if (options.subform_class)
          element = container.find(selector + '.' + options.subform_class).first();

        if (element.length) {
          var parent = element.is('.sub-form, .form-element') ? element : element.parent('.form-element, .sub-form');
          if (element.is('.sub-form, .form-element'))
            this.replace_html(element, content);
          else
            this.replace(element, content);
          if (parent.is('.form-element, .sub-form')) {
            for (var attr in options.attrs)
              parent.attr(attr, options.attrs[attr]);
          }
          if (typeof(options.hidden) != 'undefined')
            parent[options.hidden ? 'addClass' : 'removeClass'].call(parent, 'hidden')
        }
      },

      record_select_onselect: function(edit_associated_url, active_scaffold_id, id){
        jQuery.ajax({
          url: edit_associated_url.replace('--ID--', id),
          error: function(xhr, textStatus, errorThrown){
            ActiveScaffold.report_500_response(active_scaffold_id, xhr)
          }
        });
      },

      // element is tbody id
      mark_records: function(element, options) {
        if (typeof(element) == 'string') element = '#' + element;
        var element = jQuery(element);
        if (options.include_checkboxes) {
          var mark_checkboxes = jQuery('#' + element.attr('id') + ' > tr.record td.as_marked-column input[type="checkbox"]');
          mark_checkboxes.prop('checked', !!options.checked);
          mark_checkboxes.val('' + !options.checked);
        }
        if(options.include_mark_all) {
          var mark_all_checkbox = element.prevAll('thead').find('th.as_marked-column_heading span input[type="checkbox"]');
          mark_all_checkbox.prop('checked', !!options.checked);
          mark_all_checkbox.val('' + !options.checked);
        }
      },

      in_place_editor_field_clicked: function(span) {
        // test editor is open
        if (typeof(span.data('editInPlace')) === 'undefined') {
          var options = {show_buttons: true,
              hover_class: 'hover',
              element_id: 'editor_id',
              ajax_data_type: "script",
              delegate: {
                willCloseEditInPlace: function(span, options) {
                  if (span.data('addEmptyOnCancel')) span.closest('td').addClass('empty');
                  span.closest('tr').find('td.actions .loading-indicator').css('visibility','visible');
                },
                didCloseEditInPlace: function(span, options) {
                  span.closest('tr').find('td.actions .loading-indicator').css('visibility','hidden');
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
            column_heading = my_parent.closest('table').find('th:eq(' + column_no + ')');
          } else if (my_parent.is('th')) {
            column_heading = my_parent;
          }

          var render_url = column_heading.data('ie-render-url'),
            mode = column_heading.data('ie-mode'),
            record_id = span.data('ie-id') || '';

          ActiveScaffold.read_inplace_edit_heading_attributes(column_heading, options);

          if (span.data('ie-url')) {
            options.url = span.data('ie-url').replace(/__id__/, record_id);
          } else {
            options.url = column_heading.data('ie-url').replace(/__id__/, record_id);
          }

          if (csrf_param) options['params'] = csrf_param.attr('content') + '=' + csrf_token.attr('content');

          if (span.closest('div.active-scaffold').data('eid')) {
            if (options['params'].length > 0) {
              options['params'] += "&";
            }
            options['params'] += ("eid=" + span.closest('div.active-scaffold').data('eid'));
          }

          if (mode === 'clone') {
            options.clone_id_suffix = record_id;
            options.clone_selector = '#' + column_heading.attr('id') + ' .as_inplace_pattern';
            options.field_type = 'clone';
          }

          if (render_url) {
            var plural = false;
            if (column_heading.data('ie-plural')) plural = true;
            options.field_type = 'remote';
            options.editor_url = render_url.replace(/__id__/, record_id)
            if (!options.delegate) options.delegate = {}
            options.delegate.didOpenEditInPlace = function(dom) { dom.trigger('as:element_updated'); }
          }
          var actions, forms;
          options.beforeSend = function(xhr, settings) {
            switch (span.data('ie-update')) {
              case 'update_row':
                actions = span.closest('tr').find('.actions a:not(.disabled)').addClass('disabled');
                break;
              case 'update_table':
                var table = span.closest('.as_content');
                actions = table.find('.actions a:not(.disabled)').addClass('disabled');
                forms = table.find('.as_form');
                ActiveScaffold.disable_form(forms);
                break;
            }
          }
          options.error = options.success = function() {
            if (actions) actions.removeClass('disabled');
            if (forms) ActiveScaffold.enable_form(forms);
          }
          if (mode === 'inline_checkbox') {
            ActiveScaffold.process_checkbox_inplace_edit(span.find('input:checkbox'), options);
          } else {
            ActiveScaffold.create_inplace_editor(span, options);
          }
        }
      },

      update_column: function(element, url, send_form, source_id, val, additional_params) {
        if (!element) element = jQuery('#' + source_id);
        var as_form = element.closest('form.as_form');
        var params = null;

        if (send_form) {
          var selector, base = as_form;
          if (send_form == 'row') base = element.closest('.association-record, form');
          if (selector = element.data('update_send_form_selector'))
            params = base.find(selector).serialize();
          else if (base != as_form) params = base.find(':input').serialize();
          else params = base.serialize();
          params += '&_method=&' + jQuery.param({"source_id": source_id});
          if (additional_params) params += '&' + additional_params;
        } else {
          params = {value: val};
          params.source_id = source_id;
        }

        jQuery.ajax({
          url: url,
          data: params,
          type: 'post',
          dataType: 'script',
          beforeSend: function(xhr, settings) {
            element.nextAll('img.loading-indicator').css('visibility','visible');
            /* force to blur and save previous last_focus, because disable_form will trigger
             * blur on focused element and we will not be able to restore focus later
             */
            var last_focus = ActiveScaffold.last_focus;
            if (last_focus) {
              jQuery(last_focus).blur();
              ActiveScaffold.last_focus = last_focus;
            }
            //ActiveScaffold.disable_form(as_form); // not needed: called from on('ajax:beforeSend', 'form.as_form')

            if (jQuery.rails.fire(element, 'ajax:beforeSend', [xhr, settings])) {
              element.trigger('ajax:send', xhr);
            } else {
              jQuery(ActiveScaffold.last_focus).focus();
              return false;
            }
          },
          success: function(data, status, xhr) {
            as_form.find('#'+element.attr('id')).trigger('ajax:success', [data, status, xhr]);
          },
          complete: function(xhr, status) {
            element = as_form.find('#'+element.attr('id'));
            element.nextAll('img.loading-indicator').css('visibility','hidden');
            var complete_element = element.length ? element : as_form;
            complete_element.trigger('ajax:complete', [xhr, status]);
            if (ActiveScaffold.last_focus) {
              var item = jQuery(ActiveScaffold.last_focus);
              if (item.closest('body').length == 0 && item.attr('id')) item = jQuery('#' + item.attr('id'));
              if (status != 'error') item.focus().select();
            }
          },
          error: function (xhr, status, error) {
            element = as_form.find('#'+element.attr('id'));
            element.trigger('ajax:error', [xhr, status, error]);
          }
        });
      },

      update_all_checkboxes: function(button, state) {
        var lists = button.closest('.check-buttons').parent().find('.checkbox-list'),
          checkboxes = lists.find(':checkbox'), key = state ? '_added' : '_removed', params;
        params = checkboxes.filter(state ? ':not(:checked)' : ':checked').map(function() { return key + '[]=' + jQuery(this).val(); }).toArray().join('&');
        checkboxes.prop('checked', state);
        if (lists.filter('.draggable-list').length) {
          var parent = state ? lists.filter('.selected') : lists.filter(':not(.selected)');
          checkboxes.parent().appendTo(parent);
        }
        checkboxes.first().trigger('change', params);
      },

      draggable_lists: function(selector_or_elements, parent) {
        var elements;
        if (!jQuery.fn.draggableLists) return;
        if (typeof(selector_or_elements) == 'string') elements = jQuery(selector_or_elements, parent);
        else elements = jQuery(selector_or_elements);
        elements.draggableLists();
      },

      setup_warn_changes: function() {
        var need_confirm = false;
        var unload_message = jQuery('meta[name=unload-message]').attr('content') || ActiveScaffold.config.unload_message || "This page contains unsaved data that will be lost if you leave this page.";
        jQuery(document).on('change input', '.active-scaffold form:not(.search) input, .active-scaffold form:not(.search) textarea, .active-scaffold form:not(.search) select', function() {
          jQuery(this).closest('form').addClass('need-confirm');
        });
        jQuery(document).on('click', '.active-scaffold .as_cancel:not([data-remote]), .active-scaffold input[type=submit]', function() {
          jQuery(this).closest('form').removeClass('need-confirm');
        });
        window.onbeforeunload = function() {
          if (jQuery('form.need-confirm').length) return unload_message;
        };
        jQuery(document).on('turbolinks:before-visit turbolinks:before-visit', function(e) {
          if (jQuery('form.need-confirm').length) {
            if (!window.confirm(unload_message)) e.preventDefault();
          }
        });
      },

      update_floating_form_footer: function() {
        jQuery('.active-scaffold form.floating-footer .form-footer').each(function () {
          var $footer = jQuery(this), $form = $footer.closest('form.floating-footer');
          $footer.removeClass('floating');
          if ($form.visible(true) && !$footer.visible(true)) $footer.addClass('floating');
        });
      },

      open_popup: function(content, link) {
        var element = jQuery(content).filter(function(){ return this.tagName; })
        if (link.adapter) link.adapter.dialog('close');
        element.dialog({
          modal: true,
          close: function () {
            if (!link.adapter.is('.loading')) link.close();
          },
          width: ActiveScaffold.config.popup_width || '80%'
        });
        link.set_adapter(element);
      },

      close_popup: function(link, callback) {
        link.adapter.dialog('close');
        ActiveScaffold.remove(link.adapter, callback);
        link.set_adapter(null);
      }
    }


    jQuery(window).on('scroll resize', ActiveScaffold.update_floating_form_footer);

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
          return _this.instantiate_link(link);
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
        element = jQuery(element);
        if (element.length > 0) {
          element.data(); // $ 1.4.2 workaround
          if (typeof(element.data('action_link')) === 'undefined' && !element.hasClass('as_adapter')) {
            var parent = element.parent().closest('.record');
            if (parent.length === 0) parent = element.parent().closest('.actions');
            if (parent.length === 0) parent = element.parent().closest('form.as_form');
            if (parent.is('.record')) {
              // record action
              var target = parent.find('a.as_action');
              var loading_indicator = parent.find('.actions .loading-indicator');
              if (!loading_indicator.length) loading_indicator = element.parent().find('.loading-indicator');
              new ActiveScaffold.Actions.Record(target, parent, loading_indicator);
            } else if (parent.is('.active-scaffold-header .actions')) {
              //table action
              new ActiveScaffold.Actions.Table(parent.find('a.as_action'), parent.closest('div.active-scaffold').find('tbody.before-header').first(), parent.find('.loading-indicator').first());
            } else if (parent.is('form.as_form')) {
              //table action
              new ActiveScaffold.Actions.Table(parent.find('a.as_action').filter(function() { return !jQuery(this).data('action_link'); }), parent.closest('div.active-scaffold').find('tbody.before-header').first(), parent.find('.form-footer .loading-indicator').first());
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
        this.method = this.tag.data('method') || 'get';
        this.target = target;
        this.content = target.closest('.active-scaffold').find('.as_content:first');
        this.loading_indicator = loading_indicator;
        this.hide_target = false;
        this.position = this.tag.data('position');
        this.action = this.tag.data('action');

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
        var link = this, callback = function() {
          link.enable();
          if (link.hide_target) link.target.show();
          if (link.hide_content) link.content.show();
          if (ActiveScaffold.config.scroll_on_close) {
            ActiveScaffold.scroll_to(link.target.attr('id'), ActiveScaffold.config.scroll_on_close === 'checkInViewport');
          }
        };
        if (this.position === 'popup') {
          ActiveScaffold.close_popup(this, callback);
        } else if (this.adapter) {
          ActiveScaffold.remove(this.adapter, callback);
        }
      },

      reload: function() {
        this.close();
        this.open();
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
        const div_id = this.scaffold().attr('id');
        if (div_id) return '#' + div_id;
      },

      scaffold: function() {
        return this.tag.closest('div.active-scaffold');
      },

      messages: function() {
        const re = /-active-scaffold$/, div_id = this.scaffold_id();

        if (re.test(div_id)) {
          return jQuery(div_id.replace(re, '-messages'));
        } else {
          var messages_container = this.scaffold().find('.messages-container'),
            messages = messages_container.find('.action-messages');
          if (!messages.length) messages = jQuery('<div class="action-messages"></div>').appendTo(messages_container);
          return messages;
        }
      },

      update_flash_messages: function(messages) {
        this.messages().html(messages);
      },

      set_adapter: function(element) {
        this.adapter = element;
        if (element) {
          this.adapter.addClass('as_adapter');
          this.adapter.data('action_link', this);
          if (this.refresh_url) jQuery('.as_cancel', this.adapter).attr('href', this.refresh_url);
        }
      },

      keep_open: function() {
        return this.tag.data('keep-open');
      }
    });

    /**
     * Concrete classes for record actions
     */
    ActiveScaffold.Actions.Record = ActiveScaffold.Actions.Abstract.extend({
      instantiate_link: function(link) {
        var l = new ActiveScaffold.ActionLink.Record(link, this.target, this.loading_indicator);
        var refresh = this.target.data('refresh');
        if (refresh) l.refresh_url = this.target.closest('.records').data('refresh-record').replace('--ID--', refresh);

        if (l.position) {
          l.url = l.url.append_params({adapter: l.position == 'popup' ? '_popup_adapter' : '_list_inline_adapter'});
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
          if (item.url != _this.url && item.is_disabled() && !item.keep_open() && item.adapter) {
            ActiveScaffold.remove(item.adapter, function () { item.enable(); });
          }
        });
      },

      insert: function(content) {
        this.close_previous_adapter();

        if (this.position === 'replace') {
          this.position = 'after';
          this.hide_target = true;
        } else if (this.position === 'table') {
          this.hide_content = true;
        } else if (this.position === 'popup') {
          return ActiveScaffold.open_popup(content, this);
        }

        var colspan = this.target.children().length;
        if (content && this.position) {
          content = jQuery(content);
          content.find('.inline-adapter-cell:first').attr('colspan', colspan);
        }
        if (this.position === 'after') {
          this.target.after(content);
          this.set_adapter(this.target.next());
        } else if (this.position === 'before') {
          this.target.before(content);
          this.set_adapter(this.target.prev());
        } else if (this.position === 'table') {
          var content_parent = this.target.closest('div.active-scaffold').find('tbody.before-header').first()
          content_parent.prepend(content);
          this.set_adapter(content_parent.children().first())
        } else {
          return false;
        }
        ActiveScaffold.highlight(this.adapter.find('td'));
        ActiveScaffold.focus_first_element_of_form(this.adapter);
      },

      close: function(refreshed_content_or_reload) {
        this._super();
        if (refreshed_content_or_reload) {
          if (typeof refreshed_content_or_reload == 'string') this.refresh(refreshed_content_or_reload);
          else this.refresh();
        }
      },

      refresh: function(content) {
        if (content) {
          ActiveScaffold.update_row(this.target, content);
        } else if (this.refresh_url) {
          var target = this.target;
          jQuery.get(this.refresh_url, function(e, status, xhr) {
            ActiveScaffold.update_row(target, xhr.responseText);
          });
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
        if (this.position === 'after') {
          this.set_adapter(this.target.next());
        }
        else if (this.position === 'before') {
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
          l.url = l.url.append_params({adapter: l.position == 'popup' ? '_popup_adapter' : '_list_inline_adapter'});
          l.tag.attr('href', l.url);
        }
        return l;
      }
    });

    ActiveScaffold.ActionLink.Table = ActiveScaffold.ActionLink.Abstract.extend({
      insert: function(content) {
        if (this.position == 'replace') {
          this.position = 'top';
          this.hide_content = true;
        } else if (this.position == 'popup') {
          return ActiveScaffold.open_popup(content, this);
        }

        if (this.position == 'top') {
          this.target.prepend(content);
          this.set_adapter(this.target.children().first());
        } else {
          throw 'Unknown position "' + this.position + '"'
        }
        ActiveScaffold.highlight(this.adapter.find('td').first().children().not('script'));
        ActiveScaffold.focus_first_element_of_form(this.adapter);
      }
    });
  };

  if (window.jQuery) {
    activeScaffoldInit(jQuery);
  } else if (typeof exports === 'object' && typeof module === 'object') {
    module.exports = activeScaffoldInit;
  }
})();
