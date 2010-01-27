module ClientValidation
  def current_adapter
    self.current_adapter = ClientValidation::Adapters::JqueryValidations
    adapter = @current_adapter

    return adapter
  end

  def current_adapter=(adapter)
    @current_adapter = adapter
  end

  extend self
end
