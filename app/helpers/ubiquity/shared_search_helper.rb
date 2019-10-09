module Ubiquity
  module SharedSearchHelper
    #request_protocol example are http:// and https://
    #request_port examples are 8080
    # call with:
    # generate_work_url('137e67f1-e25b-4a18-8f5c-a885aa168230', 'bl.oar.bl.uk', 'article', '"oar.bl.uk"', 'https://', request_port=nil)
    #
    def generate_work_url(id, tenant, model_class, request_host, request_protocol, request_port=nil)
        work_class = model_class.to_s.underscore.pluralize
        if work_class == "collections"
          set_collection_url(id, tenant, work_class, request_host, request_protocol, request_port)
        else
          set_work_url(id, tenant, work_class, request_host, request_protocol, request_port)
        end
    end

    private
    def set_work_url(id, tenant, work_class, request_host, request_protocol, request_port)
      
      if request_host.include?('localhost')
        "#{request_protocol}#{tenant}:#{request_port}/concern/#{work_class}/#{id}?locale=en"
      else
        "#{request_protocol}#{tenant}/concern/#{work_class}/#{id}?locale=en"
      end
    end

    def set_collection_url(id, tenant, work_class, request_host, request_protocol, request_port)
      if request_host == 'localhost'
        "#{request_protocol}#{tenant}:#{request_port}/#{work_class}/#{id}?locale=en"
      else
        "#{request_protocol}#{tenant}/#{work_class}/#{id}?locale=en"
      end
    end

  end
end