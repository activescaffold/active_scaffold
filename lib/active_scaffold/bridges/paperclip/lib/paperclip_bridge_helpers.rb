module ActiveScaffold
  module Bridges
    module Paperclip
      module Lib
        module PaperclipBridgeHelpers
          mattr_accessor :thumbnail_style
          self.thumbnail_style = :thumbnail
        
          def self.generate_delete_helper(klass, field)
            klass.class_eval <<-EOF, __FILE__, __LINE__ + 1 unless klass.methods.include?("delete_#{field}=")
              attr_reader :delete_#{field}
        
              def delete_#{field}=(value)
                value = (value == "true") if String === value
                return unless value
        
                # passing nil to the file column causes the file to be deleted. Don't delete if we just uploaded a file!
                self.#{field} = nil unless self.#{field}.dirty?
              end
            EOF
          end
        end
      end
    end
  end
end