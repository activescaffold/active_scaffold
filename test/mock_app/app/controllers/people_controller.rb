# frozen_string_literal: true

class PeopleController < ApplicationController
  before_action :configure_request

  active_scaffold do |conf|
    conf.columns.exclude :files
    conf.columns[:buildings].includes = nil
    conf.columns[:buildings].associated_limit = 0
    conf.columns[:roles].includes = nil
    conf.columns[:roles].associated_limit = 0
    conf.create.columns.exclude :address, :home
    conf.action_links.add 'archive', label: 'Archive', type: :member, method: :post, position: :after
    conf.action_links.add 'activate', label: 'Activate', type: :member, method: :post, position: false
    conf.action_links.add 'index', label: 'Back to list', type: :member, position: false, parameters: {id: nil},
                                    security_method: :nested_index_authorized?
  end

  def forbidden
    raise ActiveScaffold::ActionNotAllowed, 'forbidden by integration test'
  end

  def refresh_row
    @record = find_if_allowed(params[:id], :read)
    render 'update_row'
  end

  def archive
    process_action_link_action do |record|
      next unless params[:force_action_failure]

      record.errors.add(:base, 'The custom action failed')
      self.successful = false
    end
  end

  def activate
    process_action_link_action do |record|
      if params[:force_action_failure]
        record.errors.add(:base, 'The activation failed')
        self.successful = false
      else
        record.update!(adult: true)
      end
    end
  end

  protected

  def nested_index_authorized?(_record = nil)
    true
  end

  def configure_request
    active_scaffold_config.list.refresh_with_header = true if params[:refresh_with_header]
    active_scaffold_config.list.always_show_create = true if params[:always_show_create]
    if params[:nested_links]
      active_scaffold_config.update.nested_links = true
      active_scaffold_config.update.columns = %i[first_name last_name]
    end

    if params[:vertical_subform]
      active_scaffold_config.update.columns = %i[first_name buildings]
      active_scaffold_config.columns.override(:buildings) do |column|
        column.options = column.options.merge(layout: :vertical)
      end
    end

    if params[:multiple_form]
      columns = active_scaffold_config.create.override_columns
      columns.layout = :multiple
      columns[0] = %i[first_name last_name]
      columns[1] = %i[adult roles]
    end

    return unless params[:update_columns] || params[:nested_update_columns] || params[:hash_update_columns]

    active_scaffold_config.columns.override(:first_name) do |column|
      if params[:hash_update_columns]
        column.update_columns = [{contacts: [:last_name]}]
        column.send_form_on_update_column = true
      elsif params[:nested_update_columns]
        column.update_columns = [{__root__: [:last_name]}]
        column.send_form_on_update_column = true
      else
        column.update_columns = [:last_name]
      end
    end
  end

  def do_destroy(record)
    return super unless params[:force_destroy_failure]

    record.errors.add(:base, 'The forced destroy failed')
    self.successful = false
  end

  def beginning_of_chain
    scope = super
    scope = scope.where(first_name: params[:visible_first_name]) if params[:visible_first_name]
    scope
  end

  def do_add_existing
    return super unless params[:force_add_existing_failure]

    @record = active_scaffold_config.model.find(params.expect(:associated_id))
    @record.errors.add(:base, 'The custom add existing action failed')
    self.successful = false
  end
end
