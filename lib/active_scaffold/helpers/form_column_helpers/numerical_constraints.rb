# frozen_string_literal: true

module ActiveScaffold
  module Helpers
    module FormColumnHelpers
      module NumericalConstraints
        # Try to get numerical constraints from model's validators
        def column_numerical_constraints(column, options)
          validators = _as_numerical_validators_for(column)
          equal_validator = validators.find { |v| v.options[:equal_to] }
          # If there is equal_to constraint - use it (unless otherwise specified by user)
          if equal_validator && !(options[:min] || options[:max])
            equal_to = equal_validator.options[:equal_to]
            return {min: equal_to, max: equal_to}
          end

          only_integer = _as_integer_constraints?(column, validators)
          margin = only_integer ? 1 : 0
          numerical_constraints = _as_numerical_constraint_bounds(validators, options, margin)
          unless options[:step]
            _as_add_numerical_step_constraint(numerical_constraints, column, validators, options, only_integer)
          end
          numerical_constraints
        end

        def _as_numerical_validators_for(column)
          column.active_record_class.validators.select do |validator|
            validator.is_a?(ActiveModel::Validations::NumericalityValidator) &&
              validator.attributes.include?(column.name) && !validator.options[:if] && !validator.options[:unless]
          end
        end

        def _as_integer_constraints?(column, validators)
          (column.column && column.column_type == :integer) || validators.any? do |validator|
            validator.options[:only_integer]
          end
        end

        def _as_numerical_constraint_bounds(validators, options, margin)
          constraints = {}
          unless options[:min]
            minimum = validators.filter_map { |validator| validator.options[:greater_than_or_equal_to] }.max
            greater_than = validators.filter_map { |validator| validator.options[:greater_than] }.max
            constraints[:min] = [minimum, (greater_than + margin if greater_than)].compact.max
          end
          unless options[:max]
            maximum = validators.filter_map { |validator| validator.options[:less_than_or_equal_to] }.min
            less_than = validators.filter_map { |validator| validator.options[:less_than] }.min
            constraints[:max] = [maximum, (less_than - margin if less_than)].compact.min
          end
          constraints
        end

        def _as_add_numerical_step_constraint(constraints, column, validators, options, only_integer)
          only_odd_valid = validators.any? { |validator| validator.options[:odd] }
          only_even_valid = validators.any? { |validator| validator.options[:even] } unless only_odd_valid
          if only_integer
            _as_add_integer_step_constraint(constraints, options, only_odd_valid, only_even_valid)
          else
            constraints[:step] ||= "0.#{'0' * (column.column.scale - 1)}1" if column.column&.scale.to_i.positive?
            constraints[:step] ||= 'any'
          end
        end

        def _as_add_integer_step_constraint(constraints, options, only_odd_valid, only_even_valid)
          return unless options[:min].respond_to?(:even?) && (only_odd_valid || only_even_valid)

          constraints[:step] = 2
          constraints[:min] += 1 if only_odd_valid && options[:min].even?
          constraints[:min] += 1 if only_even_valid && options[:min].odd?
        end
        private :_as_numerical_validators_for, :_as_integer_constraints?, :_as_numerical_constraint_bounds,
                :_as_add_numerical_step_constraint, :_as_add_integer_step_constraint

        def numerical_constraints_for_column(column, options)
          constraints = Rails.cache.fetch("#{column.cache_key}#numerical_constraints") do
            column_numerical_constraints(column, options)
          end
          constraints.merge(options)
        end
      end
    end
  end
end
