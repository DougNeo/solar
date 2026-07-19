require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "normalizes email and hashes password" do
    user = User.create!(email: " ADMIN@Example.COM ", password: "uma-senha-bem-segura")
    assert_equal "admin@example.com", user.email
    assert user.authenticate("uma-senha-bem-segura")
    refute_equal "uma-senha-bem-segura", user.password_digest
  end
end
