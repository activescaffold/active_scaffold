# frozen_string_literal: true

module ActiveScaffold
  module Helpers
    module ListColumnHelpers
      module Headings
        def local_sorting?
          @page&.pager&.number_of_pages == 1 && active_scaffold_config.list.local_sorting
        end

        # MARK

        def all_marked?
          if active_scaffold_config.mark.mark_all_mode == :page
            @page.items.all? { |record| marked_records.key?(record.id) }
          else
            marked_records.length >= @page.pager.count.to_i
          end
        end

        def mark_column_heading
          tag_options = {
            id: "#{controller_id}_mark_heading",
            class: 'mark_heading in_place_editor_field'
          }
          content_tag(:span, check_box_tag("#{controller_id}_mark_heading_span_input", '1', all_marked?), tag_options)
        end

        # COLUMN HEADINGS

        def column_heading_attributes(column, sorting, sort_direction)
          {id: active_scaffold_column_header_id(column), class: column_heading_class(column, sorting),
           title: strip_tags(column.description).presence}
        end

        def render_column_heading(column, sorting, sort_direction)
          tag_options = column_heading_attributes(column, sorting, sort_direction)
          if column.name == :as_marked
            tag_options[:data] = {
              ie_mode: :inline_checkbox,
              ie_url: url_for(signed_url_options(params_for(action: 'mark', id: '__id__')))
            }
          elsif column.inplace_edit
            tag_options[:data] = inplace_edit_data(column)
          end

          content_tag(:th, column_heading_value(column, sorting, sort_direction) + inplace_edit_control(column),
                      tag_options)
        end

        def column_heading_value(column, sorting, sort_direction)
          if column.name == :as_marked
            mark_column_heading
          elsif column.sortable?
            options = {id: nil, class: 'as_sort',
                       'data-page-history' => controller_id,
                       remote: true, method: :get}
            url_options = {action: :index, page: 1, sort: column.name, sort_direction: sort_direction}
            # :id needed because rails reuse it even if it was deleted from params (like do_refresh_list does)
            url_options[:id] = nil if @remove_id_from_list_links
            url_options = params_for(url_options)
            if !active_scaffold_config.store_user_settings && respond_to?(:search_params) && search_params.present?
              url_options[:search] = search_params
            end
            link_to column_heading_label(column), signed_url_options(url_options), options
          else
            content_tag(:p, column_heading_label(column))
          end
        end

        def column_heading_label(column)
          column.label
        end
      end
    end
  end
end
