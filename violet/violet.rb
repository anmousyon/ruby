require 'socket'
require 'rarbg'
require 'sequel'
require 'filmbuff'

def main_setup
    rarbg = RARBG::API.new(
        'limit' => 1000,
        'sort' => 'seeders',
        'format' => 'json',
        'min_seeders' => 1
    )
    database = setup_database
    server = TCPServer.new('192.168.1.203', 2345)
    imdb = FilmBuff.new
    return rarbg, database, server, imdb
end

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

def find_best(database, movie, torrents, formats)
    for resolution in formats[:resolutions] do
        for encoding in formats[:encodings] do
            for format_type in formats[:format_types] do
                if good_enough(database, movie, torrents, resolution, encoding, format_type)
                    return true
                end
            end
        end
    end
    return false
end

def good_enough(database, movie, torrents, resolution, encoding, format_type)
    for torrent in torrents do
        if torrent['filename'].include? resolution and torrent['filename'].include? encoding and torrent['filename'].include? format_type
            puts movie.title + " :: " + torrent['filename']
            database.insert(
                :title => movie.title,
                :name => torrent['filename'],
                :label => movie.imdb_id,
                :magnet_link => torrent['download'],
                :downloaded => false
            )
            return true
        end
    end
    return false
end

def respond(socket, added)
    if added
        response = 'the movie has started downloading'
    else
        response = 'sorry but I cant find a bluray version of that one :/'
    end

    socket.print "HTTP/1.1 200 OK\r\n" + "Content-Type: text/plain\r\n" + "Content-Length: #{response.bytesize}\r\n" + "Connection: close\r\n"
    socket.print "\r\n"
    socket.print response
    socket.close

    return socket
end

def main
    rarbg, database, server, imdb = main_setup

    loop do
        #start a new thread for every request so it doesnt get clogged
        socket = server.accept
        #get id of movie to download from url
        imdb_id = (socket.gets)[5...-11]

        #formats: ordered best to worst
        formats = {
            :resolutions => ["1080", "720"],
            :encodings => ["X264", "x264", "H264", "h264"],
            :format_types => ['bluray', 'BluRay', 'BRRip']
        }

        #check that imdb_id is all numbers and is exactly 7 digits long
        if  not (imdb_id !~ /\D/ and imdb_id.length == 7)
            next
        end

        #search rarbg using imdb id
        torrents = rarbg.search_imdb(imdb_id)
        
        #search imdb using imdb id
        movie = imdb.look_up_id('tt' + imdb_id)

        #find best result and start download if successful
        added = find_best(database, movie, torrents, formats)

        #respond to request
        socket = respond(socket, added)

        #run python script to start download in qbittorrent
        python_script = `python2.7 violet.py`
    end
end

main()
