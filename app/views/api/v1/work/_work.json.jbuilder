#/home/edward/dev-2/hyku/app/views/api/v1/work/_work.json.jbuilder

json.uuid    work['id']
json.related_url    work['related_url_tesim']
json.work_type    work['has_model_ssim'].try(:first)
json.title    work['title_tesim'].try(:first)
json.alternative_title    work['alternative_title_tesim']
json.resource_type    work['resource_type_sim'].try(:first)
json.visibility    work['visibility_ssi']
creator = work['creator_tesim'].try(:first)
if valid_json?(creator)
  json.creator JSON.parse(creator)
end

contributor = work['contributor_tesim'].try(:first)
if valid_json?(contributor)
 json.contributor JSON.parse(contributor)
end

editor = work['editor_tesim'].try(:first)
if valid_json?(editor)
  json.editor JSON.parse(editor)
end

json.abstract    work['abstract_tesim'].try(:first)
json.date_published    work['date_published_tesim']
json.institution    work['institution_tesim']
json.organisational_unit    work['org_unit_tesim']
json.project_name    work['project_name_tesim']
json.funder    work['funder_tesim']
json.publisher   work['publisher_tesim']
json.date_accepted    work['date_accepted_tesim']
json.date_submitted    work['date_submitted_tesim']
json.official_url    work['official_url_tesim']
json.language    work['language_tesim']
json.license    work['license_for_api_tesim']
json.rights_statement    work['rights_statements_for_api_tesim']
json.rights_holder    work['rights_holder_tesim']
json.doi    work['doi_tesim']

alternate_identifier = work['alternate_identifier_tesim'].try(:first)
if valid_json?(alternate_identifier)
  alternate_identifier_array = JSON.parse(alternate_identifier)
  json.alternate_identifier do
    json.array! alternate_identifier_array do |hash|
      json.name hash['alternate_identifier']
      json.type hash['alternate_identifier_type']
      json.postion hash["alternate_identifier_position"].to_i
    end
  end
end

json.peer_reviewed    work['peer_reviewed_tesim']
json.keywords    work['keyword_tesim']
json.dewey    work['dewey_tesim']
json.library_of_congress_classification    work['library_of_congress_classification_tesim']
json.additional_info    work['add_info_tesim']

related_identifier = work['related_identifier_tesim'].try(:first)
if valid_json?(related_identifier)
  related_identifier_array = JSON.parse(related_identifier)
  json.related_identifier do
    json.array! related_identifier_array do |hash|
      json.name hash['related_identifier']
      json.type hash['related_identifier_type']
      json.relationship hash['relation_type']
      json.postion hash["related_identifier_position"].to_i
    end
  end
end

json.thumbnail_url    ('https://' + work['account_cname_tesim'].first + work['thumbnail_path_ss'])
json.download_link    ('https://' + work['account_cname_tesim'].first + '/' + 'downloads' + '/' + work[:id])

json.version    work['version_tesim']
json.duration    work['duration_tesim']
json.pagination    work['pagination_tesim']
json.series_name    work['series_name']
json.issue    work['issue_tesim']
json.volume    work['volume_tesim']
json.material_media    work['media_tesim']
json.edition    work['edition_tesim']

event = work['event_tesim'].try(:first)
if valid_json?(event)
  json.event JSON.parse(event)
end
json.journal_title    work['journal_title_tesim']
json.book_title    work['book_title_tesim']
json.article_number    work['article_number_tesim']
json.eissn    work['eissn_tesim']
json.issn    work['issn_tesim']
json.isbn    work['isbn_tesim']
json.current_he_institution    work['current_he_institution_tesim']
json.qualification_name    work['qualification_name_tesim']
json.qualification_levale    work['qualification_level_tesim']
json.alternative_journal_title    work['alternative_journal_title_tesim']

json.article_number     work['article_num_tesim']
json.alternative_alternative    work['alt_title_tesim']
json.place_of_publication     work['place_of_publication_tesim']
json.funder_project_reference    work['fndr_project_ref_tesim']
json.official_url     work['official_link_tesim']
json.event_title    work['event_title_tesim']
json.event_location    work['event_location_tesim']
json.event_date   work['event_date_tesim']
json.related_exhibition     work['related_exhibition_tesim']
json.related_exhibition_date    work['related_exhibition_date_tesim']
json.related_exhibition_venue     work['related_exhibition_venue_tesim']

get_files =  Ubiquity::ApiUtils.query_for_files(work["file_set_ids_ssim"])

if get_files.present?
  json.files get_files
else
  json.files  nil
end

get_collections =   Ubiquity::ApiUtils.query_for_parent_collections(work["member_of_collection_ids_ssim"])

if get_collections.present?
  json.collections do
    json.array! get_collections
  end
else
  json.collections  nil
end