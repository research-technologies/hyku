# Generated by hyrax:models:install
class FileSet < ActiveFedora::Base
  include ::Hyrax::FileSetBehavior
  include Ubiquity::FileAvailabilityCallback

  before_destroy :remove_rendering_relationship
  before_update :fetch_file_sets_and_create_work_expiry_service

  # Hyku has its own FileSetIndexer: app/indexers/file_set_indexer.rb
  # It overrides Hyrax to inject IIIF behavior.
  self.indexer = FileSetIndexer

  def rendering_ids
    to_param
  end

  def account_cname
    parent.try(:account_cname)
  end

  private

    # If any parent objects are pointing at this object as their
    # rendering, remove that pointer.
    def remove_rendering_relationship
      parent_objects = parents
      return if parent_objects.empty?
      parent_objects.each do |work|
        if work.rendering_ids.include(id)
          new_rendering_ids = work.rendering_ids.delete(id)
          work.update(rendering_ids: new_rendering_ids)
        end
      end
    end

    def fetch_file_sets_and_create_work_expiry_service
      embargo_condition_check = under_embargo? || active_lease?
      if embargo_condition_check && account_cname.present?
        work_service = WorkExpiryService.find_or_create_by(work_id: id)
        release_date = under_embargo? ? embargo.embargo_release_date : lease.lease_expiration_date
        work_service.update(work_type: 'file', tenant_name: account_cname, expiry_time: release_date)
      end
    end
end
