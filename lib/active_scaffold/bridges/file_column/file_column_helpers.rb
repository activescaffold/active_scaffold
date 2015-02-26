module ActiveScaffold
  module Bridges
    class FileColumn
      module FileColumnHelpers
        class << self
          def file_column_fields(klass)
            klass.instance_methods.select { |m| m.to_s =~ /_just_uploaded\?$/ }.collect { |m| m[0..-16].to_sym }
          end

          def generate_delete_helpers(klass)
            file_column_fields(klass).each do |field|
              klass.send :class_eval, <<-EOF, __FILE__, __LINE__ + 1  unless klass.method_defined?(:"#{field}_with_delete=")
                attr_reader :delete_#{field}

                def delete_#{field}=(value)
                  value = (value=="true") if String===value
                  return unless value

                  # passing nil to the file column causes the file to be deleted.  Don't delete if we just uploaded a file!
                  self.#{field} = nil unless self.#{field}_just_uploaded?
                end
              EOF
            end
          end

          def klass_has_file_column_fields?(klass)
            true unless file_column_fields(klass).empty?
          end
        end

        def file_column_fields
          @file_column_fields ||= FileColumnHelpers.file_column_fields(self)
        end

        def options_for_file_column_field(field)
          allocate.send("#{field}_options")
        end

        def field_has_image_version?(field, version = 'thumb')
          options = options_for_file_column_field(field)
          versions = options[:magick][:versions]
          raise unless versions.stringify_keys[version]
          true
        rescue
          false
        end

        def generate_delete_helpers
          FileColumnHelpers.generate_delete_helpers(self)
        end
      end
    end
  end
end
