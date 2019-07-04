# Generated via
#  `rails generate hyrax:work Dataset`
class Dataset < ActiveFedora::Base
  include ::Hyrax::WorkBehavior
  include Ubiquity::BasicMetadataDecorator
  include Ubiquity::SharedMetadata
  include Ubiquity::AllModelsVirtualFields
  include Ubiquity::UpdateSharedIndex
  include Ubiquity::FileAvailabilityFaceting

  self.indexer = DatasetIndexer
  # Change this to restrict which works can be added as a child.
  # self.valid_child_concerns = []
  validates :title, presence: { message: 'Your work must have a title.' }

  self.human_readable_type = 'Dataset'

  # This must be included at the end, because it finalizes the metadata
  # schema (by adding accepts_nested_attributes)
  include ::Hyrax::BasicMetadata
end
