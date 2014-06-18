every 1.day, at: '3:00 am' do
  rake 'orats:backup'
end

every 1.day, at: '4:00 am' do
  rake 'sitemap:refresh'
end