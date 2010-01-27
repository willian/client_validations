module ClientValidation
  class Util
    def self.message_for(field_scope, key)
      field_name = I18n.translate(field_scope, {:scope => "activerecord.attributes"})
      message_text = I18n.translate(key, {:scope => 'activerecord.errors.messages'})
      "#{field_name} #{message_text}"
    end
  end
end