class API::V1::ApiBaseController < ActionController::Base
  protect_from_forgery unless: -> { request.format.json? }
  include Ubiquity::ApiErrorHandlers

  before_action :switch_tenant
  before_action :get_auth_token
  before_action :authenticate_user_from_token
  before_action :allow_access_credentials_in_cors

  helper_method :current_user, :current_account, :current_api_ability

  def current_user
    if @token_id.present?
      user = User.find_by(id: @token_id)
      @current_user = user
    end
  end

  def current_account
    if @tenant.present?
      @current_account ||= @tenant
    end
  end

  private

  def current_api_ability
    if current_user.present?
    @current_ability ||= Ability.new(current_user)
    end
  end

  def authenticate_user_from_token
    if current_user.present?
      @current_user
    end
  end

  def get_auth_token
    auth_header = request.headers['Authorization'] || cookies[:jwt]
    if auth_header.present? && request.headers['Authorization'].present?
      authenticate_or_request_with_http_token do |token, options|
        jwt = Ubiquity::Api::JwtGenerator.decode(token).try(:with_indifferent_access)
        @token_id = jwt['id']
      end
    elsif auth_header.present? && cookies[:jwt].present?
      jwt = Ubiquity::Api::JwtGenerator.decode(auth_header).try(:with_indifferent_access)
      @token_id = jwt['id']
    end

  end

  def find_parent
    tenant_id = params[:tenant_id] || params['tenant_id']
    @tenant ||= Account.find_by(tenant: params[:tenant_id])
  end

  def switch_tenant
    find_parent
    if @tenant && @tenant.cname.present?
      tenant_name = @tenant.cname
      AccountElevator.switch!(tenant_name)
    end
  end

  def allow_access_credentials_in_cors
    response.set_header('Access-Control-Allow-Credentials', true)
    domain = request.scheme + '//' + request.host
  end

end