module FixtureAccess
  def self.allowed?(environment, flag)
    %w[development test].include?(environment) && flag == "1"
  end
end
