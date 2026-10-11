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
  def test_ci_database_is_disposable_and_loopback_only
    root = File.expand_path("..", __dir__)
    workflow = YAML.load_file(File.join(root, ".github/workflows/ci.yml"))
    job = workflow.fetch("jobs").fetch("independent")
    service = job.fetch("services", {}).fetch("postgres", {})
    assert_equal "postgres:18.6", service["image"]
    assert_equal [ "127.0.0.1:5432:5432" ], service["ports"]
    refute service.key?("volumes")
    refute service.key?("credentials")
    assert_equal "studio_ci_test", service.fetch("env").fetch("POSTGRES_DB")
    assert_includes job.fetch("env").fetch("TEST_DATABASE_URL"), "@127.0.0.1:5432/studio_ci_test"
    refute job.fetch("env").key?("DATABASE_URL")
    assert job.fetch("steps").any? { |step| step["run"] == "timeout 900 scripts/ci-check" }
  end
end
