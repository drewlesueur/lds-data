# lots of this http code is ugly and non dry
# I couldn't find an http library that managed cookies, etc
# (like curl) so I wrote some raw copy paste stuff
# I also didn't want to use curl 

# is it fine to copy pase dependencies like this?
_ = require "underscore"
nimble = require "nimble"
_.mixin nimble
require("drews-mixins") _
https = require "https"

{s, wait, series} = _
log = (args...) -> console.log args... 
# https://code.lds.org/wsvn/wsvn/mobilemember/webos/trunk/app/service.js 

module.exports = do ->
  cookie = null

  self = {} 
  self.getCurrentUserUnit = (cb) -> getJSON '/directory/services/ludrs/mem/current-user-unitNo', cb
  self.getStakeUnits = (cb) -> getJSON '/directory/services/ludrs/unit/current-user-stake-wards', cb
  self.getStakeLeadership = (cb) -> getJSON '/directory/services/ludrs/unit/stake-leadership-positions', cb
  self.getUnitMembership = (unit, cb) ->
    getJSON '/directory/services/ludrs/mem/member-detaillist/#{unit}', cb
  self.getUnitLeadership = (unit, cb) ->
    getJSON '/directory/services/ludrs/1.1/unit/unit-leadershiplist/#{unit}', cb 
  self.getUnitLeadershipNew = (unit, cb) ->
    getJSON '/directory/services/ludrs/1.1/unit/unit-leadershiplist/#{unit}'
  self.getPhotoUrl = (unit, member, cb) ->
    getJSON '/directory/services/ludrs/photo/url/#{unit}/#{member}', cb 


  signIn = (username, password, callback) ->
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
        d()

    signInStep2 = (d) ->
      log "step 2"
      formData = "username=#{username}&password=#{password}"     
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
          d()
      req.write formData 
      req.end()  
    series [signInStep1, signInStep2], callback

  getJSON = (args..., d) ->
    [path] = args
    headers = 
      'Accept':'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
      'Accept-Charset':'ISO-8859-1,utf-8;q=0.7,*;q=0.3'
      'Accept-Encoding':'gzip,deflate,sdch'
      'Accept-Language':'en-US,en;q=0.8'
      'Connection':'keep-alive'
      Cookie: cookie
      'Host':'lds.org'
      'User-Agent':'Mozilla/5.0 (Windows NT 5.1) AppleWebKit/534.30 (KHTML, like Gecko) Chrome/12.0.742.91 Safari/534.30'
    req = https.get
      host:"lds.org"
      path: path or "/directory/services/ludrs/unit/current-user-units"
      headers: headers
    , (res) ->
      resp = ""
      res.on "data", (data) ->
        resp += data.toString()
      res.on "end", ->
        d null, resp
  ret =
    signIn: signIn
    getJSON: getJSON
    cookie: cookie
  return _.extend ret, self

