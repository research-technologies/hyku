# Generated via
#  `rails generate hyrax:work Dataset`
module Hyrax
  class DatasetForm < Hyrax::Forms::WorkForm
    include Hyrax::FormTerms
    self.model_class = ::Dataset
    self.terms += %i[resource_type rendering_ids doi issn eissn
                     date_published place_of_publication date_accepted date_submitted institution org_unit refereed
                     project_name funder fndr_project_ref add_info rights_holder]
    self.terms -= [:based_near]
    self.required_fields += %i[institution publisher date_published]
    self.required_fields -= %i[keyword rights_statement]
  end
end
