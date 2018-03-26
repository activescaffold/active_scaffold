# require 'rails/generators/rails/scaffold_controller/scaffold_controller_generator'

module ActiveScaffold
  module Generators
    class ControllerGenerator < Rails::Generators::NamedBase
      include Rails::Generators::ResourceHelpers

      source_root File.expand_path('../templates', __dir__)

      check_class_collision :suffix => 'Controller'

      class_option :orm, :banner => 'NAME', :type => :string, :required => true,
                         :desc => 'ORM to generate the controller for'

      desc <<-DESC.strip_heredoc
      Description:
          Stubs out a active_scaffolded controller. Pass the model name,
          either CamelCased or under_scored.
          The controller name is retrieved as a pluralized version of the model
          name.

          To create a controller within a module, specify the model name as a
          path like 'parent_module/controller_name'.

          This generates a controller class in app/controllers and invokes helper,
          template engine and test framework generators.

      Example:
          `rails generate active_scaffold:controller CreditCard`

          Credit card controller with URLs like /credit_card/debit.
              Controller:      app/controllers/credit_cards_controller.rb
              Functional Test: test/functional/credit_cards_controller_test.rb
              Helper:          app/helpers/credit_cards_helper.rb
      DESC

      def create_controller_files
        template 'controller.rb', File.join('app/controllers', class_path, "#{controller_file_name}_controller.rb")
        template 'helper.rb', File.join('app/helpers', class_path, "#{controller_file_name}_helper.rb")
      end

      hook_for :test_framework, :as => :scaffold

      def create_view_root_folder
        empty_directory File.join('app/views', controller_file_path)
      end
    end
  end
end
