class SessionsController < ApplicationController
  MAX_ATTEMPTS = 5
  WINDOW = 15.minutes

  def new
    redirect_to root_path if current_user
  end

  def create
    key = "login-attempts/#{request.remote_ip}"
    attempts = Rails.cache.read(key).to_i
    return redirect_to(login_path, alert: "Muitas tentativas. Tente novamente em 15 minutos.") if attempts >= MAX_ATTEMPTS

    user = User.find_by(email: params[:email].to_s.strip.downcase)
    if user&.authenticate(params[:password])
      reset_session
      session[:user_id] = user.id
      user.update_column(:last_login_at, Time.current)
      Rails.cache.delete(key)
      redirect_to root_path
    else
      Rails.cache.write(key, attempts + 1, expires_in: WINDOW)
      redirect_to login_path, alert: "E-mail ou senha inválidos."
    end
  end

  def destroy
    reset_session
    redirect_to login_path, notice: "Sessão encerrada."
  end
end
