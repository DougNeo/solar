namespace :admin do
  desc "Cria ou altera a senha do administrador das Credentials"
  task password: :environment do
    email = Rails.application.credentials.dig(:admin, :email)
    abort "Defina admin.email nas Rails Credentials." if email.blank?
    password = STDIN.tty? ? $stdin.getpass("Nova senha: ") : ENV["ADMIN_PASSWORD"]
    confirmation = STDIN.tty? ? $stdin.getpass("Confirme a senha: ") : ENV["ADMIN_PASSWORD_CONFIRMATION"]
    abort "As senhas não coincidem ou têm menos de 12 caracteres." unless password == confirmation && password.to_s.length >= 12
    user = User.find_or_initialize_by(email: email)
    user.update!(password: password, password_confirmation: confirmation)
    puts "Senha do administrador #{email} atualizada."
  end
end

namespace :solar do
  desc "Sincroniza usinas, dispositivos, histórico e alertas agora"
  task sync: :environment do
    SyncPlantsJob.perform_now
    SyncHistoryJob.perform_now
    SyncAlertsJob.perform_now
  end
end
