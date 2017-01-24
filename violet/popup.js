var l=location;
var current_url = l.href;

var movie_id = current_url.substring(28);
var movie_id = movie_id.substring(0,7)

var new_url = "http://192.168.1.203:2345/" + movie_id;
l.href=new_url;