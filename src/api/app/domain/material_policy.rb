module MaterialPolicy
  EXTERNAL = %w[learner instructor design].freeze
  def self.external_candidates(materials)
    materials.select { |material| EXTERNAL.include?(material[:classification]) }
  end
  def self.learner_input(materials)
    materials.select { |material| material[:classification] == "learner" }
  end
end
