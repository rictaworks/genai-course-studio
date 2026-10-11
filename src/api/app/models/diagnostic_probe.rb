class DiagnosticProbe < ApplicationRecord
  validates :key, format: { with: /\Afixture-[0-9a-f-]{36}\z/ }
  validates :outcome, inclusion: { in: %w[success failure] }
  validates :status, inclusion: { in: %w[pending succeeded failed] }
end
