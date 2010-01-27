ActionController::Routing::Routes.draw do |map|
  map.connect 'client_validations/:action', :controller => 'client_validations'
end