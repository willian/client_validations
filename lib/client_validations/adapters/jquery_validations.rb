module ClientValidation
  module Adapters
    # Adapter for jQuery Validation
    class JqueryValidations < ClientValidation::AdapterBase

      response :uniqueness do |r|
        column  = r.params[r.params[:model_class].downcase].keys.first
        value   = r.params[r.params[:model_class].downcase][column]
        r.params[:model_class].constantize.count(:conditions => {column => value}) == 0
      end

      def self.render_script(object)
        @declarations = []
        @validators = {}
        @messages = {}

        @klasses = [object.class]

        # Discovering all models
        object.class.reflections.keys.uniq.each do |assoc_object|
          unless object.class.reflections[assoc_object].options.include?(:through)
            if object.class.reflections[assoc_object].options[:class_name]
              assoc_object = {:class_name => object.class.reflections[assoc_object].options[:class_name], :object_name => assoc_object.to_s}
            else
              assoc_object = assoc_object.to_s
            end

            if assoc_object.is_a?(Hash)
              if assoc_object[:class_name] =~ /ss$/
                assoc_object[:class_name] = assoc_object[:class_name].camelize.constantize
                assoc_object[:object_name] = assoc_object[:object_name].camelize
              else
                assoc_object[:class_name] = assoc_object[:class_name].camelize.singularize.constantize
                assoc_object[:object_name] = assoc_object[:object_name].camelize.singularize
              end
            else
              if assoc_object =~ /ss$/
                assoc_object = assoc_object.camelize.constantize
              else
                assoc_object = assoc_object.camelize.singularize.constantize
              end
            end
            @klasses << assoc_object
          end
        end

        # Gererating the jQuery Validator code
        @klasses.each do |klass|
          if klass.is_a?(Hash)
            self.generate_validations(object, klass[:class_name], klass[:object_name])
          else
            self.generate_validations(object, klass)
          end
        end
        [@declarations, {:rules => @validators, :messages => @messages}]
      end

      def self.generate_validations(object, klass, object_name = nil)
        @klass = klass
        @klass.reflect_on_all_validations.each do |v|
          @v = v

          if object_name.nil?
            prefix = @klass.model_name.singular
          else
            prefix = object_name.underscore
          end

          attribute_name = v.name unless v.macro == :validates_confirmation_of
          attribute_name = "#{v.name}_confirmation" if v.macro == :validates_confirmation_of

          @translate_message_key = "#{prefix}.#{v.name}"

          if object.class.model_name.singular == prefix
            @field_name = "#{prefix}[#{attribute_name}]"
            @field_id = "#{prefix}_#{attribute_name}"
          else
            prefix = "#{prefix}_attributes"

            @field_name = "#{object.class.model_name.singular}[#{prefix}][#{attribute_name}]"
            @field_id = "#{object.class.model_name.singular}_#{prefix}_#{attribute_name}"
          end
          @validators[@field_name] = {} unless @validators[@field_name]
          @messages[@field_name] = {} unless @messages[@field_name]

          # Set validation
          unless v.options[:allow_nil] && v.options[:allow_blank]
            @validators[@field_name]['required'] = true
            @messages[@field_name]['required'] = ClientValidation::Util.message_for(@translate_message_key, :blank)
          end
          eval("self.set_#{v.macro.to_s}")
        end
      end

      def self.set_validates_acceptance_of
        @validators[@field_name]['required'] = true
        @messages[@field_name]['required'] = ClientValidation::Util.message_for(@translate_message_key, :accepted)
      end

      def self.set_validates_associated
        # Nothing to do here
      end

      def self.set_validates_confirmation_of
        @validators[@field_name]['equalTo'] = "##{@field_id.gsub('_confirmation', '')}"
        @validators[@field_name]['required'] = true

        message = ClientValidation::Util.message_for(@translate_message_key, :confirmation)
        @messages[@field_name]['equalTo'] = message
        @messages[@field_name]['required'] = message
      end

      def self.set_validates_exclusion_of
        enum = @v.options[:in]
        message = ClientValidation::Util.message_for(@translate_message_key, :exclusion)
        add_custom_rule(@field_name, Digest::SHA1.hexdigest(enum.inspect), "var list = #{enum.to_json}; for (var i=0; i<list.length; i++){if(list[i] == value) { return false; }} return true;", message)
      end

      def self.set_validates_inclusion_of
        enum = @v.options[:in] || @v.options[:within]
        message = ClientValidation::Util.message_for(@translate_message_key, :inclusion)

        case enum
        when Range
          @validators[@field_name]['range'] = [enum.first, enum.last]
          @messages[@field_name]['range'] = message
        when Array
          add_custom_rule(@field_name, Digest::SHA1.hexdigest(enum.inspect), "var list = #{enum.to_json}; for (var i=0; i<list.length; i++){if(list[i] == value) { return true; }}", message)
        end
      end

      def self.set_validates_format_of
        regex = @v.options[:with].inspect.gsub(/(.*)\/.*$/, '\1/')
        message = ClientValidation::Util.message_for(@translate_message_key, :invalid)
        add_custom_rule(@field_name, Digest::SHA1.hexdigest("#{@field_name}_#{regex.inspect}"), "return #{regex}.test(value)", message)
      end

      def self.set_validates_length_of
        if @v.options[:minimum]
          @validators[@field_name]['minlength'] = @v.options[:minimum]
          @messages[@field_name]['minlength'] = ClientValidation::Util.message_for(@translate_message_key, :too_short)
        end

        if @v.options[:maximum]
          @validators[@field_name]['maxlength'] = @v.options[:maximum]
          @messages[@field_name]['maxlength'] = ClientValidation::Util.message_for(@translate_message_key, :too_long)
        end

        if @v.options[:within] || @v.options[:in]
          r = @v.options[:within] || @v.options[:in]
          @validators[@field_name]['rangelength'] = [r.first, r.last]
          @messages[@field_name]['rangelength'] = "#{ClientValidation::Util.message_for(@translate_message_key, :inclusion)} (min: #{r.first}, max: #{r.last})"
        end

        if @v.options[:is]
          length = @v.options[:is]
          add_custom_rule(@field_name, "lengthIs#{length}", "return value.length == #{length}", ClientValidation::Util.message_for(@translate_message_key, :wrong_length))
        end
      end

      def self.set_validates_numericality_of
        @validators[@field_name]['digits'] = true
        @validators[@field_name]['required'] = true

        message = ClientValidation::Util.message_for(@translate_message_key, :not_a_number)
        @messages[@field_name]['digits'] = message
        @messages[@field_name]['required'] = message
      end

      def self.set_validates_uniqueness_of
        @validators[@field_name]['remote'] = "/client_validations/uniqueness?model_class=#{@klass.to_s}"
        @messages[@field_name]['remote'] = ClientValidation::Util.message_for(@translate_message_key, :taken)
      end

      def self.set_validates_presence_of
        @validators[@field_name]['required'] = true
        @messages[@field_name]['required'] = ClientValidation::Util.message_for(@translate_message_key, :blank)
      end

      def self.add_custom_rule(attribute, identifier, validation, message)
        @declarations << <<-EOF
          jQuery.validator.addMethod('#{identifier}', function(value){
            #{validation}
          }, '#{message}');
        EOF
        @validators[@field_name][identifier] = true
      end

    end
  end
end