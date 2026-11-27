# frozen_string_literal: true

module NestedRoutes
  class CarsController < ApplicationController
    before_action :configure_url_cache

    active_scaffold :car do |conf|
      conf.columns = [:model]
    end

    protected

    def configure_url_cache
      active_scaffold_config.user.cache_action_link_urls = params[:cache_urls] != 'false'
    end
  end
end
