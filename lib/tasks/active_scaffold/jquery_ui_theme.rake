namespace :active_scaffold do
  namespace :jquery_ui do
    desc "Generate jQuery UI theme.css from jquery-ui-rails for Propshaft compatibility"
    task generate_theme: :environment do
      if ActiveScaffold::JqueryUiThemeGenerator.generate!
        puts "✅ jQuery UI theme generated"
      else
        puts "✅ jQuery UI theme is already up to date"
      end
    end

    desc "Force regenerate jQuery UI theme"
    task force_generate_theme: :environment do
      if ActiveScaffold::JqueryUiThemeGenerator.generate!(true)
        puts "✅ jQuery UI theme regenerated"
      else
        puts "✅ jQuery UI theme generated"
      end
    end

    desc "Check if theme needs regeneration"
    task check: :environment do
      if ActiveScaffold::JqueryUiThemeGenerator.needs_generation?
        puts "⚠️  Theme needs regeneration. Run: rake active_scaffold:jquery_ui:generate_theme"
      else
        puts "✅ Theme is up to date"
      end
    end
  end
end