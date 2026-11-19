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

  protected

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

    return unless params[:update_columns] || params[:nested_update_columns]

    active_scaffold_config.columns.override(:first_name) do |column|
      if params[:nested_update_columns]
        column.update_columns = [{__root__: [:last_name]}]
        column.send_form_on_update_column = true
      else
        column.update_columns = [:last_name]
      end
    end
  end

  def do_add_existing
    return super unless params[:force_add_existing_failure]

    @record = active_scaffold_config.model.find(params.expect(:associated_id))
    @record.errors.add(:base, 'The custom add existing action failed')
    self.successful = false
  end
end
