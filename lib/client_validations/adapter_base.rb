module ClientValidation
  # The base class of an adapter.
  class AdapterBase
    def self.response(name, &block)
      self.validation_responses[name] = ValidationResponse.new(&block)
    end

    private
      def self.validation_responses
        @validation_responses ||= {}
      end
  end
end
