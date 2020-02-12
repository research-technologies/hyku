class API::V1::SessionsController < API::V1::ApiBaseController

  def create
    user = User.find_for_database_authentication(email: session_params[:email])
    if user && user.valid_password?(session_params[:password])
      token = payload(user)
      expire = session_params[:expire].try(:hour).try(:from_now) || 1.hour.from_now
      response.set_cookie(
        :jwt,
          {
            value: token, expires: expire, path: '/',
            domain: ('.' + request.host), secure: true, httponly: true
        }
      )
      render json: user.slice(:email)
    else
      message = 'Please check that email or password is not wrong'
      error_object = Ubiquity::ApiError::NotFound.new(status: 401, code: 'Invalid credentials', message: message)
      render json: error_object.error_hash
    end
  end

  def destroy
    head :ok
  end

  def refresh
    if current_user.present?
      token = payload(current_user)
      render json: current_user.slice(:email).merge(token: token)
    else
      message = 'This is not a valid token, inorder to refresh you must send back a valid token or you must re-log in'
      error_object = Ubiquity::ApiError::NotFound.new(status: 401, code: 'Invalid credentials', message: message)
      render json: error_object.error_hash
    end
  end

  private

  def session_params
    params.permit(:email, :password, :expire)
  end

  def payload(user)
    expire =  session_params[:expire]
    if expire.present?
      @auth_token = Ubiquity::Api::JwtGenerator.encode({id: user.id, exp: (Time.now + expire.to_i.hours).to_i})
    else
      @auth_token = Ubiquity::Api::JwtGenerator.encode({id: user.id})
    end
  end

end
