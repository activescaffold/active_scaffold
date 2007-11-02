module DeleteFileColumn
  
  def self.included(klass)
    file_column_fields(klass).each { |field|
      klass.send :class_eval, <<-EOF, __FILE__, __LINE__ + 1  unless klass.methods.include?("#{field}_with_delete=")
        attr_reader :delete_#{field}
        
        def delete_#{field}=(value)
          value = (value=="true") if String===value
          return unless value
          
          # passing nil to the file column causes the file to be deleted.  Don't delete if we just uploaded a file!
          self.#{field} = nil unless self.#{field}_just_uploaded?
        end
      EOF
    }
  end
  
  def self.file_column_fields(klass)
    klass.instance_methods.grep(/_just_uploaded\?$/).collect{|m| m[0..-16].to_sym }
  end
  
  def self.generate_delete_helpers(klass)
     klass.send :include, DeleteFileColumn unless klass.included_modules.include?(DeleteFileColumn)
  end
  # hackish but it works
  def file_column_fields
    DeleteFileColumn.file_column_fields(self.class)
  end
end