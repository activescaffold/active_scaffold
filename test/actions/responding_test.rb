# frozen_string_literal: true

require 'test_helper'

class RespondingActionTest < ActionController::TestCase
  tests PeopleController

  test 'treats a wildcard Accept header as HTML only' do
    @request.set_header 'HTTP_ACCEPT', '*/*'

    assert @controller.send(:accepts?, :html)
    assert_not @controller.send(:accepts?, :json)
  end

  test 'matches an explicitly accepted API format' do
    @request.set_header 'HTTP_ACCEPT', 'application/json'

    assert @controller.send(:accepts?, :json)
    assert_not @controller.send(:accepts?, :xml)
  end

  test 'uses action success and action name to select an API status' do
    @controller.stubs(:action_name).returns('create')
    assert_equal 201, @controller.send(:response_status)

    @controller.send(:successful=, false)
    assert_equal 422, @controller.send(:response_status)

    @controller.send(:successful=, true)
    @controller.stubs(:action_name).returns('update')
    assert_equal 200, @controller.send(:response_status)
  end

  test 'builds conditional GET arguments from records and XHR state' do
    record = Person.create!(first_name: 'Alice')
    @controller.instance_variable_set(:@record, record)
    @request.set_header 'HTTP_X_REQUESTED_WITH', 'XMLHttpRequest'
    @controller.expects(:stale?).with do |options|
      options[:etag] == [record, 'xhr'] && options[:last_modified] == record.updated_at
    end.returns(true)

    assert @controller.send(:view_stale?)
  end

  test 'selects the iframe responder when it exists' do
    @controller.params = ActionController::Parameters.new(iframe: 'true')

    assert_equal 'action_update_respond_on_iframe',
                 @controller.send(:respond_method_for, :action_update, :html)
    assert_equal 'action_update_respond_to_json',
                 @controller.send(:respond_method_for, :action_update, :json)
  end

  test 'serializes an XML collection with a model-derived root' do
    response = ActiveScaffold::Actions::Core::Responding::AuthorizedApiResponse.new(
      [Person.new(first_name: 'Alice')],
      [:first_name],
      @controller.active_scaffold_config
    )

    xml = response.to_xml

    assert_includes xml, '<people type="array">'
    assert_includes xml, '<first-name>Alice</first-name>'
  end
end
