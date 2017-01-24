require 'Redd'
require 'sequel'
require 'sentimental'
require 'set'
require 'uri'

DB = Sequel.connect('sqlite://test.db')

def get_dbs()
    DB.create_table? :posts do
        String :id
        String :title
        Float :title_sentiment
        String :is_self
        String :selftext
        Float :selftext_sentiment
        String :domain
        String :subreddit
        String :user
        String :created
        String :edited
        Integer :karma
        Integer :gold
        String :link
    end

    DB.create_table? :comments do
        String :id
        String :body
        Float :body_sentiment
        String :user
        String :subreddit
        String :created
        String :edited
        Integer :karma
        Integer :gold
    end
    return DB[:posts], DB[:comments]
end

POSTS, COMMENTS = get_dbs()

def get_analyzer()
    # Create an instance for usage
    analyzer = Sentimental.new

    # Load the default sentiment dictionaries
    analyzer.load_defaults

    return analyzer
end

ANALYZER = get_analyzer()

def login()
    id = "-400hLn5ypKJhg"
    secret = "KuiYAJxYa1gqDBd4eg_Y-A3fuTw"
    r = Redd.it(:script, id, secret, "anmousyony", "b5!Rf7@Ee1^Dg2%D", user_agent: "emma v0.0.1 sentiment and machine learning analysis")
    r.authorize!
    return r
end

R = login()


def get_posts(subreddit)
    posts = R.get_hot(subreddit)
    return posts
end

def add_comment(comment)
    COMMENTS.insert(
        :id => comment.id,
        :body => comment.body,
        :body_sentiment => ANALYZER.score(comment.body),
        :user => comment.author,
        :subreddit => comment.subreddit,
        :created => comment.created,
        :edited => comment.edited,
        :karma => comment.score,
        :gold => comment.gilded,
    )
end

def dfs(comment, seen)
    if comment.respond_to? :id
        for reply in Set.new(comment.replies).subtract(seen) do
            if reply.respond_to? :id
                add_comment(reply)
                seen.add(reply)
                dfs(reply, seen)
            end
        end
    end
end

def add_post(post)
    POSTS.insert(
        :id => post.id,
        :title => post.title,
        :title_sentiment => ANALYZER.score(post.title),
        :is_self => post.self?,
        :selftext => post.selftext,
        :selftext_sentiment => ANALYZER.score(post.selftext),
        :domain => post.short_url,
        :subreddit => post.subreddit,
        :user => post.author,
        :created => post.created,
        :edited => post.edited,
        :karma => post.score,
        :gold => post.gilded,
        :link => post.permalink
    )

    comments = post.comments
    comments.each{ |comment| dfs(comment, Set.new([])) }
end

def main()
    new_posts = get_posts('all')
    new_posts.each { |post| add_post(post) }
    POSTS.each{ |post| p post }
    p "\n\n\n"
    COMMENTS.each{ |comment| p comment }
end

main()