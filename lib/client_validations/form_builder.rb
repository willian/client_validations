module ClientValidation
  module FormBuilder
    def client_validations
      if object.new_record?
        form_id = "new_#{object.class.model_name.singular}"
      else
        form_id = "edit_#{object.class.model_name.singular}_#{object.to_param}"
      end
      declarations, validations = ClientValidation.current_adapter.render_script(object)
      js = <<-EOF
        $(function() {
          #{declarations}
          $('##{form_id}').validate({
            rules: #{validations[:rules].to_json},
            messages: #{validations[:messages].to_json}
          });
        });
      EOF

      template ||= @template

      html = template.content_tag(:script, js, :type => "text/javascript")
      html.respond_to?(:html_safe!) ? html.html_safe! : html
    end
  end
end
