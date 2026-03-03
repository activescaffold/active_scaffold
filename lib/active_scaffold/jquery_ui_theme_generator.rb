module ActiveScaffold
  class JqueryUiThemeGenerator
    class << self
      def generate_if_needed
        return unless jquery_ui_installed?

        generator = new
        generator.generate_if_needed
      end

      def generate!(force = false)
        return unless jquery_ui_installed?

        generator = new
        generator.generate!(force)
      end

      def needs_generation?
        return false unless jquery_ui_installed?

        generator = new
        generator.needs_generation?
      end

      private

      def jquery_ui_installed?
        Gem.loaded_specs['jquery-ui-rails'].present?
      end
    end

    def initialize
      @jquery_ui_spec = Gem.loaded_specs['jquery-ui-rails']
      @source_path = File.join(@jquery_ui_spec.full_gem_path, 'app/assets/stylesheets/jquery-ui/theme.css.erb')
      @theme_path = Rails.root.join('app/assets/stylesheets/active_scaffold/jquery-ui/theme.css')
    end

    def generate_if_needed
      return unless source_exists?
      generate! if needs_generation?
    end

    def generate!(force = false)
      return unless source_exists?

      if force || needs_generation?
        Rails.logger.info "ActiveScaffold: Generating jQuery UI theme..."
        perform_generation
        true
      else
        false
      end
    end

    def needs_generation?
      return true unless File.exist?(@theme_path)
      return true if source_newer_than_generated?
      false
    end

    def source_exists?
      File.exist?(@source_path)
    end

    private

    def source_newer_than_generated?
      source_mtime = File.mtime(@source_path)
      theme_mtime = File.mtime(@theme_path)
      source_mtime > theme_mtime
    end

    def perform_generation
      # Read and process the ERB
      theme_content = File.read(@source_path)

      # Process asset_path calls
      processed = theme_content.gsub(/<%= image_path\(['"]([^'"]+)['"]\) %>/) do
        "'/assets/#{$1}'"
      end

      # Remove any other ERB tags
      processed.gsub!(/<%=.*?%>/, '')

      # Ensure directory exists
      FileUtils.mkdir_p(File.dirname(@theme_path))

      # Write the processed file
      File.write(@theme_path, processed)
      puts "Success: Generated '#{(@theme_path)}' from ActiveScafer theme"
      puts caller

      Rails.logger.info "✅ ActiveScaffold: jQuery UI theme generated at #{@theme_path}"
    rescue => e
      Rails.logger.error "ActiveScaffold: Failed to generate jQuery UI theme: #{e.message}"
    end
  end
end