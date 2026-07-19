require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    User.delete_all
    @user = User.create!(email: "admin@example.com", password: "uma-senha-bem-segura")
  end

  test "requires authentication and logs in" do
    get root_path
    assert_redirected_to login_path
    post login_path, params: { email: @user.email, password: "uma-senha-bem-segura" }
    assert_redirected_to root_path
    follow_redirect!
    assert_response :success
  end

  test "rejects wrong password" do
    post login_path, params: { email: @user.email, password: "errada" }
    assert_redirected_to login_path
  end

  test "limits repeated failures" do
    5.times { post login_path, params: { email: @user.email, password: "errada" } }
    post login_path, params: { email: @user.email, password: "uma-senha-bem-segura" }
    assert_equal "Muitas tentativas. Tente novamente em 15 minutos.", flash[:alert]
  end
end
