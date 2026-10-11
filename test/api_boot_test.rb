require "minitest/autorun"
require "open3"
require "tempfile"

class ApiBootTest < Minitest::Test
  def test_entrypoints_initialize_bundle_before_database_safety
    api = File.expand_path("../src/api", __dir__)
    Tempfile.create([ "boot-order", ".rb" ]) do |probe|
      probe.write(<<~RUBY)
        TracePoint.new(:line) do |event|
          if event.path.end_with?("/lib/database_safety.rb")
            abort "database safety loaded before config/boot" unless $LOADED_FEATURES.any? { |path| path.end_with?("/config/boot.rb") }
          end
        end.enable
      RUBY
      probe.flush
      %w[rails jobs].each do |entrypoint|
        _, stderr, status = Open3.capture3(
          { "RUBYOPT" => "-r#{probe.path}", "RAILS_ENV" => "test", "TEST_DATABASE_URL" => nil, "DATABASE_URL" => nil },
          RbConfig.ruby, "bin/#{entrypoint}", chdir: api
        )
        assert_equal 1, status.exitstatus
        assert_includes stderr, "A separate, valid TEST_DATABASE_URL is required"
        refute_includes stderr, "database safety loaded before config/boot"
      end
    end
  end
end
