class SolarmanSync
  def initialize(api: Atores::Solarman::Request.new)
    @api = api
  end

  def plants!
    @api.stations.each do |remote|
      plant = Plant.find_or_initialize_by(plant_id: remote.id)
      plant.update!(name: remote.name, latitude: remote.latitude, longitude: remote.longitude, address: remote.address,
        installed_capacity: remote.installed_capacity, start_operating_time: remote.start_operating_time,
        metadata: remote.raw, last_synced_at: Time.current)
    end
  end

  def devices!(plant)
    @api.devices(plant.plant_id).each do |item|
      serial = item["deviceSn"] || item["sn"]
      next if serial.blank?
      device = plant.devices.find_or_initialize_by(serial: serial.to_s)
      device.update!(name: item["deviceName"] || item["name"], device_type: item["deviceType"],
        status: item["deviceState"] || item["status"], last_collected_at: Time.current,
        telemetry: device.telemetry.merge(item.compact))
    end
  end

  def history!(plant, through: Date.yesterday)
    cursor = ([ plant.start_operating_time&.to_date, plant.energy_readings.maximum(:recorded_on)&.next ].compact.max || through)
    while cursor <= through
      window_end = [ cursor + 29.days, through ].min
      @api.history(plant.plant_id, cursor, window_end).each do |reading|
        record = plant.energy_readings.find_or_initialize_by(recorded_on: reading.date)
        record.update!(generation_kwh: reading.generation_kwh, metrics: reading.raw)
      end
      cursor = window_end.next
    end
  end

  def alerts!(plant)
    @api.alerts(plant.plant_id).each do |item|
      external_id = item["alertId"] || item["id"]
      next if external_id.blank?
      device = Device.find_by(serial: (item["deviceSn"] || item["sn"]).to_s)
      alert = plant.alerts.find_or_initialize_by(external_id: external_id.to_s)
      detail = device ? safely { @api.alert_detail(device_sn: device.serial, alert_id: external_id) } : {}
      alert.update!(device:, title: item["alertName"] || item["name"], severity: item["level"] || item["severity"],
        status: item["status"], influence: detail["influence"], solution: detail["solution"],
        occurred_at: parse_time(item["alertTime"] || item["occurTime"]), metadata: item.merge(detail))
    end
  end

  def current!(plant)
    realtime = @api.real_time(plant.plant_id)
    plant.update!(current_power_kw: realtime["generationPower"], daily_energy_kwh: realtime["generationValue"],
      total_energy_kwh: realtime["generationTotal"], status: realtime["networkStatus"] || realtime["status"],
      metadata: plant.metadata.merge(realtime.compact), last_synced_at: Time.current)
    plant.devices.find_each do |device|
      data = @api.current_data(device.serial)
      device.update!(telemetry: normalize_parameters(data), status: data["deviceState"] || device.status, last_collected_at: Time.current)
    end
    plant
  end

  private

  def normalize_parameters(payload)
    Array(payload["dataList"]).to_h do |parameter|
      key = parameter["key"].presence || parameter["name"].to_s.parameterize(separator: "_")
      [ key, { "name" => parameter["name"], "value" => parameter["value"], "unit" => parameter["unit"] } ]
    end
  end

  def safely
    yield
  rescue Atores::Solarman::Error => error
    Rails.logger.warn("Detalhe de alerta indisponível: #{error.class}")
    {}
  end

  def parse_time(value)
    Time.zone.parse(value.to_s) if value.present?
  rescue ArgumentError
    nil
  end
end
