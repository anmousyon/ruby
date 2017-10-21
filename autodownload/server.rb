require 'sinatra'
require 'rarbg'
require 'sequel'
require 'filmbuff'

set :port, 9494

rarbg = RARBG::API.new(
    'limit' => 1000,
    'sort' => 'seeders',
    'format' => 'json',
    'min_seeders' => 1
)
database = setup_database
imdb = FilmBuff.new

def setup_database
    db = Sequel.connect('sqlite://movies.db')

    #create table if it doesnt already exist
    db.create_table? :Movie do
        primary_key :id
        String :title
        String :name
        String :label
        String :magnet_link
        Boolean :downloaded
    end

    return db[:Movie]
end



post '/download/:imdb_id' do
    if validateid(:imdb_id) do
        info = imdbsearch(:imdb_id)
        trnt = rarbgsearch(:imdb_id)
        if trnt != nil
            categories = trnt['category'].split("/")
            database.insert(
                :title => info.title,
                :name => trnt['filename'],
                :label => :imdb_id,
                :magnet_link => trnt['download'],
                :downloaded => false,
                :format => categories[1],
                :resolution => categories[2]
            )
            return 'Success! Now downloading '
        end
        return "Sorry, but I couldn\'t find the torrent on rarbg\nAre you sure its been released on bluray?"
    end
    return "I couldn\'t get an IMDB id for a movie from the url.\nIs this an IMDB page for a movie?"
end

get '/active' do
    'downloading torrents'
end

get '/done' do
    'finished torrents'
end

get '/delete/:imdb_id' do
    @imdb_id = :imdb_id
    'deleted torrent x'
end

def validateid(imdb_id)
    if  not (imdb_id !~ /\D/ and imdb_id.length == 7)
        return false
    end
    return true
end

def imdbsearch(imdb_id)
    info = imdb.look_up_id('tt' + imdb_id)
    # clean up info object
end

def rarbgsearch(imdb_id)
    torrents = rarbg.search_imdb(imdb_id)
    formats = {
        :resolutions => ["1080", "720"],
        :encodings => ["X264", "x264", "H264", "h264"],
        :format_types => ['bluray', 'BluRay', 'BRRip']
    }
    trnt = sortbest(formats, torrents)
    if trnt != nil 
        return trnt
    end
    return nil
end

def sortbest(fmts, torrents)
    for res in fmts[:res] do
        for enc in fmts[:enc] do
            for typ in fmts[:types] do
                trnt = okay(res, enc, typ, torrents)
                if trnt != nil
                    return trnt
                end
            end
        end
    end
    return nil
end

def okay(res, enc, typ, torrents) 
    name = 'filename'
    for trnt in torrents do
        if trnt[name].include? res and trnt[name].include? enc and trnt[name].include? typ
            puts movie.title + " :: " + torrent['filename']
            return trnt
        end
    end
    return nil
end