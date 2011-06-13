config = require './config.coffee'
_ = require "underscore"
nimble = require "nimble"
_.mixin nimble
require("drews-mixins") _
https = require "https"
zombie = require "zombie"

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


# Routes
cookie = null
signInStep1 = (d) ->
  log "step 1"
  headers = 
    'Accept':'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
    'Accept-Charset':'ISO-8859-1,utf-8;q=0.7,*;q=0.3'
    'Accept-Encoding':'gzip,deflate,sdch'
    'Accept-Language':'en-US,en;q=0.8'
    'Connection':'keep-alive'
    #'Cookie':'s_ppv=38'
    'Host':'lds.org'
    'User-Agent':'Mozilla/5.0 (Windows NT 5.1) AppleWebKit/534.30 (KHTML, like Gecko) Chrome/12.0.742.91 Safari/534.30'
  req = https.get
    host:"lds.org"
    path:"/SSOSignIn/",
    headers: headers
  , (res) ->
    
    cookie = s(res.headers['set-cookie'], -1)[0]
    cookie = cookie.split(";")[0].split("=")
    cookie = "#{cookie[0]}=#{cookie[1]}"
    log "done step 1"
    d null, cookie

signInStep2 = (d) ->
  log "step 2"
  formData = "username=#{config.lds.username}&password=#{config.lds.password}"     
  headers = 
    'Accept':'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
    'Accept-Charset':'ISO-8859-1,utf-8;q=0.7,*;q=0.3'
    'Accept-Encoding':'gzip,deflate,sdch'
    'Accept-Language':'en-US,en;q=0.8'
    'Cache-Control':'max-age=0'
    'Connection':'keep-alive'
    'Content-Length': formData.length
    'Content-Type':'application/x-www-form-urlencoded'
    Cookie: cookie
    Host:'lds.org'
    Origin:'https://lds.org'
    Referer:'https://lds.org/SSOSignIn/'
    'User-Agent':'Mozilla/5.0 (Windows NT 5.1) AppleWebKit/534.30 (KHTML, like Gecko) Chrome/12.0.742.91 Safari/534.30'
  req = https.request
    host: "lds.org"
    port: 443
    path: "/login.html"
    method: "POST"
    headers: headers


  , (res) ->
    cookie = s(res.headers['set-cookie'], -1)[0]
    cookie = cookie.split(";")[0].split("=")
    cookie = "#{cookie[0]}=#{cookie[1]}"
    resp = ""
    res.on "data", (data) ->
      resp += data.toString()
    res.on "end", ->
      log "done step 2"
      d null, [res.headers, resp]
  req.write formData 
  req.end()  

    

getDoc = (d) ->
  log "step 3"
  headers = 
    'Accept':'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
    'Accept-Charset':'ISO-8859-1,utf-8;q=0.7,*;q=0.3'
    'Accept-Encoding':'gzip,deflate,sdch'
    'Accept-Language':'en-US,en;q=0.8'
    'Connection':'keep-alive'
    #'Cookie':'s_ppv=38'
    Cookie: cookie
    'Host':'lds.org'
    'User-Agent':'Mozilla/5.0 (Windows NT 5.1) AppleWebKit/534.30 (KHTML, like Gecko) Chrome/12.0.742.91 Safari/534.30'
  req = https.get
    host:"lds.org"
    path: "/directory/services/ludrs/unit/current-user-units"
    headers: headers
  , (res) ->
    resp = ""
    res.on "data", (data) ->
      resp += data.toString()
    res.on "end", ->
      log "done step 333"
      log resp
      d()

series [signInStep1, signInStep2, getDoc], (err, result) ->

tryZombie = ->
  browser = new zombie.Browser debug: true
  browser.runScripts = false

  browser.visit "http://google.com", (err) ->
    if err
      log "there was an error"
      log err
    else
      log browser.html()


  


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

