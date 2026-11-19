# frozen_string_literal: true

class IntegrationPeopleController < ApplicationController
  active_scaffold :person do |conf|
    conf.actions << :field_search
    conf.field_search.columns = %i[first_name last_name]
    conf.field_search.human_conditions = true

    conf.show.columns = %i[first_name last_name car contacts buildings]
    conf.columns[:car].show_ui = :horizontal
    conf.columns[:contacts].show_ui = [:horizontal, {subform_columns: %i[first_name last_name]}]
    conf.columns[:buildings].show_ui = [:vertical, {subform_columns: %i[name floors_count]}]

    conf.create.columns = %i[first_name last_name adult roles]
    conf.update.columns = %i[first_name last_name adult roles]
    conf.columns[:adult].form_ui = [:radio, {options: [['Adult', true], ['Minor', false]]}]
    conf.columns[:roles].form_ui = :checkboxes

    conf.list.filter_human_message = true
    conf.list.filters.add(:age) do |filter|
      filter.label = 'Age'
      filter.add :all, label: 'All ages', conditions: {}
      filter.add :adults, label: 'Adults', conditions: {adult: true}
      filter.add :minors, label: 'Minors', conditions: {adult: false}
    end
  end

  helper_method :person_first_name_show_column

  def person_first_name_show_column(record, _column)
    "Profile: #{record.first_name}"
  end
end
