# frozen_string_literal: true

module ActiveScaffold
  module Finder
    module Collection
      protected

      def active_scaffold_conditions
        @active_scaffold_conditions ||= []
      end

      def active_scaffold_relations
        @active_scaffold_relations ||= []
      end

      def active_scaffold_preload
        @active_scaffold_preload ||= []
      end

      def active_scaffold_joins
        @active_scaffold_joins ||= []
      end

      def active_scaffold_outer_joins
        @active_scaffold_outer_joins ||= []
      end

      def active_scaffold_references
        @active_scaffold_references ||= []
      end

      # Override this method on your controller to define conditions used when querying a recordset (e.g. for List).
      # The return of this method should be any format compatible with the :conditions clause of ActiveRecord::Base's
      # find.
      def conditions_for_collection; end

      # Override this method on your controller to define joins to be used when querying a recordset (e.g. for List).
      # The return of this method should be any format compatible with the :joins clause of ActiveRecord::Base's find.
      def joins_for_collection; end

      # Override this method on your controller to provide custom finder options to the find() call. The return of this
      # method should be a hash.
      def custom_finder_options
        {}
      end

      def active_scaffold_embedded_conditions
        params_hash active_scaffold_embedded_params[:conditions]
      end

      def all_conditions(id_condition: true)
        [
          (self.id_condition if id_condition),          # for list with id (e.g. /users/:id/index)
          active_scaffold_conditions,                   # from the search modules
          conditions_for_collection,                    # from the dev
          conditions_from_params,                       # from the parameters (e.g. /users/list?first_name=Fred)
          conditions_from_constraints,                  # from any constraints (embedded scaffolds)
          active_scaffold_embedded_conditions           # embedding conditions (weaker constraints)
        ].compact_blank
      end

      def id_condition
        {active_scaffold_config.primary_key => params[:id]} if params[:id]
      end

      # valid options may include:
      # * :sorting - a Sorting DataStructure (basically an array of hashes of field => direction,
      #     e.g. [{field1: 'asc'}, {field2: 'desc'}]).
      #     please note that multi-column sorting has some limitations: if any column in a multi-field
      #     sort uses method-based sorting, it will be ignored. method sorting only works for single-column sorting.
      # * :per_page
      # * :page
      def finder_options(options = {})
        search_conditions = all_conditions

        sorting = options[:sorting]&.clause
        # create a general-use options array that's compatible with Rails finders
        finder_options = {
          reorder: sorting,
          conditions: search_conditions
        }
        if active_scaffold_config.mongoid?
          finder_options[:includes] =
            [active_scaffold_references, active_scaffold_preload].compact.flatten.uniq.presence
        else
          finder_options.merge!(
            joins:      joins_for_finder,
            left_joins: active_scaffold_outer_joins,
            preload:    active_scaffold_preload,
            includes:   active_scaffold_references.presence,
            references: active_scaffold_references.presence,
            relations:  active_scaffold_relations.presence,
            select:     options[:select]
          )
        end

        finder_options.merge! custom_finder_options
        finder_options
      end
    end
  end
end
