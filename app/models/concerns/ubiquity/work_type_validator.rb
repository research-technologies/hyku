module Ubiquity
  module WorkTypeValidator
    extend ActiveSupport::Concern

    included do
      validate :validator_work_type  if :get_work_list.present?
    end

    def validator_work_type
      if not get_work_list.include?(self.class)
        errors.add("#{self.class}", "is not in your list of work types")
      end
    end

    def get_work_list
      parser_class = Ubiquity::ParseTenantWorkSettings.new(self.account_cname)
      work_list = parser_class.get_per_account_settings_value_from_tenant_settings("work_type_list")
      work_types_array = work_list.presence && work_list.split(',')
      work_types_array.present? ? work_types_array.map {|i| i.classify.constantize} : Hyrax.config.curation_concerns
    end
  end
end