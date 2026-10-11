require "minitest/autorun"
require "yaml"
require "open3"
require "tempfile"

class WorkflowTest < Minitest::Test
  def test_ruby_setup_uses_root_version_with_api_bundle_directory
    root = File.expand_path("..", __dir__)
    workflow = YAML.load_file(File.join(root, ".github/workflows/ci.yml"))
    steps = workflow.fetch("jobs").fetch("independent").fetch("steps")
    setup = steps.find { |step| step["uses"] == "ruby/setup-ruby@v1" }.fetch("with")
    reader = steps.find { |step| step["id"] == "ruby-version" }
    refute_nil reader, "Read root .ruby-version before changing to API working-directory"
    Tempfile.create("ruby-version-output") do |output|
      _, stderr, status = Open3.capture3({ "GITHUB_OUTPUT" => output.path }, "bash", "-e", "-c", reader.fetch("run"), chdir: root)
      assert status.success?, stderr
      version = File.read(output.path).strip.delete_prefix("version=")
      assert_match(/\A\d+\.\d+\.\d+\z/, version)
      assert_equal File.read(File.join(root, ".ruby-version")).strip, version
      assert_equal "${{ steps.ruby-version.outputs.version }}", setup.fetch("ruby-version")
      assert File.file?(File.join(root, setup.fetch("working-directory"), "Gemfile.lock"))
    end
  end
end
