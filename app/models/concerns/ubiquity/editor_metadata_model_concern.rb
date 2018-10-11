module Ubiquity
  module EditorMetadataModelConcern
    extend ActiveSupport::Concern
    include Ubiquity::AllModelsVirtualFields

    included do

      property :editor, predicate: ::RDF::Vocab::SCHEMA.Person do |index|
        index.as :stored_searchable
      end


      attr_accessor :editor_group, :editor_name_type, :editor_given_name,
                    :editor_family_name, :editor_orcid, :editor_isni,
                    :editor_position

      before_save :save_editor
    end

    private

    def save_editor
      if self.editor_group.present?
        new_editor_group = remove_hash_keys_with_empty_and_nil_values(self.editor_group)
        editor_json = new_editor_group.to_json
        self.editor = [editor_json]
      end
    end
  end
end