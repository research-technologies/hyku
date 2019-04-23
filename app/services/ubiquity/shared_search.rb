#call locally h = Ubiquity::SharedSearch.new(1, 10, 'local', "score desc, system_create_dtsi desc")
#
module Ubiquity
  class SharedSearch

    Hash_keys = ["system_create_dtsi", "id", "depositor_ssim", "title_tesim", "creator_search_tesim",
                "creator_tesim",  "date_published_tesim", "resource_type_tesim", "account_cname_tesim",  "pagination_tesim", "institution_tesim",
                "resource_type_tesim", "thumbnail_path_ss", "file_set_ids_ssim",
                "visibility_ssi", "has_model_ssim", "score" ].freeze

    NAME_MAPPING = {
      "system_create_dtsi" => 'Date Created', "title_tesim" => 'Title',
      "creator_tesim" => 'Creator:', "resource_type_tesim" => 'Resource Type:',
      "date_published_tesim" => "Date Published:", "institution_tesim" => 'Institution:'
    }.freeze

    PER_PAGE_OPTIONS = [10, 20, 50, 100].freeze

    SORT_OPTIONS =  [["relevance", "score desc, system_create_dtsi desc"], ["date uploaded ▼",
      "system_create_dtsi desc"], ["date uploaded ▲", "system_create_dtsi asc"]].freeze

    Facet_mappings = {
      'resource_type_sim'  => 'Resource Type',
      'institution_sim' => 'Institution',
      'creator_search_sim' => 'Creator',
      'keyword_sim' => 'Keyword',
      'member_of_collections_ssim' => 'Collections'
    }.freeze

    attr_accessor :tenant_names, :solr_url, :search_results,
                  :limit, :offset, :total_pages, :page, :demo_records,
                  :live_records, :live_tenant_names, :demo_tenant_names,
                  :live_solr_urls, :demo_solr_urls, :sort, :facet_values,
                  :facet_filtering, :build_facet_qf, :build_facet_and_text_query_fq

    def initialize(page, limit, host, sort=nil)
      @facet_values = {}
      @build_facet_qf = ''
      @build_facet_and_text_query_fq = ''
      @page = page.to_i
      @limit = limit.to_i
      @sort = sort

      @records_size = []
      @search_results = []
      @accounts = Account.where("cname ILIKE ?", "%#{host}%")

      @demo_records = @accounts.map {|acct| j if acct.cname.include? 'demo'}.compact
      @live_records = @accounts - @demo_records

      @live_tenant_names = @live_records.pluck(:cname)
      @live_solr_urls = @live_records.map {|acct| acct.solr_endpoint.options}.pluck('url')
    end

    def current_page
      @page
    end

    def limit_value
      (@limit/live_tenant_names.size).ceil
    end

    def offset
      limit * ([@page, 1].max - 1)
    end

    def total_pages
      @total_pages = @records_size.inject(0, :+)
    end

    def all
       fetch_all
    end

    def fetch_term(search_term)
      if search_term.present?
        sanitized_value = clean_and_downcase_user_search_term(search_term)
        multiple_field_search(sanitized_value, fields_to_search_against)
      end
    end

    def facet_filter_query(filters)
      if filters.present?
        term = build_query_params_from_facet_values(filters)
        multiple_field_search(term, @build_facet_qf)
      end
    end

    def combined_filter_query(search_term, filters)
      facet_query_terms = build_query_params_from_facet_values(filters)
      search_input = clean_and_downcase_user_search_term(search_term)
      #changed from AND to OR because search term eg darius and resource_type_sim dataset fails
      combined_terms = facet_query_terms.prepend("#{search_input} AND ")
      multiple_field_search(combined_terms, fields_to_search_against, 'multiple')
    end


    # maby_by without calling .to_h return_search
      #{:institution_sim=>[["Tate", 1], ["British Museum", 1], ["MOLA", 1], ["British Library", 1]]}
    # max_by with .to_h returns {:institution_sim=>{"Tate"=>1, "British Museum"=>1, "MOLA"=>1, "British Library"=>1}}
    #
    def five_values_from_facet_hash
     selected_facet = {}
     number = ENV['BL_SHARED_SEARCH_FACETS_SIZE']
     facet_size = number.present? ? number : 5
     facet_values.each { |key, value| selected_facet[key] = value.max_by(facet_size.to_i, &:last).to_h }
     selected_facet
    end

    def valid_json?(data)
      !!JSON.parse(data)  if data.class == String
      rescue JSON::ParserError
        false
    end

    private

    def fields_to_return
      'title_tesim, resource_type_tesim, institution_tesim, date_published_tesim, account_cname_tesim, thumbnail_path_ss, id, visibility_ssi,
      creator_tesim, creator_search_tesim, has_model_ssim, system_create_dtsi, system_modified_dtsi,  id, score, accessControl_ssim'
    end

    #You can not just increase a weight and expect to go one step higher sometimes it might go many steps,
    #so you need to experiment and check it is in the right position on the web
    #we applied a default weight 0.55
    def fields_to_search_against
      #fields to search against which is passed to the qf params
      "title_tesim^42.0 description_tesim^0.55 keyword_tesim^34.50 journal_title_tesim^25.0 subject_tesim^0.55 creator_tesim^36.50 editor_tesim^8.47 version_tesim^2.53 related_exhibition_tesim^0.59 media_tesim event_title_tesim^6.80 event_date_tesim
      event_location_tesim^6.85 abstract_tesim^70.0 book_title_tesim^0.61 series_name_tesim^7.40 edition_tesim^0.63 contributor_tesim^8.50 publisher_tesim^9.0 place_of_publication_tesim^10.0 date_published_tesim based_near_label_tesim^0.55
      language_tesim^7.60 date_uploaded_tesim date_modified_tesim date_created_tesim rights_statement_tesim^0.55 license_tesim^0.55 resource_type_tesim format_tesim identifier_tesim^0.55 doi_tesim^16.0 isbn_tesim^2.50
      issn_tesim^0.85 eissn_tesim^0.81 extent_tesim^0.55 institution_tesim org_unit_tesim^7.20 refereed_tesim^0.55 funder_tesim fndr_project_ref_tesim^0.83 add_info_tesim^45.0 date_accepted_tesim issue_tesim^0.65 volume_tesim^1.55
      pagination_tesim^1.30 article_num_tesim^0.67 project_name_tesim^7.0 official_link_tesim^12.0 rights_holder_tesim^28.0 library_of_congress_classification_tesim^1.25 file_format_tesim^0.55 all_text_timv^6.0"
    end

    def fetch_all
      @live_solr_urls.map do |url|
        solr_connection = RSolr.connect :url => url
        search_response = solr_connection.get("select", params: { q: "*:* AND visibility_ssi:open", fq: list_of_models_to_search, sort: sort, rows: 4000, "facet.field" => facet_fields, fl: fields_to_return })
        @records_size << search_response["response"]["docs"].size
        facet_data = search_response["facet_counts"]['facet_fields']
        remap_facet_values(facet_data)
        data =  search_response["response"]["docs"]
        search_results << data.map {|hash| hash.slice(*Hash_keys)}
      end
      result = search_results.flatten.compact
      return result.sort_by { |hash|[hash['system_create_dtsi'], hash['score'] ]}.reverse if resort_search == 'relevance'
      return result.sort_by { |hash| hash['system_create_dtsi']} if resort_search == 'asc'
      return result.sort_by { |hash| hash['system_create_dtsi']}.reverse if resort_search == 'desc'
    end

    def multiple_field_search(search_term, query_fields, type='single')
         @live_solr_urls.map do |url|
           solr_connection = RSolr.connect :url => url
           if type == 'single'
             search_response = solr_connection.get("select", params: { q: "#{search_term} AND visibility_ssi:open", :defType => "edismax", fq: list_of_models_to_search, qf: query_fields, sort: sort, rows: 4000, "facet.field" => facet_fields, fl: fields_to_return } )
           else
             search_response = solr_connection.get("select", params: { q: "#{search_term} AND visibility_ssi:open", :defType => "edismax", fq: @build_facet_and_text_query_fq, qf: query_fields, sort: sort, rows: 4000, "facet.field" => facet_fields, fl: fields_to_return } )
           end
          #add to total
           @records_size << search_response["response"]["docs"].size
           facet_data = search_response["facet_counts"]['facet_fields']
           remap_facet_values(facet_data)
           #pull out the data from the response
           data =  search_response["response"]["docs"]

           #return only the desired hash keys
           search_results << data.map {|hash| hash.slice(*Hash_keys)}
         end

         result = search_results.flatten.compact
         return result.sort_by { |hash|[ hash['score'],  hash['system_create_dtsi'] ]}.reverse if resort_search == 'relevance'
         return result.sort_by { |hash| hash['system_create_dtsi'] } if resort_search == 'asc'
         return result.sort_by { |hash| hash['system_create_dtsi']}.reverse if resort_search == 'desc'
    end

    def sanitize_input(search_value)
      regex = /[+ | ? * - ! ^ ~ ; :  || & ""]/
      search_value.gsub(regex, " ")
    end

    def list_of_models_to_search
      model_names_array = ENV["SHARED_SEARCH_TYPES"].split(',')
      model_names_string = "("
      model_names_array.each_with_index do |model_name, index|
        model_names_string << "has_model_ssim:#{model_name}" if  index == 0
        model_names_string << " OR has_model_ssim:#{model_name}" if index <   model_names_array.size
        model_names_string << " OR has_model_ssim:#{model_name})" if index == (model_names_array.size - 1)
      end
      model_names_string
    end

    #turns the result of query from multi-dimensional array to nested hash
    #eg {institution_sim: [[tate, 1] [mola, 1]]}
    #into {institution_sim: {tate: 1, mola: 1}}
    #
    def remap_facet_values(facet_data)
      new_facet_hash = { }
      facet_data.each { |key, value| new_facet_hash[key] = Hash[*facet_data[key].flatten(1)]}
      @facet_values.deep_merge!(new_facet_hash) { |key, this_val, other_val| this_val + other_val }
      new_facet_hash.clear
      facet_values
    end

    #facet fields to return in query response 'keyword_sim', "member_of_collections_ssim"
    def facet_fields
      facet_to_display = ENV['BL_SHARED_SEARCH_FACETS']
      if facet_to_display.present?
        facet_to_display.split(',')
      else
        ['resource_type_sim', 'creator_search_sim', 'institution_sim']
      end
    end

    def clean_and_downcase_user_search_term(search_term)
      sanitized_term = sanitize_input(search_term)
      sanitized_term #.downcase
    end

    def build_query_params_from_facet_values(filters)
      query_key = {'institution_sim' => 'institution_tesim', 'resource_type_sim' => 'resource_type_tesim',
      'creator_search_sim' => 'creator_search_tesim', 'keyword_sim' => 'Keyword_tesim',
      'member_of_collections_ssim' => 'member_of_collections_ssim'
      }

      data = filters
      #needed because when deleting multiple filters, a string is sometimes sent instead of hash
      #if the rquest is from the destroy action or a form submission
      data = JSON.parse(filters) if valid_json?(filters)
      term = ""
      add_query_field = ""
      data.each_with_index do |(key, value), index|
        term << "#{value}"  if index == 0
        term << " AND #{value}"  if index > 0
        @build_facet_qf << " #{query_key[key]} "
        @build_facet_and_text_query_fq << " #{query_key[key]}:#{value.gsub(' ', '+')}"
      end
      term
    end

    def resort_search
      if sort.present?
        splitted_sort_value = sort.split(',')
        return  splitted_sort_value.last.split(' ').last if splitted_sort_value.size == 1
        return 'relevance' if splitted_sort_value.size == 2
      else
         'relevance'
      end
    end

  end
end