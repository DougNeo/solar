return if Rails.env.test? || ENV["SECRET_KEY_BASE_DUMMY"].present?

required = {
  "solarman.app_id" => Rails.application.credentials.dig(:solarman, :app_id),
  "solarman.app_secret" => Rails.application.credentials.dig(:solarman, :app_secret),
  "solarman.email" => Rails.application.credentials.dig(:solarman, :email),
  "solarman.password" => Rails.application.credentials.dig(:solarman, :password),
  "application.allowed_host" => Rails.application.credentials.dig(:application, :allowed_host),
  "admin.email" => Rails.application.credentials.dig(:admin, :email)
}

missing = required.filter_map { |name, value| name if value.blank? }
raise "Credenciais obrigatórias ausentes: #{missing.join(', ')}. Edite-as com `bin/rails credentials:edit`." if missing.any?
