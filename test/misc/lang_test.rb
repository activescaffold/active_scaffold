# frozen_string_literal: true

require 'test_helper'

class LocalizationTest < ActiveSupport::TestCase
  def test_localization
    assert_equal 'Dutch', as_(:dutch)
    assert_equal 'dutch', as_('dutch')
    I18n.backend.store_translations :en, active_scaffold: {create_model: 'Create %<model>s'}
    assert_equal 'Create Test', as_(:create_model, model: 'Test')
  end

  def test_plain_translation_remains_html_safe
    I18n.backend.store_translations :en, active_scaffold: {plain_text: 'Plain'}

    assert_predicate as_(:plain_text), :html_safe?
  end

  def test_html_translation_is_html_safe
    I18n.backend.store_translations :en, active_scaffold: {
      greeting: {html: '<strong>Hello, %<name>s</strong>'}
    }

    translation = as_(:greeting, name: 'Test')

    assert_equal '<strong>Hello, Test</strong>', translation
    assert_predicate translation, :html_safe?
  end

  def test_html_in_plain_translation_warns_only_once
    I18n.backend.store_translations :en, active_scaffold: {legacy_markup: '<strong>Legacy</strong>'}
    warning = 'HTML in translation active_scaffold.legacy_markup is deprecated. ' \
              'Move it to active_scaffold.legacy_markup.html. ' \
              'Ordinary translations will no longer be marked HTML-safe in ActiveScaffold 4.5.'
    ActiveScaffold.deprecator.expects(:warn).with(warning).once

    2.times { assert_predicate as_(:legacy_markup), :html_safe? }
  end

  def test_html_warning_is_once_per_key_and_scope_pair
    I18n.backend.store_translations :en, active_scaffold: {
      first_scope: {legacy_markup_by_scope: '<strong>First</strong>'},
      second_scope: {legacy_markup_by_scope: '<strong>Second</strong>'}
    }
    ActiveScaffold.deprecator.expects(:warn).twice

    2.times { as_(:legacy_markup_by_scope, scope: :first_scope) }
    2.times { as_(:legacy_markup_by_scope, scope: :second_scope) }
  end

  def test_plain_translation_without_html_does_not_warn
    I18n.backend.store_translations :en, active_scaffold: {unmarked_plain_text: 'Plain'}
    ActiveScaffold.deprecator.expects(:warn).never

    as_(:unmarked_plain_text)
  end

  def test_html_detection_is_checked_only_once_per_key_and_scope_pair
    translation = mock
    translation.expects(:match?).once.returns(false)

    2.times do
      ActiveScaffold::TranslationHtmlSafety.check_once(:checked_once, [:active_scaffold], translation)
    end
  end
end
