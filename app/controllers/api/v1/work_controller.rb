class API::V1::WorkController < ActionController::Base
  #defines :limit, :default_limit, :models_to_search, :switche_tenant
  include Ubiquity::ApiControllerUtilityMethods
  include Ubiquity::ApiErrorHandlers

  before_action :fetch_work, only: [:show, :manifest]

  def index
    if request.query_parameters.blank? || request.query_parameters.keys.to_set == ["per_page", "page"].to_set || request.query_parameters.keys == ["per_page"]
      fetch_all_works
    elsif params[:type].present?
      filter_by_resource_type
    else
      filter_by_metadata
    end
  end

  def show
    fresh_when(etag: @fedora_work, last_modified: @fedora_work.date_modified, public: true)
  end

  def manifest
    work_class = @work['has_model_ssim']
    controller_in_use = "Hyrax::#{work_class}Controller".camelize.constantize.new
    request.env["HTTP_HOST"]  = @work['account_cname_tesim']
    controller_in_use.request = request
    controller_in_use.response = response
    record = controller_in_use.manifest
    render json: record
  end

  private

  def fetch_work
    work = CatalogController.new.repository.search(q: params[:id],  "sort" => "score desc, system_create_dtsi desc",
    "facet.field "=> ["resource_type_sim", "creator_search_sim", "keyword_sim", "member_of_collections_ssim", "institution_sim",
    "language_sim", "file_availability_sim"])

    @work = work['response']['docs'].first
  end

  def fetch_all_works
    record = CatalogController.new.repository.search(q: "id:*", fq: models_to_search , rows: 1, "sort" => "score desc, system_modified_dtsi desc")
    total_count = record['response']['numFound']
    file_ids = record['response']['docs'].first["file_set_ids_ssim"]
    last_updated_child = CatalogController.new.repository.search(q: "", fq: ["{!terms f=id}#{file_ids.join(',')}"],  rows: 1, "sort" => "score desc, system_modified_dtsi desc")


    if record.present? && params[:per_page].present? && offset < total_count
      #something similar to multiple/library.localhost/2019-10-21T14:02:35Z/53
      set_cache_key = get_records_with_pagination_cache_key(record, last_updated_child)
      works_json  = Rails.cache.fetch(set_cache_key) do
         @works = CatalogController.new.repository.search(q: '', fq: models_to_search, "sort" => "score desc, system_create_dtsi desc",
         "facet.field" => ["resource_type_sim", "creator_search_sim", "keyword_sim", "member_of_collections_ssim", "institution_sim",
         "language_sim", "file_availability_sim"], rows: limit, start: offset)

         render_to_string(:template => 'api/v1/work/index.json.jbuilder', locals: {works: @works })
      end
      render json: works_json

    elsif record.present? && params[:per_page].blank? || offset > total_count
      #looks like "multiple/library.localhost/page-1/per_page-2/2019-10-23T20:48:11Z/53"
      set_cache_key = get_records_cache_key(record, last_updated_child)

      @limit = default_limit
      works_json  = Rails.cache.fetch(set_cache_key) do
        @works = CatalogController.new.repository.search(q: '', fq: models_to_search, "sort" => "score desc, system_create_dtsi desc",
        "facet.field" => ["resource_type_sim", "creator_search_sim", "keyword_sim", "member_of_collections_ssim", "institution_sim",
        "language_sim", "file_availability_sim"], rows: limit)

        render_to_string(:template => 'api/v1/work/index.json.jbuilder', locals: {works: @works})
      end
      render json: works_json

    end
  end

  def filter_by_resource_type
    record = CatalogController.new.repository.search(q: "id:*", fq: "has_model_ssim:#{params[:type].camelize.constantize}" , rows: 1, "sort" => "score desc, system_modified_dtsi desc")
    total_count = record['response']['numFound']
    file_ids = record['response']['docs'].first["file_set_ids_ssim"]
    last_updated_child = CatalogController.new.repository.search(q: "", fq: ["{!terms f=id}#{file_ids.join(',')}"],  rows: 1, "sort" => "score desc, system_modified_dtsi desc")

    if record.present? &&  params[:per_page].present? && offset < total_count
      #returns keys like multiple/library.localhost/article/page-0/per_page-2/2019-07-10T14:10:50Z/14
      set_cache_key = add_filter_by_class_type_with_pagination_cache_key(record, last_updated_child)

      works_json  = Rails.cache.fetch(set_cache_key) do
        @works = CatalogController.new.repository.search(q: "id:*", fq: "has_model_ssim:#{params[:type].camelize.constantize}", rows: limit, start: offset )
        render_to_string(:template => 'api/v1/work/index.json.jbuilder', locals: {works: @works})
      end
      render json: works_json

    elsif record.present? && params[:per_page].blank? || offset > total_count
      #returns value like multiple/library.localhost/article/2019-07-10T14:10:50Z/14
      set_cache_key = add_filter_by_class_type_cache_key(record, last_updated_child)
      @limit = default_limit
      works_json  = Rails.cache.fetch(set_cache_key) do
        @works = CatalogController.new.repository.search(q: "id:*", fq: "has_model_ssim:#{params[:type].camelize.constantize}", rows: limit )
        render_to_string(:template => 'api/v1/work/index.json.jbuilder', locals: {works: @works})
       end
       render json: works_json

    end
  end

  def filter_by_metadata
    extracted_params = request.query_parameters.except(*['per_page', 'page'])
    metadata_field = extracted_params.keys.first.try(:to_sym)
    value = extracted_params[metadata_field]

   if [:availability].include? metadata_field
     fetch_by_file_availability(metadata_field, value)
   else
     fetch_by_other_metatdata_fields(metadata_field, value)
   end

  end

  def fetch_by_file_availability(metadata_field, value)
    record = CatalogController.new.repository.search(q: "id:*", fq: ["{!term f=file_availability_sim}#{map_search_values[value.to_sym]}", "{!terms f=has_model_ssim}#{model_list}"], rows: 1, "sort" => "score desc, system_modified_dtsi desc")
    total_count = record['response']['numFound']
    file_ids = record['response']['docs'].first["file_set_ids_ssim"]
    last_updated_child = CatalogController.new.repository.search(q: "", fq: ["{!terms f=id}#{file_ids.join(',')}"],  rows: 1, "sort" => "score desc, system_modified_dtsi desc")

    if record.present? && params[:per_page].present? && offset < total_count
      set_cache_key = add_filter_by_metadata_field_with_pagination_cache_key(record, metadata_field), last_updated_child
      works_json  = Rails.cache.fetch(set_cache_key) do
        @works =  CatalogController.new.repository.search(:q=>"", fq: ["{!term f=file_availability_sim}#{map_search_values[value.to_sym]}", "{!terms f=has_model_ssim}#{model_list}"], rows: limit, start: offset)
        render_to_string(:template => 'api/v1/work/index.json.jbuilder', locals: {works: @works})
      end
      render json: works_json

    elsif record.present? && params[:per_page].blank? || offset > total_count
      #returns keys like "multiple/library.localhost/availability/2019-07-10T14:10:50Z/18"
      set_cache_key = add_filter_by_metadata_field_cache_key(record, metadata_field, last_updated_child)

      @limit = default_limit
      works_json  = Rails.cache.fetch(set_cache_key) do
        @works =  CatalogController.new.repository.search(:q=>"", rows: limit, fq: ["{!term f=file_availability_sim}#{map_search_values[value.to_sym]}", "{!terms f=has_model_ssim}#{model_list}"])
        render_to_string(:template => 'api/v1/work/index.json.jbuilder', locals: {works: @works})
      end
      render json: works_json
    end
  end

  def fetch_by_other_metatdata_fields(metadata_field, value)
    record = CatalogController.new.repository.search(q:  "#{map_search_keys[metadata_field]}:#{value}", rows: 1, "sort" => "score desc, system_modified_dtsi desc")
    total_count = record['response']['numFound']
    file_ids = record['response']['docs'].first["file_set_ids_ssim"]
    last_updated_child = CatalogController.new.repository.search(q: "", fq: ["{!terms f=id}#{file_ids.join(',')}"],  rows: 1, "sort" => "score desc, system_modified_dtsi desc")


    if record.present? && params[:per_page].present? && offset < total_count
      set_cache_key = add_filter_by_metadata_field_with_pagination_cache_key(record, metadata_field, last_updated_child)
      works_json  = Rails.cache.fetch(set_cache_key) do
        @works =  CatalogController.new.repository.search(q: "#{map_search_keys[metadata_field]}:#{value}", rows: limit, start: offset)
        render_to_string(:template => 'api/v1/work/index.json.jbuilder', locals: {works: @works})
      end
      render json: works_json

    elsif record.present? && params[:per_page].blank? || offset > total_count
      set_cache_key = add_filter_by_metadata_field_cache_key(record, metadata_field, last_updated_child)
      @limit = default_limit
      works_json  = Rails.cache.fetch(set_cache_key) do
        @works =  CatalogController.new.repository.search(q: "#{map_search_keys[metadata_field]}:#{value}", rows: limit)
        render_to_string(:template => 'api/v1/work/index.json.jbuilder', locals: {works: @works})
      end
      render json: works_json

    end
  end

  def map_search_keys
      {
        creator: 'creator_tesim', keyword: 'keyword_sim',
        collection_uuid: 'member_of_collection_ids_ssim',
        language: 'language_sim',  availability: 'file_availability_sim'
      }
  end

  def map_search_values
    {
       not_available: 'File not available', available: 'File available from this repository', external_link:  'External link (access may be restricted)'
    }
  end

end
