'''
scans database for movies to download
downloads movies in qbittorrent
'''

from qbittorrent import Client
from peewee import Model, TextField, BooleanField
from playhouse.sqlite_ext import SqliteExtDatabase


def setup_database(movie_database, movie):
    '''
    connect to database and create tables
    input: database
    output: None
    '''
    movie_database = SqliteExtDatabase('movies.db')
    movie_database.connect()
    movie_database.create_table(movie, safe=True)
    return movie_database


def setup_bittorrent():
    '''
    setup connection to bittorrent and login
    input: None
    output: bittorrent client connection
    '''
    bittorrent = Client('http://localhost:8080/')
    bittorrent.login('pavo', 'buffalo12')
    return bittorrent


def download_movies(bittorrent, movie_object):
    '''
    download all undownloaded movies in database
    input: bittorrent client connection
    output: None
    '''
    to_download = (movie_object.select().where(not movie_object.downloaded))
    for movie in to_download:
        print(movie.title)
        print(movie.name)
        bittorrent.download_from_link(movie.magnet_link)
        movie.downloaded = True
        movie.save()


def main():
    '''
    setup db, get connection to bittorrent, download movies
    input: None
    output: None
    '''
    movie_database = SqliteExtDatabase('movies.db')

    class Movie(Model):
        '''movie object for database'''
        title = TextField()
        name = TextField()
        label = TextField()
        magnet_link = TextField()
        downloaded = BooleanField()

        class Meta:
            '''set database for the model'''
            database = movie_database

    movie_database.connect()
    movie_database.create_table(Movie, safe=True)

    # datbase = setup_database(movie_database, Movie)
    bittorrent = setup_bittorrent()
    while True:
        download_movies(bittorrent, Movie)

main()
