require 'redd'
require 'sequel'
require 'Sentimental'
require 'set'

Db = Sequel.connect('sqlite://test.db')

def get_dbs()
    Db.create_table? :posts do
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
        Integer :score
        Integer :gold
        String :link
    end

    Db.create_table? :comments do
        String :id
        String :body
        Float :body_sentiment
        String :user
        String :subreddit
        String :created
        String :edited
        Integer :score
        Integer :gold
    end

    return Db[:posts], Db[:comments]
end

Posts, Comments = get_dbs()

class Reddit
    @@id = "-400hLn5ypKJhg"
    @@secret = "KuiYAJxYa1gqDBd4eg_Y-A3fuTw"
    @@username = "anmousyony"
    @@password = "b5!Rf7@Ee1^Dg2%D"
    @@user_agent = "ella v0.0.1 sentiment and machine learning analysis"
    def initialize
        @client = Redd.it(:script, @@id, @@secret, @@username, @@password, user_agent: @@user_agent)
        @client.authorize!
    end
    
    def get_client
        @client
    end 
end

class Subreddit < Reddit
    def initialize(name)
        @name = name
        @reddit = Reddit.new
    end

    def get_posts
        @submissions = @reddit.get_client.get_hot(@name)
    end

    def add_to_db
        for submission in @submissions do
            if submission.is_self?
                post = SelfPost.new(submission)
            else
                post = LinkPost.new(submission)
            end
            post.add_to_db
        end
    end
end

class Submission
    @@analyzer = Sentimental.new
    @@analyzer.load_defaults

    def initialize(submission)
        @id = submission.id
        @subreddit = submission.subreddit
        @user = submission.author
        @created = submission.created
        @edited = submission.edited
        @score = submission.score
        @gold = submission.gilded
    end

    def get_sentiment(text)
        @sentiment = @@analyzer.score(text)
    end

    def add_to_db
        raise NotImplementedError
    end
end

class Post < Submission
    def initialize(post)
        super(post)
        @title = post.title
        @title_sentiment = get_sentiment(post.title)
        @domain = post.short_url
        @link = post.short_url
        @comments = post.comments
    end

    def add_to_db
        Posts.insert(
            :id => @id,
            :title => @title,
            :title_sentiment => @title_sentiment,
            :is_self => @is_self,
            :selftext => @selftext,
            :selftext_sentiment => @selftext_sentiment,
            :domain => @domain,
            :subreddit => @subreddit,
            :user => @user,
            :created => @created,
            :edited => @edited,
            :score => @score,
            :gold => @gold,
            :link => @link
        )
        @comments.each{ |comment| add_comments_to_db(comment, Set.new([])) }
    end

    def add_comments_to_db(comment, seen)
        if comment.respond_to? :id
            for reply in Set.new(comment.replies).subtract(seen) do
                if reply.respond_to? :id
                    new = Comment.new(comment)
                    new.add_to_db
                    seen.add(reply)
                    add_comments_to_db(reply, seen)
                end
            end
        end
    end
end

class LinkPost < Post
    def initialize(post)
        super(post)
        @is_self = "False"
        @selftext = ""
        @selftext_sentiment = 0.0
    end
end

class SelfPost < Post
    def initialize(post)
        super(post)
        @is_self = "True"
        @selftext = post.selftext
        @selftext_sentiment = get_sentiment(post.selftext)
    end
end

class Comment < Submission
    def initialize(comment)
        super(comment)
        @body = comment.body
        @body_sentiment = get_sentiment(@body)
        @replies = comment.replies
    end

    def add_to_db
        Comments.insert(
            :id => @id,
            :body => @body,
            :body_sentiment => @body_sentiment,
            :subreddit => @subreddit,
            :user => @user,
            :created => @created,
            :edited => @edited,
            :score => @score,
            :gold => @gold,
        )
    end
end

def main()
    subreddit = Subreddit.new('all')
    subreddit.get_posts
    subreddit.add_to_db
    Posts.each { |post| p post }
    p "\n\n\n"
    Comments.each{ |comment| p comment }
end

main()    