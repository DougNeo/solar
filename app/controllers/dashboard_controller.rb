class DashboardController < ApplicationController
  before_action :require_authentication

  def show
    @plants = Plant.order(:name)
    @plant = @plants.find_by(id: params[:plant_id]) || @plants.first
    return unless @plant

    refresh_current_data
    @readings = readings_for(@plant)
    @chart_data = @readings.map { |reading| [ reading.recorded_on, reading.generation_kwh.to_f ] }
    @month_energy = @plant.energy_readings.where(recorded_on: Time.zone.today.beginning_of_month..).sum(:generation_kwh)
    @total_energy = @plant.total_energy_kwh || @plant.energy_readings.sum(:generation_kwh)
    @alerts = @plant.alerts.includes(:device).recent_first.limit(20)
    @devices = @plant.devices.order(:name, :serial)
  end

  private

  def refresh_current_data
    result = Rails.cache.fetch("plant/#{@plant.id}/current", expires_in: 2.minutes) do
      SolarmanSync.new.current!(@plant)
      :fresh
    rescue Atores::Solarman::Error => error
      Rails.logger.warn("Dashboard usando dados locais: #{error.class}")
      :stale
    end
    @api_unavailable = result == :stale
  end

  def readings_for(plant)
    scope = plant.energy_readings.order(:recorded_on)
    case params[:period]
    when "30d" then scope.where(recorded_on: 29.days.ago.to_date..)
    when "12m" then scope.where(recorded_on: 12.months.ago.to_date..)
    when "custom"
      start_date = Date.iso8601(params[:start_date]) rescue 30.days.ago.to_date
      end_date = Date.iso8601(params[:end_date]) rescue Date.current
      scope.where(recorded_on: start_date..end_date)
    else scope.where(recorded_on: 6.days.ago.to_date..)
    end
  end
end
