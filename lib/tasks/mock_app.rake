# frozen_string_literal: true

namespace :mock_app do
  desc 'Start the mock_app server and Dart Sass watcher (default port 3000)'
  task :server do
    args = ARGV.drop_while { |a| a != '--' }.drop(1)
    Dir.chdir('test/mock_app') do
      environment = { 'BUNDLE_GEMFILE' => File.expand_path('../../Gemfile', __dir__) }
      system(environment, 'rails', 'dartsass:build', exception: true)
      watcher = Process.spawn(environment, 'rails', 'dartsass:watch')
      _pid, status = Process.wait2(Process.spawn(environment, 'rails', 'server', *args))
      exit status.exitstatus
    ensure
      begin
        if watcher
          Process.kill('TERM', watcher)
          Process.wait(watcher)
        end
      rescue Errno::ECHILD, Errno::ESRCH
        # The watcher already exited.
      end
    end
  end

  desc 'Start the mock_app console'
  task :console do
    args = ARGV.drop_while { |a| a != '--' }.drop(1)
    Dir.chdir('test/mock_app') do
      exec({'BUNDLE_GEMFILE' => File.expand_path('../../Gemfile', __dir__)},
           'rails', 'console', *args)
    end
  end
end
