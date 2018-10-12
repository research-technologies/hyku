
module Ubiquity
  module AllModelsVirtualFields
    extend ActiveSupport::Concern

    included do

      before_save :save_contributor
      before_save :save_creator
      before_save :save_alternate_identifier
      before_save :save_related_identifier

      #These are used in the forms to populate fields that will be stored in json fields
      #The json fields in this case are creator, contributor, alternate_identifier and related_identifier
      attr_accessor :creator_group, :contributor_group, :alternate_identifier_group, :related_identifier_group
    end

    private

    #
    # We are addressing 2 use case for each json field
    # 1. When saving a new record
    #    a. loop through the array and reject empty or nil values from the hash.
    #    b. Using the data from 1a above, run an additionally t detect if the hash keys are meant for default values only.
    #    c. If step 1b returns true, then we just clear the array by settin the json field to an empty arry
    #
    # 2 when updating a record that has a mix, that is some hash need to be kept while removing those hash with only default values
    #    a. Same as step 1a and 1b Above
    #    b. Using the array of hash from the above step remove hash that contains only default keys and values.
    #    c. Save the the array of hashes from step 2b
    #
    def save_creator
      #remove Hash with empty values and nil
      clean_submitted_data ||= remove_hash_keys_with_empty_and_nil_values(self.creator_group)

      #Check if the hash keys are only those used for default values like position
      data = compare_hash_keys?(clean_submitted_data)

      if (self.creator_group.present? && clean_submitted_data.present? && data == false)
        # remove hash that contains only default keys and values.
        new_creator_group = remove_hash_with_default_keys(clean_submitted_data)
        creator_json = new_creator_group.to_json
        populate_creator_search_field(creator_json)
        self.creator = [creator_json]
      elsif data
        #save an empty array since the submitted data contains only default keys & values
        self.creator = []
      end
    end

    def save_contributor
      clean_submitted_data ||= remove_hash_keys_with_empty_and_nil_values(self.contributor_group)
      data = compare_hash_keys?(clean_submitted_data)
      if (self.contributor_group.present? && clean_submitted_data.present? && data == false )
        new_contributor_group = remove_hash_with_default_keys(clean_submitted_data)
        contributor_json = new_contributor_group.to_json
        self.contributor = [contributor_json]
      elsif data
       self.contributor = []
      end
    end

    def save_related_identifier
      clean_submitted_data ||= remove_hash_keys_with_empty_and_nil_values(self.related_identifier_group)
      data = compare_hash_keys?(clean_submitted_data)
      if (self.related_identifier_group.present?  && clean_submitted_data.present? && data == false)
        new_related_identifier_group = remove_hash_with_default_keys(clean_submitted_data)
        related_identifier_json = new_related_identifier_group.to_json
        self.related_identifier = [related_identifier_json]
      elsif data
       self.related_identifier = []
      end
    end

    def save_alternate_identifier
      clean_submitted_data ||= remove_hash_keys_with_empty_and_nil_values(self.alternate_identifier_group)
      data = compare_hash_keys?(clean_submitted_data)
      if (self.alternate_identifier_group.present? && clean_submitted_data.present? && data == false)
       #remove any empty hash in the array
       clean_submitted_data = clean_submitted_data - [{}]
        new_alternate_identifier_group = remove_hash_with_default_keys(clean_submitted_data)
        alternate_identifier_json = new_alternate_identifier_group.to_json
        self.alternate_identifier = [alternate_identifier_json]
      elsif data
        self.alternate_identifier = []
      end
    end

    private

    #We parse the json in the an array before saving the value in creator_search
    def populate_creator_search_field(json_record)
      values = Ubiquity::ParseJson.new(json_record).data
      self.creator_search = values
    end

    #remove hash keys with value of nil, "", and "NaN"
    def remove_hash_keys_with_empty_and_nil_values(data)
      if (data.present? && data.class == Array)
        data.map do |hash|
          hash.reject { |k,v| v.nil? || v.to_s.empty? || v == "NaN"}
        end
      end
    end

    #Check if the hash keys are only those used for default values like position
    def compare_hash_keys?(record)
      if record.present? && record.first.present?
        my_default_keys = get_default_hash_keys(record)
        keys_in_hash = record.map {|hash| hash.keys}.flatten.uniq
        (keys_in_hash == my_default_keys)
      else
        nil
      end
    end

    # remove any hash that contains only default keys and values.
    def remove_hash_with_default_keys(data)
      my_default_keys = get_default_hash_keys(data)
      new_data = data.reject {|hash| hash.keys.uniq == my_default_keys}
    end

    #data is an array of hash eg [{"contributor_organization_name"=>""}},{"contributor_name_type"=>"Personal"}]
    def get_default_hash_keys(data)
      if data.present? && data.first.present?

        #we get the first hash in the array and then get the first hash key
        record = data.first.keys.first || data

        #the value of record will be "contributor_organization_name" when using array of hash from the above comments
        #This means field name after the record.split will be 'contributor' and will change depending on the hash keys
        get_field_name ||= record.split('_').first
        ["#{get_field_name}_name_type", "#{get_field_name}_position"]
      end
    end

  end
end
