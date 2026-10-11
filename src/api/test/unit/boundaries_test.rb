require "minitest/autorun"
require_relative "../../app/domain/material_policy"
require_relative "../../app/adapters/disabled_ai"
require_relative "../../lib/database_safety"
require_relative "../../app/domain/fixture_access"

class BoundariesTest < Minitest::Test
  def test_material_allowlists_fail_closed
    materials = %w[learner instructor design confidential unknown].map { |kind| { classification: kind, content: kind } }
    assert_equal %w[learner instructor design], MaterialPolicy.external_candidates(materials).map { |m| m[:classification] }
    assert_equal [ "learner" ], MaterialPolicy.learner_input(materials).map { |m| m[:classification] }
    assert_empty MaterialPolicy.external_candidates([ { content: "unclassified" } ])
  end

  def test_all_ai_boundaries_disabled
    %i[reasoning fact_check creation judgment].each do |operation|
      assert_raises(DisabledAi::Unavailable) { DisabledAi.new.public_send(operation, []) }
    end
  end

  def test_fixture_access_never_opens_production
    assert FixtureAccess.allowed?("development", "1")
    assert FixtureAccess.allowed?("test", "1")
    refute FixtureAccess.allowed?("production", "1")
    refute FixtureAccess.allowed?("development", nil)
  end

  def test_test_database_is_required_and_separate_ignoring_credentials_and_options
    assert_raises(DatabaseSafety::Unsafe) { DatabaseSafety.verify_test!(nil, nil) }
    assert_raises(DatabaseSafety::Unsafe) { DatabaseSafety.verify_test!("postgres://u:p@localhost/db", "postgresql://other@127.0.0.1:5432/db?sslmode=require") }
    assert_raises(DatabaseSafety::Unsafe) { DatabaseSafety.verify_test!("postgres://localhost/db?dbname=other", nil) }
    assert_raises(DatabaseSafety::Unsafe) { DatabaseSafety.verify_test!("sqlite3:test", nil) }
    assert DatabaseSafety.verify_test!("postgres://localhost/test_db", "postgres://localhost/dev_db")
  end
end
