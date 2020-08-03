module Ubiquity
  module ExpiryUtil
    extend ActiveSupport::Concern

    private

    def get_visibility_after_expiration(model_instance, type)
      object = model_instance.send("#{type}_history") #if model_instance.embargo_history.present?
      if object.present?
        object.first.split('.').last.split('and').last.split(' ').last
      end
    end

    def compare_visibility_after_expiration?(model_instance, type)
      expired_visibility = get_visibility_after_expiration(model_instance, "#{type}")
      if expired_visibility != nil
        needs_visibility_reset = (model_instance.visibility != expired_visibility)
      end
    end

    #before adding a file with expired lease, use this method to check it has no embargo
    #before adding a file with expired embargo, use this file to check it has no lease
    #if either of the above is true, enter another elsif block in
    #in fetch_embargo_records_for_single_tenant or fetch_lease_records_for_single_tenant
    #and then  set_values
    def return_either_embargo_or_lease(model_instance)
      if  model_instance.embargo_history.present? && model_instance.lease_history.present?
        expired_embargo_date = model_instance.embargo_history.first.split('.')[1].split(' ').last.split(' ').last
        expiry_lease_date = model_instance.lease_history.first.split('.')[1].split(' ').last.split(' ').last
        embargo_expiry_date = Date.parse(expired_embargo_date)
        lease_expiry_date = Date.parse(expiry_lease_date)
        get_older_date = [embargo_expiry_date, lease_expiry_date].max
      elsif model_instance.embargo_release_date.present? && model_instance.lease_expiration_date.present?
        embargo_expiry_date = model_instance.embargo_release_date
        lease_expiry_date = model_instance.lease_expiration_date
        get_older_date = [embargo_expiry_date, lease_expiry_date].max
      end
      if  get_older_date.present? && get_older_date == expiry_lease_date
        'lease'
      elsif get_older_date.present? && get_older_date == embargo_expiry_date
        'embargo'
      end
    end

  end

end