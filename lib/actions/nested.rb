module ActiveScaffold::Actions
  module Nested

    def self.included(base)
      super
      base.active_scaffold_config.list.columns.each do |column|
        column.set_link('nested', :parameters => {:associations => column.name.to_sym}) if column.association and column.link.nil? and [:has_many].include?(column.association.macro)
      end
    end

    def nested
      insulate { do_nested }

      respond_to do |type|
        type.html { render :partial => 'nested', :layout => true }
        type.js { render :partial => 'nested', :layout => false }
      end
    end

    protected

    def do_nested
      @record = find_if_allowed(params[:id], 'nested')
    end

  end
end