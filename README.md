

```ruby
api = Atores::Solarman::Request.new

hist = api.historical_data('62290994', (Date.today - 30.days),Date.today)

hist.stationDataItems.pluck(:generationValue).sum
```