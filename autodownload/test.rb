require 'rarbg'

rarbg = RARBG::API.new(
	'limit' => 1000,
	'sort' => 'seeders',
	'format' => 'json',
	'min_seeders' => 1
)

torrents = rarbg.search_imdb('tt2488496')

puts torrents[0]
