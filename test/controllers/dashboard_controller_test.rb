require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "viewer@example.com", password: "uma-senha-bem-segura")
    @plant = Plant.create!(plant_id: "dashboard-plant", name: "Usina Casa", installed_capacity: 5,
      current_power_kw: 2.5, daily_energy_kwh: 12, last_synced_at: 10.minutes.ago)
    post login_path, params: { email: @user.email, password: "uma-senha-bem-segura" }
  end

  test "renders local data without optional consumption metrics" do
    Rails.cache.write("plant/#{@plant.id}/current", :fresh, expires_in: 2.minutes)
    get root_path
    assert_response :success
    assert_select "h1", { count: 0, text: "Nenhuma usina sincronizada" }
    assert_includes response.body, "Usina Casa"
    refute_includes response.body, "Consumo"
  end

  test "marks cached local data as stale during an outage" do
    Rails.cache.write("plant/#{@plant.id}/current", :stale, expires_in: 2.minutes)
    get root_path
    assert_response :success
    assert_includes response.body, "Exibindo os últimos dados salvos"
  end
end
