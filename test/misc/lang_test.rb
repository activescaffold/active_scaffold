# frozen_string_literal: true

require 'test_helper'

class LocalizationTest < ActiveSupport::TestCase
  def test_localization
    assert_equal 'Dutch', as_(:dutch)
    assert_equal 'dutch', as_('dutch')
    I18n.backend.store_translations :en, active_scaffold: {create_model: 'Create %<model>s'}
    assert_equal 'Create Test', as_(:create_model, model: 'Test')
  end

  def test_plain_translation_is_not_html_safe
    I18n.backend.store_translations :en, active_scaffold: {plain_markup: '<strong>Plain</strong>'}

    translation = as_(:plain_markup)

    assert_equal '<strong>Plain</strong>', translation
    assert_not_predicate translation, :html_safe?
  end

  def test_html_translation_is_html_safe
    I18n.backend.store_translations :en, active_scaffold: {
      greeting: {html: '<strong>Hello, %<name>s</strong>'}
    }

    translation = as_(:greeting, name: 'Test')

    assert_equal '<strong>Hello, Test</strong>', translation
    assert_predicate translation, :html_safe?
  end

  def test_html_translation_escapes_interpolation
    I18n.backend.store_translations :en, active_scaffold: {
      escaped_greeting: {html: '<strong>Hello, %<name>s</strong>'}
    }

    translation = as_(:escaped_greeting, name: '<em>Test</em>')

    assert_equal '<strong>Hello, &lt;em&gt;Test&lt;/em&gt;</strong>', translation
    assert_predicate translation, :html_safe?
  end

  def test_html_translation_preserves_html_safe_interpolation
    I18n.backend.store_translations :en, active_scaffold: {
      safe_greeting: {html: '<strong>Hello, %<name>s</strong>'}
    }

    translation = as_(:safe_greeting, name: '<em>Test</em>'.html_safe)

    assert_equal '<strong>Hello, <em>Test</em></strong>', translation
    assert_predicate translation, :html_safe?
  end

  def test_html_translation_uses_custom_scope
    I18n.backend.store_translations :en, active_scaffold: {
      messages: {greeting: {html: '<strong>Hello</strong>'}}
    }

    translation = as_(:greeting, scope: :messages)

    assert_equal '<strong>Hello</strong>', translation
    assert_predicate translation, :html_safe?
  end

  def test_default_translation_is_not_html_safe
    translation = as_(:missing_plain_translation)

    assert_equal 'Missing Plain Translation', translation
    assert_not_predicate translation, :html_safe?
  end

  def test_custom_default_is_not_html_safe
    translation = as_(:missing_custom_default, default: '<strong>Default</strong>')

    assert_equal '<strong>Default</strong>', translation
    assert_not_predicate translation, :html_safe?
  end
end
