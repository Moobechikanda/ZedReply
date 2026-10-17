# Confirms signup tokens outside /auth so OmniAuth cannot treat the request as a provider callback.
class Auth::ConfirmationsController < ActionController::API
  include AuthHelper

  def create
    user = User.find_by(confirmation_token: params[:confirmation_token])
    return render json: { message: 'Invalid or expired confirmation link' }, status: :unprocessable_entity unless user&.confirm

    send_auth_headers(user)
    render partial: 'devise/auth', formats: [:json], locals: { resource: user }
  end
end
