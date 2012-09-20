
##
# Utility setup for different envs.
##

oneYear = 1000 * 60 * 60 * 24 * 365

connect                 = require 'connect'
mongo                   = require 'mongodb'
MongoStore              = require('connect-mongo')
RedisStore              = require('connect-redis')(connect)
dbOptions               = 
    { host: '127.0.0.1', port: 27017, collection: 'sessions', auto_reconnect: true, clear_interval: -1, db: 'sessions'}
fs                      = require("fs")

sslKey                  = fs.readFileSync('key/key.pem').toString()
sslCertificate          = fs.readFileSync('key/certificate.pem').toString()

exports.common          =
  mainURL               : 'http://listingserver.cloudapp.net:7575/'
  registrationURL       : 'http://listingserver.cloudapp.net:7575/'
  socketIOURL           : 'http://localhost:8080'
  socketIOMainChannel   : 'mainchannel'
  mainEmailAccount      : 'service@melisting.com'
  serverDBURL           : 'mongodb://localhost/db'
  registerDBURL         : 'mongodb://localhost/db'
  redisServer           : 'localhost'
  redisPort             : 6379
  mainPort              : 7575
  socketIOPort          : 8080
  cookieMaxAge          : oneYear
  publicDir             : 'public'
  cookieSecret          : 'wonderfullife'
  sessionKey            : 'shopme.sid'
  mongoSessionStore     : MongoStore
  redisSessionStore     : RedisStore
  sessionDBOptions      : dbOptions
  key                   : sslKey
  certificate           : sslCertificate
  mailServer            : 'smtp.gmail.com'
  mailUserAccount       : 'melistingDev@gmail.com'
  mailUserPassword      : 'passavee'
  mailServerSSLPort     : '465'
  youtubeUsername       : 'melistingDev@gmail.com'
  youtubePassword       : 'passavee'
  googleDevelopKey      : 'AI39si5m7rzuJiMhJM_yjqXt1V0jJlR-hhEvMQwyRFZnQ6rl6hIIfPxOIqVDwFCIfDkAbRaHxHI5dbP2cQaYuVF7moRRmdV9wA'  
  leafletApiKey         : '552ed20c2dcf46d49a048d782d8b37e6'
  postItemsPerPage      : 25
  paginationShowNumber  : 5
  
exports.development     = 
  staticMaxAge          : null
  errorHandling         :
    dumpExceptions      : true
    showStack           : true 
     
  watcherOptions: 
    compass:           'config/config.rb'
    verbose:           true
    package:           'config/jammit.yml'
    packageOut:        'public/js'
    paths:
      'server.coffee'           :                       {type: 'coffee', out: '.'}
      'util/**/*.coffee'        :                       {type: 'coffee', out: 'util'}
      'config/**/*.coffee'      :                       {type: 'coffee', out: 'config'}      
      'server-lib/**/*.coffee'  :                       {type: 'coffee', out: 'server-lib'}      
      'bootstrap/**/*.coffee'   :                       {type: 'coffee', out: 'compiled/bootstrap', package: true}
      'models/**/*.coffee'      :                       {type: 'coffee', out: 'compiled/models', package: true}
      'controllers/**/*.coffee' :                       {type: 'coffee', out: 'compiled/controllers', package: true}
      'views/**/*.coffee'       :                       {type: 'coffee', out: 'compiled/views', package: true}        
      'client-lib/**/*.coffee'  :                       {type: 'coffee', out: 'compiled/lib', package: true}
      'templates/**/*.*'        :                       {type: 'template', out: 'compiled/templates', package: true}      
      
exports.production  = 
  staticMaxAge:       oneYear
  errorHandling:      {}    

exports.test        = {}
