module Atores
  module Solarman
    module Helpers
      def password_encrypted
        Digest::SHA256.hexdigest(ENV["SOLARMAN_PASSWORD"])
      end
    end
  end
end
