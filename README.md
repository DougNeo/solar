

```ruby
api = Atores::Solarman::Request.new

hist = api.historical_data('62290994', '2024-11-11',Date.today)

hist.stationDataItems.pluck(:generationValue).sum
```