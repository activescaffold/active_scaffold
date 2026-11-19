# frozen_string_literal: true

require 'active_scaffold/test_support/assert_embedded_load'

if ActiveScaffold::Testing.autoload?(:AssertEmbeddedLoad) ||
   !ActiveScaffold::Testing.const_defined?(:AssertEmbeddedLoad, false)
  ActiveScaffold::Testing.const_set(
    :AssertEmbeddedLoad,
    ActiveScaffold::TestSupport::AssertEmbeddedLoad
  )
end

message = 'active_scaffold/testing/assert_embedded_load is deprecated; ' \
          'require active_scaffold/test_support/assert_embedded_load instead.'

if ActiveScaffold.respond_to?(:deprecator)
  ActiveScaffold.deprecator.warn(message)
else
  warn "DEPRECATION WARNING: #{message}"
end
