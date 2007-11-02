module ActiveScaffold::DataStructures
  class Column
    attr_accessor :file_column_display
  end
end

module ActiveScaffold::Config
  class Core < Base
    attr_accessor :file_column_fields
    def initialize_with_file_column(model_id)
      @file_column_fields||=[]
      
      initialize_without_file_column(model_id)
      
      @file_column_fields = DeleteFileColumn.file_column_fields(self.model) # self.model.file_column_fields
      # check to see if file column was used on the model
      return if @file_column_fields.empty?
      
      # include the "delete" helpers for use with active scaffold, unless they are already included
      DeleteFileColumn.generate_delete_helpers(self.model)
      
      # do we have some file columns?  If so, switch on multipart
      for config_action in [self.update, self.create]
        config_action.multipart = true
      end
      
      # automatically set the form_ui to a file column, and tell active scaffold not to use null's implicitly (this makes things easier if the user is overriding columns)
      @file_column_fields.each{|field|
        begin
          self.columns[field].form_ui = :file_column
          # these 2 parameters are necessary helper attributes for the file column that must be allowed to be set to the model by active scaffold.
          self.columns[field].params.add "#{field}_temp", "delete_#{field}"
          # set null to false so active_scaffold wont set it to null
          # This is a bit hackish
          self.model.columns_hash[field.to_s].instance_variable_set("@null", false)
        rescue
        end
      }
    end
    
    alias_method_chain :initialize, :file_column unless self.instance_methods.include?("initialize_without_file_column")
    
  end
end

module ActiveScaffold
  module Helpers
    # Helpers that assist with the rendering of a List Column
    module ListColumns
      def get_column_value_with_file_column(record, column)
        if column_override?(column) || !active_scaffold_config.file_column_fields.include?(column.name.to_sym)
          return get_column_value_without_file_column(record, column)
        end
        
        value = record.send(column.name)
        
        unless column.file_column_display
          begin
            options = record.send("#{column.name}_options")
            versions = options[:magick][:versions]
            raise unless versions.stringify_keys["thumb"]
            column.file_column_display = :image
          rescue
            column.file_column_display = :link
          end
        end
                
        return "&nbsp;" if value.nil?
        
        link_to( (column.file_column_display==:link) ? File.basename(value) : image_tag(url_for_file_column(record, column.name.to_s, "thumb"), :border => 0), 
          url_for_file_column(record, column.name.to_s), 
          :popup => true)
      end
      
      alias_method_chain :get_column_value, :file_column unless self.instance_methods.include?("get_column_value_without_file_column")
    end
  end
end


module ActiveScaffold
  module Helpers
    # Helpers that assist with the rendering of a Form Column
    module FormColumns
      def active_scaffold_input_file_column(column, options)
        if @record.send(column.name) 
          # we already have a value?  display the form for deletion.
          output = 
            content_tag(
              :div, 
              content_tag(
                :div, 
                get_column_value(@record, column) + " " +
                hidden_field(:record, "delete_#{column.name}", :value => "false") +
                link_to_function("Remove file", "$(this).previous().value='true'; p=$(this).up(); p.hide(); p.next().show();"),
                {}
              ) +
              content_tag(
                :div,
                file_column_field("record", column.name, options),
                :style => "display: none"
              ),
              {}
            )
          
        else
          # no, 
          file_column_field("record", column.name, options)
        end
      end      
    end
  end
end