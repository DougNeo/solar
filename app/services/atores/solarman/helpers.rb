require "digest"

module Atores
  module Solarman
    module Helpers
      private

      def credentials
        Rails.application.credentials.solarman
      end

      def password_encrypted
        Digest::SHA256.hexdigest(credentials.fetch(:password))
      end
    end
  end
end
