# frozen_string_literal: true

namespace :active_scaffold do
  namespace :assets do
    desc 'Generate jQuery UI theme css from jquery-ui-rails (if using the gem), and deps.css for Propshaft compatibility'
    task generate: :environment do
      if ActiveScaffold::Assets::JqueryUiThemeGenerator.generate!
        puts '✅ jQuery UI theme generated'
      else
        puts '✅ No need to generate jQuery UI theme'
      end
      if ActiveScaffold::Assets::CssDepsGenerator.generate!
        puts '✅ Deps.css generated'
      else
        puts '⚠️ Deps.css not generated'
      end
    end

    desc 'Force regenerate jQuery UI theme css from jquery-ui-rails (if using the gem) and deps.css'
    task force_generate: :environment do
      if ActiveScaffold::Assets::JqueryUiThemeGenerator.generate!(force: true)
        puts '✅ jQuery UI theme regenerated'
      else
        puts '⚠️ jQuery UI theme not generated'
      end
      if ActiveScaffold::Assets::CssDepsGenerator.generate!
        puts '✅ Deps.css regenerated'
      else
        puts '⚠️ Deps.css not generated'
      end
    end

    desc 'Check if jQuery UI theme needs regeneration'
    task check: :environment do
      if ActiveScaffold::Assets::JqueryUiThemeGenerator.needs_generation?
        puts '⚠️  jQuery UI theme needs regeneration. Run: rake active_scaffold:assets:generate'
      else
        puts '✅ jQuery UI theme is up to date'
      end
    end
  end
end
