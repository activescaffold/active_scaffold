class ActiveSupport::TestCase
  def self.should_have_columns_in(action, *columns)
    should "have columns in #{action}" do
      assert_equal columns, @controller.active_scaffold_config.send(action).columns.map(&:name)
    end
  end

  def self.should_include_columns_in(action, *columns)
    should "include columns in #{action}" do
      action_columns = @controller.active_scaffold_config.send(action).columns.map(&:name)
      columns.each do |column|
        assert action_columns.include?(column.to_sym), "#{column} is not included in #{action}"
      end
    end
  end

  def self.should_not_include_columns_in(action, *columns)
    should "not include columns in #{action}" do
      action_columns = @controller.active_scaffold_config.send(action).columns.map(&:name)
      columns.each do |column|
        assert !action_columns.include?(column.to_sym), "#{column} is included in #{action}"
      end
    end
  end

  def self.should_render_as_form_ui(column_name, form_ui)
    should "render column #{column_name} as #{form_ui} form_ui", :before => lambda{
      @rendered_columns = []
      ActionView::Base.any_instance.expects(:"active_scaffold_input_#{form_ui}").at_least_once.with {|column, options|
        @rendered_columns << column.name
        true
      }
    } do
      assert_equal form_ui, @controller.active_scaffold_config.columns[column_name].form_ui
      assert @rendered_columns.include?(column_name)
    end
  end

  def self.should_render_as_form_override(column_name)
    should "render column #{column_name} as form override" do
      column = @controller.active_scaffold_config.columns[column_name]
      assert @response.template.override_form_field?(column)
      assert_template :partial => "_#{column_name}_form_column", :count => 0
    end
  end

  def self.should_render_as_form_partial_override(column_name)
    should "render column #{column_name} as form partial override" do
      assert_template :partial => "_#{column_name}_form_column"
    end
  end

  def self.should_render_as_list_ui(column_name, list_ui)
    should "render column #{column_name} as #{list_ui} list_ui", :before => lambda{
      @rendered_columns = []
      ActionView::Base.any_instance.expects(:"active_scaffold_column_#{list_ui}").at_least_once.with {|column, options|
        @rendered_columns << column.name
        true
      }
    } do
      assert_equal list_ui, @controller.active_scaffold_config.columns[column_name].list_ui
      assert @rendered_columns.include?(column_name)
    end
  end

  def self.should_render_as_field_override(column_name)
    should "render column #{column_name} as field override" do
      column = @controller.active_scaffold_config.columns[column_name]
      assert @response.template.override_form_field?(column)
      assert_template :partial => "_#{column_name}_column", :count => 0
    end
  end

  def self.should_render_as_field_partial_override(column_name)
    should "render column #{column_name} as field partial override" do
      assert_template :partial => "_#{column_name}_column"
    end
  end

  def self.should_render_as_inplace_edit(column_name)
    should "render column #{column_name} as inplace edit", :before => lambda{
      @column = @controller.active_scaffold_config.columns[column_name]
      @rendered_columns = []
      method = @column.list_ui == :checkbox ? :format_column_checkbox : :active_scaffold_inplace_edit
      ActionView::Base.any_instance.expects(method).at_least_once.with {|model, column, options|
        @rendered_columns << column.name
        true
      }
    } do
      assert @column.inplace_edit
      assert @rendered_columns.include?(column_name)
    end
  end
end
