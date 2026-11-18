# frozen_string_literal: true

module ActiveScaffold::Actions
  module Core
    module RenderField
      def render_field
        if request.get? || request.head?
          render_field_for_inplace_editing
          respond_to do |format|
            format.js { render action: 'render_field_inplace', layout: false }
          end
        elsif params[:tabbed_by]
          add_tab
          respond_to do |format|
            format.js { render action: 'add_tab', layout: false }
          end
        else
          render_field_for_update_columns
          respond_to { |format| format.js }
        end
      end

      protected

      def render_field_for_inplace_editing
        @column = active_scaffold_config.columns[params[:update_column]]
        @record = find_if_allowed(params[:id], crud_type: :update, column: params[:update_column])
      end

      def add_tab
        process_render_field_params
        @column = @main_columns.find_by_name(params[:column])
        @record = updated_record_with_form(@main_columns, {}, @scope)
      end

      def process_render_field_params
        @source_id = params.delete(:source_id)
        @scope = params.delete(:scope)
        @form_action = render_field_form_action

        subform_columns = render_field_subform_columns
        action_cfg = active_scaffold_config.send(@form_action)
        @main_columns = subform_columns ? action_cfg.build_action_columns(subform_columns) : action_cfg.columns
      end

      def render_field_form_action
        if @scope
          form_action = :subform
        elsif active_scaffold_config.actions.include? params[:form_action]&.to_sym
          form_action = params.delete(:form_action).to_sym
        end

        form_action || (params[:id] ? :update : :create)
      end

      def render_field_subform_columns
        return unless @scope

        controller = main_form_controller
        return unless controller

        column = parent_column(controller, @scope)
        return unless column

        (column.form_ui_options || column.options)&.dig(:subform_columns)
      end

      def render_field_for_update_columns
        return if (@column = active_scaffold_config.columns[params.delete(:column)]).nil?

        @columns = @column.update_columns || []
        @columns += [@column.name] if @column.options[:refresh_link] && @columns.exclude?(@column.name)
        process_render_field_params
        prepare_record_for_render_field
        after_render_field(@record, @column)
      end

      def prepare_record_for_render_field
        @record = find_from_scope(setup_parent, @scope) if @scope && main_form_controller
        if @column.send_form_on_update_column
          @record ||= updated_record_with_form(@main_columns, params[:record] || params[:search], @scope)
        elsif @record
          update_column_from_params(@record, @column, params.delete(:value), avoid_changes: true)
        else
          @record = updated_record_with_column(@column, params.delete(:value), @scope)
        end
      end

      def updated_record_with_form(columns, attributes, scope)
        if attributes && scope
          attributes = attributes_from_scope(attributes, scope)
          id = attributes&.[](:id)
        else
          id = params[:id]
        end

        # call update_record_from_params with new_model, in other case some associations can be saved
        @form_record = new_model
        # check permissions and support overriding to_param, preload associations
        copy_data_from_saved_record(id, active_scaffold_config, @form_record) if id
        apply_constraints_to_record(@form_record) unless scope
        create_association_with_parent @form_record, check_match: true if nested?
        if @form_action == :field_search
          update_columns_from_params(
            @form_record, columns, attributes || {}, :read,
            avoid_changes: true, search_attributes: true
          )
        else
          update_record_from_params(@form_record, columns, attributes || {}, avoid_changes: true)
        end
      end

      def updated_record_with_column(column, value, scope)
        record = params[:id] ? copy_data_from_saved_record(params[:id]) : new_model
        apply_constraints_to_record(record) unless scope || params[:id]
        create_association_with_parent record, check_match: true if nested?
        if @form_action == :field_search && value.is_a?(Array) && column.association&.singular?
          # don't assign value if it's an array and column is singular association,
          # e.g. value came from multi-select on search form
          # use instance variable so it's available in the view and helpers
          @value = value
        else
          update_column_from_params(record, column, value, avoid_changes: true)
        end
        record.id = params[:id]
        record
      end

      def setup_parent
        cfg = main_form_controller.active_scaffold_config
        parent = cfg.model.new
        copy_data_from_saved_record(params[:parent_id], cfg, parent) if params[:parent_id]
        apply_constraints_to_record(parent) unless params[:parent_id]
        if @column.send_form_on_update_column
          parent = update_record_from_params(
            parent, cfg.send(params[:parent_id] ? :update : :create).columns, params[:record], avoid_changes: true
          )
        end

        if params[:nested] # form in nested scaffold, set nested parent_record to parent
          nested = ActiveScaffold::DataStructures::NestedInfo.get(parent.class, params[:nested])
          if nested&.child_association && !nested.child_association.polymorphic?
            apply_constraints_to_record(parent, constraints: {nested.child_association.name => nested.parent_id})
          end
        end
        @form_record = parent
      end

      def copy_data_from_saved_record(id, config = active_scaffold_config, record = nil)
        preload_values = preload_for_form(config.update.columns) if config.actions.include?(:update)
        saved_record = find_if_allowed(id, :read, config.model.preload(preload_values))
        copy_attributes(saved_record, record).tap { |new_record| new_record.id = id }
      end

      def parent_column(parent_controller, scope)
        attrs = params[:record]
        parts = scope_parts(scope)
        columns = parent_controller.active_scaffold_config.columns
        column = nil

        while parts.present?
          column = columns[parts.shift]
          return unless column&.association
          break if parts.blank?

          klass = parent_column_association_class(column, attrs)
          return unless klass

          columns = active_scaffold_config_for(klass).columns
          attrs = attrs&.dig(column.name)
          attrs = attrs&.dig(parts.shift) if column.association.collection?
        end

        column
      end

      def parent_column_association_class(column, attributes)
        return column.association.klass unless column.association.polymorphic? && attributes

        record = column.active_record_class.new(
          column.association.foreign_type => attributes[column.association.foreign_type]
        )
        column.association.klass(record)
      end

      def find_from_scope(parent, scope)
        parts = scope_parts(scope)
        record = parent

        while parts.present?
          part = parts.shift
          return unless record.respond_to?(part)

          association = record.class.reflect_on_association(part)
          id = association&.collection? ? parts.shift.to_i : nil
          record = record.send(part)
          if id
            record = record.find { |child| child.id == id }
            record ||= @new_records&.dig(association.klass, id.to_s)
          end
          return if record.nil?
        end

        record
      end

      def scope_parts(scope)
        return [] unless scope

        scope[1..-2].split('][')
      end

      def attributes_from_scope(attributes, scope)
        scope_parts(scope).inject(attributes) { |scoped_attributes, part| scoped_attributes&.[](part) }
      end

      def copy_attributes(orig, dst = nil)
        dst ||= orig.class.new
        orig.attributes.each { |attr, value| dst.send :write_attribute, attr, value }
        orig.class.reflect_on_all_associations.each do |assoc|
          next unless orig.send(:association_cached?, assoc.name)

          dst.association(assoc.name).target = orig.association(assoc.name).target
        end
        dst.changes_applied
        dst
      end

      # override this method if you want to do something after render_field
      def after_render_field(record, column); end
    end
  end
end
