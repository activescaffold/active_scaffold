# frozen_string_literal: true

module ActiveScaffold
  module Bridges
    class Paperclip
      module PaperclipBridgeHelpers
        mattr_accessor :thumbnail_style
        self.thumbnail_style = :thumbnail

        def self.generate_delete_helper(klass, field)
          return if klass.method_defined?(:"delete_#{field}=")

          klass.attr_reader :"delete_#{field}"
          klass.define_method "delete_#{field}=" do |value|
            value = (value == "true") if String === value
            return unless value

            # passing nil to the file column causes the file to be deleted.  Don't delete if we just uploaded a file!
            self.send("#{field}=", nil) unless self.send(field).dirty?
          end
        end
      end
    end
  end
end
