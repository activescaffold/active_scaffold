class ActiveSupport::TestCase
  def self.should_have_columns_in(action, *columns)
    should "have #{columns.to_sentence} columns in #{action}" do
      assert_equal columns, column_names(action)
    end
  end

  def self.should_include_columns_in(action, *columns)
    should "include #{columns.to_sentence} columns in #{action}" do
      action_columns = column_names(action)
      columns.each do |column|
        assert action_columns.include?(column.to_sym), "#{column} is not included in #{action}"
      end
    end
  end

  def self.should_not_include_columns_in(action, *columns)
    should "not include #{columns.to_sentence} columns in #{action}" do
      action_columns = column_names(action)
      columns.each do |column|
        assert !action_columns.include?(column.to_sym), "#{column} is included in #{action}"
      end
    end
  end

  def self.should_render_as_form_ui(column_name, form_ui)
    before_block = lambda do
      @rendered_columns = []
      @controller.view_context_class.any_instance.expects(:"active_scaffold_input_#{form_ui}").at_least_once.with do |column, _|
        @rendered_columns << column.name
        true
      end
    end
    should "render column #{column_name} as #{form_ui} form_ui", :before => before_block do
      assert_equal form_ui, @controller.active_scaffold_config.columns[column_name].form_ui
      assert @rendered_columns.include?(column_name)
    end
  end

  def self.should_render_with_options_for_select(column_name, *options)
    should "render column #{column_name} with options for select" do
      converting_sort = ->(a, b) { a.to_s <=> b.to_s }
      assert_equal options.sort(&converting_sort), @controller.active_scaffold_config.columns[column_name].options[:options].sort(&converting_sort)
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

  def self.should_render_as_form_hidden(column_name)
    before_block = lambda do
      @rendered_columns = []
      @controller.view_context_class.any_instance.expects(:"hidden_field").at_least_once.with do |_, method, _|
        @rendered_columns << method
        true
      end
    end
    should "render column #{column_name} as form hidden", :before => before_block do
      assert_template :partial => '_form_hidden_attribute'
      assert @rendered_columns.include?(column_name)
    end
  end

  def self.should_render_as_list_ui(column_name, list_ui)
    before_block = lambda do
      @rendered_columns = []
      @controller.view_context_class.any_instance.expects(:"active_scaffold_column_#{list_ui}").at_least_once.with do |column, _|
        @rendered_columns << column.name
        true
      end
    end
    should "render column #{column_name} as #{list_ui} list_ui", :before => before_block do
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
    before_block = lambda do
      @column = @controller.active_scaffold_config.columns[column_name]
      @rendered_columns = []
      method = @column.list_ui == :checkbox ? :format_column_checkbox : :active_scaffold_inplace_edit
      @controller.view_context_class.any_instance.expects(method).at_least_once.with do |_, column, _|
        @rendered_columns << column.name
        true
      end
    end
    should "render column #{column_name} as inplace edit", :before => before_block do
      assert @column.inplace_edit
      assert @rendered_columns.include?(column_name)
    end
  end

  def self.should_respond_to_parent_redirecting_to(description, &block)
    should_respond_to_parent("redirecting to #{description}") { "document.location.href = \"#{instance_eval(&block)}\"" }
  end

  def self.should_respond_to_parent(description = nil, &block)
    should "respond to parent #{description}" do
      script = block ? instance_eval(&block) : /.*/
      script = script.is_a?(Regexp) ? script.source : Regexp.quote(script)
      script = script.gsub('\n', '\\\\\\n')
               .gsub(/['"]/, '\\\\\\\\\&')
               .gsub('</script>', '</scr"+"ipt>')
      assert_select 'script[type=text/javascript]', Regexp.new('.*' + Regexp.quote("with(window.parent) { setTimeout(function() { window.eval('") + script + Regexp.quote("'); if (typeof(loc) !== 'undefined') loc.replace('about:blank'); }, 1) };") + '.*')
    end
  end

  private

  def column_names(action)
    columns = []
    @controller.active_scaffold_config.send(action).columns.each(:flatten => true) { |col| columns << col.name }
    columns
  end
end
