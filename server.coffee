##
# Main configuration.
#
##

sys                 = require 'util'
express             = require 'express'
path                = require 'path'
url                 = require 'url'
fs                  = require 'fs'
_                   = require 'underscore'
stylus              = require 'stylus'
nib                 = require 'nib'
Settings            = require 'settings'
formidable          = require 'formidable'
PostSystem          = require './server-lib/post-system'
Validator           = require('validator').Validator
settings            = new Settings(path.join __dirname, 'config/environment.js').getEnvironment()

key                 = settings.key
certificate         = settings.certificate
service             = require './util/service'

generateResponse    = service.generateResponse
logger              = service.logger

PostItem            = service.PostItem
Photo               = service.Photo
User                = service.User
LoginToken          = service.LoginToken


postSystem          = new PostSystem()
 
Validator::error = (msg)-> this._errors.push(msg);
Validator::getErrors = ()-> return this._errors;

####################################################################################################
#
# Setup Express server for serving pages.
#
################################################################################################### 

app = express.createServer(
    #    (req, res) ->
    #uri             = url.parse(req.url).pathname
    #filename        = path.join(process.cwd(), uri)
    #
    #path.exists(filename, (exists) ->
    #    if !exists 
    #        res.writeHead(404, {"Content-Type": "text/plain"});
    #        res.write("404 Not Found\n")
    #        res.end()
    #        return
    #    filename += 'index.html' if fs.statSync(filename).isDirectory()
    #    
    #    fs.readFile(filename, "binary", (err, file) ->
    #        if err        
    #            res.writeHead(500, {"Content-Type": "text/plain"});
    #            res.write(err + "\n")
    #            res.end()
    #            return
    #        res.writeHead(200)
    #        res.write(file, "binary")
    #        res.end())
    #)
)##({key: key, cert: certificate})

#set helper libraries
app.helpers(require('./util/helpers.js').helpers)
app.dynamicHelpers(require('./util/helpers.js').dynamicHelpers)

#Error handling
NotFound = (@msg) ->
  @name = 'NotFound'
  Error.call(this, @msg)
  Error.captureStackTrace(this, arguments.callee)

sys.inherits(NotFound, Error);

app.error((err, req, res, next) ->
  if (err instanceof NotFound)
    res.render('404.jade', {
      locals: {
        status: 404
      }
    })
  
    next(err)
)

app.error((err, req, res) -> 
  res.render('500.jade', {
    locals: {
      status: 500,
      error: err
    }
  })
)

##
# We have to instantiate the sessionStore here since putting it in the settings would throw wrong object type error.
##
sessionStore = new settings.mongoSessionStore(settings.sessionDBOptions)
app.error((err, req, res, next) ->
    console.error(err);
    res.send('Fail Whale, yo.' + err)
)

app.configure ->
  app.use express.errorHandler settings.errorHandling
  app.use express.static settings.publicDir, maxAge: settings.staticMaxAge
  app.use express.bodyParser()
  app.use express.cookieParser maxAge: settings.cookieMaxAge
  app.use express.session({secret: settings.cookieSecret, maxAge: new Date(Date.now() + 3600000), store: sessionStore})
  app.set('views', __dirname + '/views')
  app.set('view engine', 'jade')
  app.set('view options', {layout: false})
  app.use stylus.middleware
    debug: true
    force: true
    src: __dirname + '/views'
    dest: __dirname + '/public'
    compile: (str, path) ->
      return stylus(str).set('filename', path).set('compress', true).use(nib())
  app.use(express.static(__dirname + '/public'))
  app.use(app.router)
  app.use('/', express.errorHandler({ dump: true, stack: true }))

##
# TODO serve up the postitem queries
##

app.get '/postitem/:id',
  (req, res) ->
      ##TODO error handling.
      PostItem.findOne({ id: req.params.id }, 
          (err, postItem) ->
              console.log err if (err)
              console.log '/postitem is called'
              console.log postItems
              res.render("postitem", { "postItem": postItem})
      )

app.get '/category/:country/:state/:city/',
  (req, res) ->  
      result = null
      await service.getCategories service.db, defer result
      res.send result

app.get '/category/total/:country/:state/:city/',
  (req, res) ->
      categories = null
      await service.getCategoriesWithTotal service.db, defer categories
      #TODO take care of the error. 
      console.log "result is null" if categories is null
      res.send categories
      
##
# Static page for search indexing.
##
app.get '/page/:name/',
    (req, res) ->
        res.render req.params.name

app.get '/post',
    (req, res) ->
        postitem = new PostItem()
        res.render 'posts',{categories:postitem.schema.paths.category.enumValues}
        
app.get '/',
    (req, res) ->
        ##
        # TODO We check if the req has a session and/or loginToken. If yes, then set logged in veriable to true.
        # We need to check if the token has expired.
        ##        
        session  = req?.session?.id          
        console.log session
        loggedin = false    
        tok = err = t = null
        categories = null                                 
        await service.getCategories service.db, defer categories 
        token = req?.cookies?.logintoken
        if token
            token = JSON.parse(token)
            await service.LoginToken.findOne { "token": token.token, "series": token.series, "username": token.username }, defer err, token$
            if token$
                loggedin = true
                loginToken = new service.LoginToken({ username: token$?.username, rememberme: token$?.rememberme })
                await loginToken.save defer err, token$$ 
                if token$$
                    token$.remove()
                    token = token$$
                else
                    token = ""
            else
                #The token has already changed and not in the system, so return "" for token.
                token = ""
            res.render('index', {
                "categories": categories                                                                                  
                "loggedin": loggedin
                "user_id": token?.username
                "session": session
                "token": JSON.stringify(token)
            })
        else
            res.render('index', {
                "categories": categories                                                                                  
                "loggedin": false
                "user_id": ""
                "session": ""
                "token": ""
            }) 

app.post "/api/postitem/", 
    (req, res) ->
        console.log req
        res.send generateResponse("success", "success", null, null)

app.post "/validateForm", 
    (req, res) ->
      data=req.body
      result = ''
      validator = new Validator()
      validator.check(data.title,'title').notEmpty()
      validator.check(data.itemDescription,'itemDescription').notEmpty()
      validator.check(data.neighborhood,'neighborhood').notEmpty()
      validator.check(data.city,'city').notEmpty()
      validator.check(data.state,'state').notEmpty()
      validator.check(data.country,'country').notEmpty()
      validator.check(data.email,'email').isEmail()
      validator.check(data.price,'price').isDecimal()

      errors = validator.getErrors()
      if errors.length>0 
        result+=','+error for error in errors
        result= result.substring 1
      res.writeHead 200, {'content-type': 'text/plain'} 
      res.write result
      res.end()

app.post "/post", 
    (req, res) ->
      form = new formidable.IncomingForm()
      form.uploadDir = './public/data'
      form.keepExtensions = false
      files  = {}
      fields = {}
      _this=this

      form.addListener 'progress',
           (recvd, expected) ->
             progress = (recvd / expected * 100).toFixed(2)

      form.on 'field',
           (field, value) ->
             fields[field]=value
          .on 'file',
           (field, file) ->
             files[field]=file
          .on 'end',
           ->
             item = 
              'fields' : fields
              'files' : files

             #console.log item
             postSystem.add item 
             categoryEnum = new PostItem()
             res.render 'posts',{success:'Please, wait for email to confirm this posting process.',categories:categoryEnum.schema.paths.category.enumValues}
      form.parse req


app.listen 7575

####################################################################################################
#
# Setup Socket.IO server for websocket interaction.
#
###################################################################################################  

#io = require("socket.io").listen(7172)

#io.sockets.on("connection", (socket) -> 
#    console.log "connection happening"
#    socket.emit("Welcome", { message: "Welcome" })
#)

