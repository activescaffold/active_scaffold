# frozen_string_literal: true

module ActiveScaffold
  module Helpers
    module ActionLinkHelpers
      module ColumnLinks
        # Set up an association-column action link for its inline form.
        def action_link_to_inline_form(link, record)
          link = link.dup
          associated = record.send(link.column.association.name)
          if link.column.association&.polymorphic? || link.controller.nil?
            link.controller = controller_path_for_activerecord(associated.class)
            return link if link.controller.nil?
          end
          link = configure_column_link(link, record, associated) if link.action.nil?
          link
        end

        def configure_column_link(link, record, associated, actions = nil)
          actions ||= link.controller_actions || []
          _as_configure_column_link_action(link, associated, actions)

          unless column_link_authorized?(link, link.column, record, associated)[0]
            link.action = nil
            return link unless link.crud_type == :update

            # if action is edit and is not authorized, fallback to an enabled read action
            actions -= %i[new edit]
            link = configure_column_link(link, record, associated, actions) if actions.present?
          end
          link
        end

        def _as_configure_column_link_action(link, associated, actions)
          if column_empty?(associated) # if association is empty, we only can link to create form
            if actions.include?(:new)
              link.action = 'new'
              link.crud_type = :create
              link.label ||= :create_new
            end
          elsif actions.include?(:edit)
            link.action = 'edit'
            link.crud_type = :update
          elsif actions.include?(:show)
            link.action = 'show'
            link.crud_type = :read
          elsif actions.include?(:list)
            link.action = 'index'
            link.crud_type = :read
          end
        end
        private :_as_configure_column_link_action

        def column_link_authorized?(link, column, record, associated = nil)
          # Only automatic links on association columns validate associated data.
          if column.association && link.column == column
            associated ||= record.send(column.association.name) unless column.association.collection?
            associated_for_authorized =
              if column.association.collection? || associated.nil?
                column.association.klass
              else
                associated
              end
            authorized, reason = associated_for_authorized.authorized_for?(crud_type: link.crud_type, reason: true)
            if link.crud_type == :create && authorized
              authorized, reason = record.authorized_for?(crud_type: :update, column: column.name, reason: true)
            end
            [authorized, reason]
          else
            action_link_authorized?(link, record)
          end
        end
      end
    end
  end
end
