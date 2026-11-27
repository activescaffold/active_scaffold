# frozen_string_literal: true

module NestedRoutes
  class BuildingsController < ApplicationController
    before_action :configure_url_cache

    active_scaffold :building do |conf|
      conf.columns = [:name]
      conf.list.filters.add(:status) do |filter|
        filter.add :all, label: 'All statuses', conditions: {}
        filter.add :first, label: 'First building only', conditions: {name: 'First building'}
      end
      conf.list.filters.add(:occupancy) do |filter|
        filter.add :all, label: 'All occupancy', conditions: {}
        filter.add :occupied, label: 'Occupied only', conditions: {floors_count: 1}
      end
    end

    protected

    def configure_url_cache
      active_scaffold_config.user.cache_action_link_urls = params[:cache_urls] != 'false'
    end
  end
end
