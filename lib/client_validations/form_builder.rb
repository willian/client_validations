module ClientValidation
  module FormBuilder
    def client_validations(custom_form_id = nil)
      unless custom_form_id
        if object.new_record?
          form_id = "new_#{object.class.model_name.singular}"
        else
          form_id = "edit_#{object.class.model_name.singular}_#{object.to_param}"
        end
      else
        form_id = custom_form_id
      end
      declarations, validations = ClientValidation.current_adapter.render_script(object)
      js = <<-EOF
        jQuery(function() {
          #{declarations}
          jQuery('##{form_id}').validate({
            rules: #{validations[:rules].to_json},
            messages: #{validations[:messages].to_json}
          });
        });
      EOF

      template ||= @template

      if "".respond_to?(:html_safe)
        html = template.content_tag(:script, js.html_safe, :type => "text/javascript").html_safe
      else
        html = template.content_tag(:script, js, :type => "text/javascript")
      end
      html
    end
  end
end
