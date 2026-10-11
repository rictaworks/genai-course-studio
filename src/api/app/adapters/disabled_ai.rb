class DisabledAi
  class Unavailable < StandardError; end
  %i[reasoning fact_check creation judgment].each do |operation|
    define_method(operation) { |_input| raise Unavailable, "external_ai_disabled" }
  end
end
