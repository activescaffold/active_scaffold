# frozen_string_literal: true

# This file is loaded by the Rails engine
if defined?(Rails) && defined?(Propshaft) && Rails.application.config.assets.server
  # Hook into assets:precompile to generate theme before compilation
  Rake::Task['assets:precompile'].enhance do
    ActiveScaffold::Assets::JqueryUiThemeGenerator.generate!(force: true)
    ActiveScaffold::Assets::CssDepsGenerator.generate!
  end
end
