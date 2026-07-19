module DashboardHelper
  KNOWN_METRICS = {
    "P_DC" => "Potência DC", "P_AC" => "Potência AC", "U_AC" => "Tensão AC",
    "F_AC" => "Frequência", "T" => "Temperatura", "Etdy_ge0" => "Geração hoje"
  }.freeze

  def metric_label(key, value)
    KNOWN_METRICS[key] || value["name"].presence || key
  end

  def metric_value(value)
    [ value["value"], value["unit"] ].compact.join(" ")
  end

  def status_label(status)
    status.to_s.downcase.in?(%w[normal online 1]) ? "Online" : "Offline"
  end
end
