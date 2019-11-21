# Generated by hyrax:models
class Collection < ActiveFedora::Base

  #added by ubiquitypress
  include Ubiquity::WorkAndCollectionMetadata
  include Ubiquity::UpdateSharedIndex
  include ::Ubiquity::CachingSingle

  include ::Hyrax::CollectionBehavior
  # You can replace these metadata if they're not suitable
  include Hyrax::BasicMetadata
  self.indexer = CollectionIndexer
end
