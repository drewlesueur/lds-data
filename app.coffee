config = require './config.coffee'
_ = require "underscore"
nimble = require "nimble"
_.mixin nimble
require("drews-mixins") _
https = require "https"

{s, wait, series} = _

log = (args...) -> console.log args... 

# reconnect 1 second after the connection closes

express = require('express')

drewsSignIn = (req, res, next) ->
  req.isSignedIn = () ->
    req.session.email isnt null
  next()

app = module.exports = express.createServer()
app.configure () ->
  app.use(express.bodyParser())
  app.use express.cookieParser()
  app.use express.session secret: "boom shaka laka"
  app.use(express.methodOverride())
  app.use(app.router)
  app.use(express.static(__dirname + '/public'))
  app.use drewsSignIn

app.configure 'development', () ->
  app.use(express.errorHandler({ dumpExceptions: true, showStack: true })) 

app.configure 'production', () ->
  app.use(express.errorHandler()) 


pg = (p, f) ->
  app.post p, f
  app.get p, f


  
lds = require "./lds.coffee"
console.log _.keys(lds)
username = config.lds.username
password = config.lds.password
lds.signIn username, password, ->
  lds.getJSON (err, json) ->
    console.log json

app.get "/drew", (req, res) ->
  res.send "aguzate, hazte valer"




pg "/p", (req, res) ->
  req.session.poo = "gotta"
  res.send "that is all"

pg "/whoami", (req, res) ->
  res.send req.session
  


exports.app = app

if (!module.parent) 
  app.listen config.server.port || 8001
  console.log("Express server listening on port %d", app.address().port)

