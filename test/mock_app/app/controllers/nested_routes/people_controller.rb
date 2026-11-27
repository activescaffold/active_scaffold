# frozen_string_literal: true

module NestedRoutes
  class PeopleController < ApplicationController
    before_action :configure_url_cache

    active_scaffold :person do |conf|
      conf.columns = %i[first_name buildings car]
      conf.list.filters.add(:status) do |filter|
        filter.add :all, conditions: {}
        filter.add :active, conditions: {}
      end
      conf.nested.add_link :buildings, label: 'Selected buildings', parameters: {
        status: 'first', occupancy: 'occupied', context: {source: 'parent link'}, tags: ['one', 'two & three']
      }
      conf.nested.add_link :buildings, label: 'Dynamic buildings', parameters: {source: 'dynamic'},
                                       dynamic_parameters: ->(person) do
                                         {status: person.first_name.start_with?('First') ? 'first' : 'all', occupancy: 'occupied'}
                                       end
    end

    protected

    def configure_url_cache
      active_scaffold_config.user.cache_action_link_urls = params[:cache_urls] != 'false'
    end
  end
end
