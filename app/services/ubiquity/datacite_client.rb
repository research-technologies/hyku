module Ubiquity
  class DataciteClient
    include HTTParty
    # base_uri 'https://api.datacite.org'
    default_timeout 6
    include Ubiquity::DataciteCrossrefClient
  end
end