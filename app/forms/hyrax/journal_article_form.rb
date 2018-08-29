# Generated via
#  `rails generate hyrax:work JournalArticle`
module Hyrax
  class JournalArticleForm < Hyrax::Forms::WorkForm
    include Hyrax::FormTerms
    self.model_class = ::JournalArticle

    self.terms += %i[resource_type rendering_ids journal_title doi volume issue pagination place_of_publication issn eissn
                     article_num date_published date_accepted date_submitted abstract institution org_unit refereed
                     official_link project_name funder fndr_project_ref add_info rights_holder
                     creator_name_type given_name family_name ORCiD isni creator_organization
                     contributor_type contributor_given_name contributor_family_name contributor_orcid contributor_isni contributor_organization
                     ]
    self.terms -= %i[based_near description]
    self.required_fields += %i[resource_type journal_title institution publisher date_published]
    self.required_fields -= %i[keyword rights_statement]
  end
end