# frozen_string_literal: true

module ActiveScaffold
  module Bridges
    class Paperclip
      module PaperclipBridgeHelpers
        mattr_accessor :thumbnail_style
        self.thumbnail_style = :thumbnail

        def self.generate_delete_helper(klass, field)
          klass.class_eval <<-CODE, __FILE__, __LINE__ + 1 unless klass.method_defined?(:"delete_#{field}=")
            attr_reader :delete_#{field}                                   # attr_reader :delete_file
                                                                           #
            def delete_#{field}=(value)                                    # def delete_file=(value)
              value = (value == "true") if String === value                #   value = (value == "true") if String === value
              return unless value                                          #   return unless value
                                                                           #
              # passing nil to the file column causes the file             #   # passing nil to the file column causes the file
              # to be deleted. Don't delete if we just uploaded a file!    #   # to be deleted. Don't delete if we just uploaded a file!
              self.#{field} = nil unless self.#{field}.dirty?              #   self.file = nil unless self.file.dirty?
            end                                                            # end
          CODE
        end
      end
    end
  end
end
