require File.join(File.dirname(__FILE__), '../test_helper.rb')

class Config::ListTest < Test::Unit::TestCase
  def setup
    @config = ActiveScaffold::Config::Core.new :model_stub
  end

  def test_label
    I18n.backend.store_translations :en, :active_scaffold => {:resource => {:one => 'Resource', :other => 'Resources'}}
    @config.list.label = :resource
    assert_equal 'Resources', @config.list.label
    label = 'monkeys'
    @config.list.label = label
    assert_equal label, @config.list.label
  end

  def test_default_options
    assert_equal 15, @config.list.per_page
    assert_equal 2, @config.list.page_links_window
    assert_equal '-', @config.list.empty_field_text
    assert_equal ', ', @config.list.association_join_text
    assert_equal true, @config.list.pagination
    assert_equal 'search', @config.list.search_partial
    assert_equal :no_entries, @config.list.no_entries_message
    assert_equal :filtered, @config.list.filtered_message
    assert !@config.list.always_show_create
    assert !@config.list.always_show_search
    assert !@config.list.mark_records
    assert @config.list.count_includes.nil?
    assert_equal 'ModelStubs', @config.list.label
    assert @config.list.sorting.sorts_on?(:id)
    assert_equal 'ASC', @config.list.sorting.direction_of(:id)
  end
  
  def test_empty_field_text
    @config.list.empty_field_text = '(missing)'
    assert_equal '(missing)', @config.list.empty_field_text
  end
  
  def test_association_join_text
    @config.list.association_join_text = '<br/>'
    assert_equal '<br/>', @config.list.association_join_text
  end
  
  def test_no_entries
    @config.list.no_entries_message = 'No items'
    assert_equal 'No items', @config.list.no_entries_message
  end
  
  def test_filtered_message
    @config.list.filtered_message = 'filtered items'
    assert_equal 'filtered items', @config.list.filtered_message
  end
  
  def test_pagination
    @config.list.pagination = :infinite
    assert_equal :infinite, @config.list.pagination
    @config.list.pagination = false
    assert !@config.list.pagination
  end
  
  def test_sorting
    @config.list.sorting = {:a => :desc}
    assert @config.list.sorting.sorts_on?(:a)
    assert_equal 'DESC', @config.list.sorting.direction_of(:a)
    assert !@config.list.sorting.sorts_on?(:id)
    
    @config.list.sorting = [{:a => :asc}, {:b => :desc}]
    assert @config.list.sorting.sorts_on?(:a)
    assert_equal 'ASC', @config.list.sorting.direction_of(:a)
    assert @config.list.sorting.sorts_on?(:b)
    assert_equal 'DESC', @config.list.sorting.direction_of(:b)
    assert !@config.list.sorting.sorts_on?(:id)
  end
  
  def test_mark_records
    @config.list.mark_records = true
    assert @config.list.mark_records
  end
  
  def test_per_page
    per_page = 35
    @config.list.per_page = per_page
    assert_equal per_page, @config.list.per_page
  end
  
  def test_page_links_window
    page_links_window = 3
    @config.list.page_links_window = page_links_window
    assert_equal page_links_window, @config.list.page_links_window
  end
  
  def test_always_show_create
    always_show_create = true
    @config.list.always_show_create = always_show_create
    assert_equal always_show_create, @config.list.always_show_create
  end
  
  def test_always_show_create_when_create_is_not_enabled
    always_show_create = true
    @config.list.always_show_create = always_show_create
    @config.actions.exclude :create
    assert_equal false, @config.list.always_show_create
  end
  
  def test_always_show_search
    @config.list.always_show_search = true
    assert @config.list.always_show_search
    assert_equal 'search', @config.list.search_partial
  end
  
  def test_always_show_search_when_search_is_not_enabled
    @config.list.always_show_search = true
    @config.actions.exclude :search
    assert_equal false, @config.list.always_show_search
  end
  
  def test_always_show_search_when_field_search
    @config.list.always_show_search = true
    @config.actions.swap :search, :field_search
    assert @config.list.always_show_search
    assert_equal 'field_search', @config.list.search_partial
  end
  
  def test_count_includes
    @config.list.count_includes = [:assoc_1, :assoc_2]
    assert_equal [:assoc_1, :assoc_2], @config.list.count_includes
  end
end
