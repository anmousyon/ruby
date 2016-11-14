require 'Redd'
require 'sqlite3'


def login()
    id = "-400hLn5ypKJhg"
    secret = "KuiYAJxYa1gqDBd4eg_Y-A3fuTw"
    r = Redd.it(:script, id, secret, "anmousyony", "b5!Rf7@Ee1^Dg2%D", user_agent: "emma v0.0.1 sentiment and machine learning analysis")
    r.authorize!
    return r
end

def database()
    db = SQLite3::Database.new "test.db"
    row = db.execute <<-SQL
        create table posts (
            title text,
            author text
        );
    SQL
    return db
end

def main()
    r = login()
    db = database()
    hot = r.get_hot("all")
    hot.each { |link| puts "#{link.title} by /u/#{link.author}" }
    hot.each { |link| db.execute "insert into posts values(?,?)", link.title, link.author }
    db.execute( "select * from posts" ) do |row|
        p row
    end
end

main()