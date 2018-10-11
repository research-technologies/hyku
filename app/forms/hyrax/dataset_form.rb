# Generated via
#  `rails generate hyrax:work Dataset`
module Hyrax
  class DatasetForm < Hyrax::Forms::WorkForm
    include Hyrax::FormTerms
    include ::Ubiquity::AllFormsSharedBehaviour

    self.model_class = ::Dataset
    self.terms += %i[title resource_type creator contributor rendering_ids doi alternate_identifier
                     version related_identifier publisher date_published place_of_publication
                     date_published date_accepted date_submitted abstract keyword institution org_unit
                     refereed official_link related_url project_name funder fndr_project_ref add_info
                     language license rights_statement rights_holder]
  end
end