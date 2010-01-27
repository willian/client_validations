require "client_validations"
require "client_validations/form_builder"
require "client_validations/util"
require "client_validations/adapter_base"
require "client_validations/adapter_base/validation_hook"
require "client_validations/adapter_base/validation_response"
require "client_validations/adapters/jquery_validations"

# Hook into the default form builder
# ActionView::Helpers::FormBuilder.class_eval { include ClientValidation::FormBuilder }
ActionView::Helpers::FormBuilder.send :include, ClientValidation::FormBuilder
