require 'socket'
require 'rarbg'
require 'sequel'

def setup_rarbg
    '''
    setup rarbg connection
    '''
    rarbg = RARBG::API.new

    rarbg.default_params
    rarbg.default_params['sort'] = 'seeders'
    rarbg.default_params['min_seeders'] = 1
    rarbg.default_params['format'] = 'json'
    rarbg.default_params['limit'] = 1000

    return rarbg
end

def search(rarbg, movie_id)
    '''
    search rarbg for movie
    input: movie id
    output: None
    '''
    rarbg.search_imdb(movie_id)
end

def setup_database
    '''
    setup the movie database
    input:
        None
    output:
        movie database
    '''
    db = Sequel.connect('sqlite://movies.db')

    db.create_table? :Movie do
        primary_key :id
        String :title
        String :magnet_link
        Boolean :downloaded
    end

    movie_db = db[:Movie]
    return movie_db
end

def check_wanted(movie_db, results, resolution, encoding)
    '''
    check search results for specified movie
    input:
        movie database
        search results
        resolution
        encoding
    output:
        boolean for success
    '''
    for res in results do
        if res['filename'].include? "bluray" or res['filename'].include? "BluRay" or res['filename'].include? "BRRip"
            if res['filename'].include? resolution and res['filename'].include? encoding
                puts 'inserting ' + res['filename']
                movie_db.insert(:title => res['filename'], :magnet_link => res['download'], :downloaded => false)
                return true
            end
        end
    end
    return false
end

def get_imdb_id(url)
    '''
    get id from url
    input:
        url
    output:
        imdb id
    '''
    movie_id = url[5...-11]
    return movie_id
end

def validate_id(movie_id)
    '''
    validate the id to be all numbers
    input:
        imdb id
    output:
        boolean for success
    '''
    if movie_id !~ /\D/
        return true
    else
        return false
    end
end

def main_setup
    '''
    setup everything needed
    input:
        None
    output:
        rarbg connection
        movie database
        server socket
    '''
    rarbg = setup_rarbg
    movie_db = setup_database
    server = TCPServer.new('47.184.15.16', 2345)
    return rarbg, movie_db, server
end

def respond(socket, result)
    '''
    respond to request
    input:
        server socket
        boolean for success
    output:
        None
    '''
    if result == true
        response = 'we got \'em'
    else
        response = 'sorry but I couldnt find it :/'
    end

    socket.print "HTTP/1.1 200 OK\r\n" + "Content-Type: text/plain\r\n" + "Content-Length: #{response.bytesize}\r\n" + "Connection: close\r\n"
    socket.print "\r\n"
    socket.print response
    socket.close

    return socket
end

def check_all(movie_db, results, resolutions, encodings)
    '''
    check search results for proper resolution and encodings
    input:
        imdb id
        search results
        wanted resolutions
        wanted encodings
    output:
        boolean for success
    '''
    for resolution in resolutions do
        for encoding in encodings do
            if check_wanted(movie_db, results, resolution, encoding)
                return true
            end
        end
    end
    return false
end

def main
    '''
    get movie id from imdb and check rarbg for movie to download and add to db
    input:
        None
    output:
        None
    '''
    rarbg, movie_db, server = main_setup

    loop do
        Thread.start(server.accept) do |socket|
            socket = server.accept

            movie_id = get_imdb_id(socket.gets)

            puts movie_id

            resolutions = ["1080", "720"]
            encodings = ["X264", "x264", "H264", "h264"]

            if validate_id(movie_id) == true
                results = search(rarbg, movie_id)
                socket = respond(socket, check_all(movie_db, results, resolutions, encodings))
            end
        end
    end
end

main()
