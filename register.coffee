##
# This will be the ssl enabled server that provide registration service for the users.
#
##

express                   = require "express"
path                      = require "path"
_                         = require "underscore"
stylus                    = require "stylus"
nib                       = require "nib"
Settings                  = require "settings"
fs                        = require "fs"
formidable                = require "formidable"
url                       = require "url"
kybos                     = require "./util/Kybos"
random                    = kybos.Kybos()
settings                  = new Settings(path.join __dirname, "config/environment.js").getEnvironment()

key                       = settings.key
certificate               = settings.certificate
mainPort                  = settings.mainPort
socketIOPort              = settings.socketIOPort
socketIOMainChannel       = settings.socketIOMainChannel

service                   = require "./util/service" 
loadUser                  = service.loadUser
loadUserAjax              = service.loadUserAjax
generateUniqueId          = service.uniqueId
generateResponse          = service.generateResponse
logger                    = service.logger
mailer                    = service.mailer
capitalize                = service.capitalizeFirstLetters
transformToLocationString = transformToLocationString
mkdirs                    = service.mkdirs
LoginToken                = service.LoginToken
User                      = service.User
PostItem                  = service.PostItem
WishList                  = service.WishList
CityInfo                  = service.CityInfo
RegionInfo                = service.RegionInfo
CountryInfo               = service.CountryInfo
isMobilePhone             = service.isMobilePhone
UniqueLocation            = service.UniqueLocation
db                        = service.db 

Process                   = []
abortedFlag               = []

UploadPhoto               = require "./server-lib/uploadphoto" 
UploadVideo               = require "./server-lib/uploadvideo" 
UploadVoice               = require "./server-lib/uploadvoice"
checkupload               = require "./server-lib/checkupload"  
savefields                = require "./server-lib/savefields" 
postingSystem             = require "./server-lib/posting-system"

##
# Setup default folders /public/data/images, /public/data/voice/, /public/data/video/ if they do not exist.
##
# mkdirs "./public/data","0777", (err)->
#       if err
#         console.log err
#         console.log "can not create upload directory"

app                       = express.createServer() ##({key: key, cert: certificate})

app.dynamicHelpers({
  session: 
    (req, res) -> return req.session
})

##
# We have to instantiate the sessionStore here since putting it in the settings would throw wrong object type error.
# new settings.redisSessionStore({ maxAge: 300000 }) #
##
sessionStore              = new settings.mongoSessionStore(settings.sessionDBOptions)

app.configure ->
  app.use express.errorHandler settings.errorHandling
  app.use express.static settings.publicDir, maxAge: settings.staticMaxAge
  app.use express.bodyParser()
  app.use express.cookieParser maxAge: settings.cookieMaxAge
  app.use express.session({secret: settings.cookieSecret, maxAge: new Date(Date.now() + 3600000), store: sessionStore, key: settings.sessionKey})
  app.set("views", __dirname + "/views")
  app.set("view engine", "jade")
  app.set("view options", {layout: false})
  app.use stylus.middleware
    debug: true
    force: true
    src: __dirname + "/views"
    dest: __dirname + "/public"
    compile: (str, path) ->
      return stylus(str).set("filename", path).set("compress", true).use(nib())
  app.use(express.static(__dirname + "/public"))
  app.use(express.static(__dirname + "/templates"))
  app.use(app.router)
  delete express.bodyParser.parse['multipart/form-data'];

##
# The user is created with active status.
#
app.post "/api/register/", 
	(req, res) ->
    username       = req?.body?.username
    email          = req?.body?.email
    password       = req?.body?.password
    city           = req?.body?.city
    state          = city
    country        = req?.body?.country
    neighborhood   = req?.body?.neighborhood
    latitude       = req?.body?.latitude
    longitude      = req?.body?.longitude
    console.log username + " " + email + " " + city + " " + state + " " + country + " " + latitude + " " + longitude
    if username and email and password and city and state and country
          #If the city does have , in it, we split it and assign state to the second element.
          cityAndState  = city.split(",")
          if cityAndState.length is 2
                city    = cityAndState[0]
                state   = cityAndState[1]
          user          = new User({ "username": username, "email": email?.toLowerCase()
            , "password": password, "location": [parseFloat(longitude), parseFloat(latitude)]
            , "address": { "country" : capitalize(country), "state" : capitalize(state)
            , "city" : capitalize(city), "neighborhood" : capitalize(neighborhood) }
            , "role": "user", "status": "inactive"})
          console.log "user " + JSON.stringify(user)
          user.save((err, result) ->
              if err
                  res.send generateResponse("error", err.stack, null, null) 
              else
                  data = {
                      "username"      : user.email,
                      "link"          : settings.registrationURL + "/confirm/" + user._id
                  }               
                  mailer.sendWithTemplate(user.email, settings.mainEmailAccount, "MeListing Registration Confirmation", "registration-email-template.txt", data)  
                  logger.info  "sign up user success " + user.email
                  req.session.user      = user.email
                  session               = req.sessionID
                  user.hashedPassword   = generateUniqueId()
                  message               = """Your account has been created successfully. An email with an instruction to activate 
                                              your account is being sent out shortly."""
                  res.send generateResponse("success", message, user, session)
          )
    else
        res.send generateResponse("error", "The information provided for registration can not be empty.", null, null)

#check username availability
app.post "/api/checkUsernameAvailability/",
    (req, res) ->
        username    = req?.body?.username
        if username
            User.findOne({username: username},
                (err, user) ->
                    res.send generateResponse("error", "We are unable to check the username at the moment due to the server error.", null, null) if err
                    if (user)
                        res.send generateResponse("taken", "Username is already taken.", user, null)
                    else
                        res.send generateResponse("success", "The username is available for registration", null, null)
            )
        else
            res.send generateResponse("error", "The username provided can not be empty", null, null)

#check the email duplication
app.post "/api/checkEmailDuplication/",
    (req, res) ->
        email   = req?.body?.email
        if email
            User.findOne({ email: email },
                (err, user) ->
                    res.send generateResponse("error", "We are unable to check email duplication at the moment due to server error.", null, null) if err
                    if (user)
                        res.send generateResponse("duplicate", "The email is already found in the system.", user, null)
                    else
                        res.send generateResponse("success", "The email is not in the system.  The user is able register with the email", null, null)
            )
        else
            res.send generateResponse("error", "The email provided can not be empty", null, null)

#get valid email domains for suggestion.
app.get "/api/getAllValidEmailDomainNames/",
  (req, res) ->
    domainNames = ""
    await service.getAllValidEmailDomainNames service.db, defer domainNames
    #TODO take care of the error. 
    console.log "result is null" if domainNames is ""
    res.send domainNames

# logout user
app.post("/api/logout/", loadUserAjax, 
  (req, res) ->
    if (req.session)
      LoginToken.remove({ username: req.currentUser.username }, () -> {})
      res.clearCookie("logintoken")
      req.session.destroy(() -> {})
                                                                                            
    res.send generateResponse("success", "The user has successfully logged out.", null, null)
)

#login user
app.post "/api/login/", 
  (req, res) ->
      email       = req?.body?.email
      password    = req?.body?.password
      rememberMe  = if req?.body?.remember_me is "true" then true else false
      console.log email
      console.log password
      if email? != "" and password? != "" and typeof email != "undefined" and typeof password != "undefined"  
          User.findOne({ email: email, status: "active" }, 
              (err, user) ->
                  ##TODO take care of the error.
                  console.log err if err
                  if (user)
                      console.log "user lat " + user?.location?["0"]
                      if (user and user.authenticate(password))
                          req.session.userId = user.id
                          session = req.sessionID
                          address = user?.address
                          if (rememberMe)
                              loginToken = new LoginToken({ username: user?.username, rememberme: true
                                , address: { city: address?.city, state: address?.state, country: address?.country
                                , neighborhood: address?.neighborhood }
                                , location: [parseFloat(user?.location?["0"]), parseFloat(user?.location?["1"])]})
                              loginToken.save((err, token) ->
                                  #TODO take care of the err.
                                  console.log err if err
                                  if token
                                      ##It has to be inside as it needs to be executed after res.cookie
                                      res.send generateResponse("success", "Your account has been authenticated successfully.", token, session)
                                  else
                                      res.send generateResponse("error", "Error occurred while trying to save session token.", null, null)
                              )
                          else
                              loginToken = new LoginToken({ username: user.username, rememberme: false 
                                , address: { city: address?.city, state: address?.state, country: address?.country
                                , neighborhood: address?.neighborhood }
                                , location: [parseFloat(user?.location?["0"]), parseFloat(user?.location?["1"])]})
                              loginToken.save((err, token) ->
                                  console.log err if err
                                  if token
                                      ##It has to be inside as it needs to be executed after res.cookie
                                      res.send generateResponse("success", "Your account has been authenticated successfully.", token, session)
                                  else
                                      res.send generateResponse("error", "Error occurred while trying to save session token.", null, null)
                              ) 
                      else
                          res.send generateResponse("error", "Authentication Error - email or/and password are in incorrect.", null, null)
                  else
                     res.send generateResponse("error", "There is an error while trying to retrieve your account.  The account information provided is not found in the system.", null, null)
          )
      else
          res.send generateResponse("error", "The email and password passed in can not be empty", null, null)

 ##
 # Forgotten password and password setting URLs.
 ##              

 app.post "/api/resetpassword/:email",
  (req, res) ->
    if (req.params.email)
      User .findOne({email: req.params.email},
        (err, user) ->
          if (user)
            data = { "username": user.email, "link": settings.registrationURL + "/resetpassword/" + user.hashedPassword }
            mailer.sendWithTemplate(user.email, settings.mainEmailAccount, "MeListing Account Reset", "account-reset-email-template.txt", data)
            res.send generateResponse("success", "An email with the instruction to reset your account has been sent.", null, null)
          else
            res.send generateResponse("error", "There was an error resetting your account.  Account is not found.  Sorry for the inconvenience. Please contact the admin@melisting.com for assistance.", null, null)
      )
    else
      res.send generateResponse("error", "There is an error while trying to retrieve your account.", null, null)

##
# User register via the web.  An email confirmation is used to verify the user.
##
      
app.post "/register",
  (req, res) ->
    logger.info req.body.email
    if req.body.email and req.body.password 
      user = new User (req.body)
      logger.info user.email
      user.set("status", "inactive")
      user.set("role", "user")
      user.save((err)->
        if err
          logger.error err.stack
          logger.error service.interpretError(err)
          errorText = service.interpretError(err)
          errorText = "Email given already exists in the database." if errorText is "Duplicate Unique Key"
          res.render("register", {error: errorText, user: user})
        else
          logger.info user.email + " user is created"
          data = {
            "username"      : user.email,
            "link"          : settings.registrationURL + "/confirm/" + user._id
          }
          mailer.sendWithTemplate(user.email, settings.mainEmailAccount, "MeListing Registration Confirmation", "registration-email-template.txt", data)

          res.render "index"
      )
    else
      res.render("register", {error:"", user: ""})

app.get "/confirm/:id",
  (req, res) ->
    if req.params.id
      User.findOne({ _id: req.params.id }, 
        (err, user) ->
          if (user)
            user.status = "active"
            user.save((err) ->
              if err
                ##TODO deal with the error
              else
                ##sign in the user and bring him/her to the confirm page
                res.render("confirm", {message:"", user: user})
            )
          else 
            res.render("register", {error : "There was an error activating your account.  The key in the path link provided was either corrupted or misstyped.  Please try signing up again.  Sorry for the inconvinience. Please contact the admin@melisting.com if the problem persists.", user  : ""})
      )
    else
      res.render("register", {error : "You have requested a wrong page.  Please sign up to confirm your activation", user  : ""})

app.get "/resetpassword/:hashedPassword",
  (req, res) ->
    if req.params.hashedPassword
      User.findOne({ hashedPassword: req.params.hashedPassword }, 
        (err, user) ->
          if (user)
            user.status = "active"
            user.save((err) ->
              if err
                ##TODO deal with the error
                res.render("resetpassword", {error:"There is an error occurred while trying to save your new password.  Please try again later or contact admin@melisting.com for further assistance.", user: user})
              else
                ##resetting the password page
                res.render("resetpassword", {error:"", user: user})
            )
          else 
            res.render("register", {error : "There was an error trying to reset your account.  The key in the path link provided was either corrupted or misstyped.  Please try signing up again.  Sorry for the inconvinience. Please contact the admin@melisting.com if the problem persists.", user  : ""})
      )
    else
      res.render("register", {error : "You have requested a wrong page.  Please sign up to obtain new account", user  : ""})


app.post "/resetpassword",
  (req, res) ->
    if req.body.email and req.body.password 
      User.findOne({ email: req.body.email }, 
        (err, user) ->
          if (user)
            user.status   = "active"
            user.password = req.body.password
            user.save((err) ->
              if err
                ##TODO deal with the error
              else
                ##TODO resetting the confirm page
                res.render "index"
            )
          else
            res.render("register", {error : "There was an error trying to reset your account.  The key in the path link provided was either corrupted or misstyped.  Please try signing up again.  Sorry for the inconvinience. Please contact the admin@melisting.com if the problem persists.", user  : ""})
      )
    else
        res.render("register", {error : "There was an error trying to reset your account.  The key in the path link provided was either corrupted or misstyped.  Please try signing up again.  Sorry for the inconvinience. Please contact the admin@melisting.com if the problem persists.", user: ""})        
        
##
# The session store structure
# { lastAccess: 1320935137401,
#  cookie: 
#   { originalMaxAge: 14400000,
#     expires: "2011-11-10T18:25:37.402Z",
#     httpOnly: true,
#     path: "/" },
#  whatevervalue: 2 }
#
##

##
# Login routes
##
# render login form
app.get("/login/", 
  (req, res) ->
    #console.log sessionStore
    console.log req.cookies.session
    sessionStore.get(req.cookies.session, 
      (err, session) -> 
        if err
          console.log err
        else
          @session = session
          console.log "#########################################"
          console.log @session
    )
    res.send("session is valid " + req.session)
    #res.render("login", { locals: {user: new User ()}})
)

#login user
#app.post("/api/login/", 
#  (req, res) ->
#    User.findOne({ email: req.body.user.email }, 
#      (err, user) ->
#        if (user && user.authenticate(req.body.user.password))
#          req.session.userId = user.id
#          console.log "login user #{user}"
#          if (req.body.remember_me)
#            loginToken = new LoginToken({ email: user.email });
#            loginToken.save(
#              () ->
#                res.cookie("logintoken", loginToken.cookieValue, { expires: new Date(Date.now() + 2 * 604800000), path: "/" })
#            )
#          
#          res.redirect("/");
#        else
#          req.flash("error", "Login Error Occurred.");
#          res.redirect("/login")
#    )
#)

################################################################################################################################
# From server.coffee
# For some reasons the get api would not complete when we do cross domain request.
# Hence the post duplication is needed as a hack to get around the issue until the solution is found.
################################################################################################################################ 

app.get "/pages/postitem/:id",
  (req, res) ->
      ##TODO error handling.
      PostItem.findOne({ _id: req.params.id }, 
          (err, item) ->
              console.log err if (err)
              console.log "/postitem is called"
              # console.log item
              res.render("postitem", { "postitem": item})
      )

app.get "/api/category/:city/:state/:country/",
  (req, res) ->  
      result = ""
      await service.getCategories service.db, defer result
      #TODO take care of the error. 
      console.log "result is null" if categories is ""
      res.send result

app.get "/api/category/total/:city/:state/:country/",
  (req, res) ->
      categories = ""
      await service.getCategoriesWithTotal service.db, defer categories
      #TODO take care of the error. 
      console.log "result is null" if categories is ""
      res.send categories

app.get "/api/getCategories/",
  (req, res) ->  
      categories = ""
      # console.log "getCategories"
      await service.getCategories service.db, defer categories
      #TODO take care of the error. 
      console.log "result is null" if categories is ""
      res.send categories

app.get "/api/getCategoriesWithTotal/",
  (req, res) ->  
      categories = ""
      await service.getCategoriesWithTotal service.db, defer categories
      #TODO take care of the error. 
      console.log "result is null" if categories is ""
      res.send categories

app.post "/api/category/:city/:state/:country/",
  (req, res) ->  
      result = ""
      await service.getCategories service.db, defer result
      #TODO take care of the error. 
      console.log "result is null" if categories is ""
      res.send result

app.post "/api/category/total/:city/:state/:country/",
  (req, res) ->
      categories = ""
      await service.getCategoriesWithTotal service.db, defer categories
      #TODO take care of the error. 
      console.log "result is null" if categories is ""
      res.send categories

app.post "/api/getCategories/",
  (req, res) ->  
      categories = ""
      # console.log "getCategories"
      await service.getCategories service.db, defer categories
      #TODO take care of the error. 
      console.log "result is null" if categories is ""
      res.send categories

app.post "/api/getCategoriesWithTotal/",
  (req, res) ->  
      categories = ""
      await service.getCategoriesWithTotal service.db, defer categories
      #TODO take care of the error. 
      console.log "result is null" if categories is ""
      res.send categories

################################################################################################################################
# Default index request.
################################################################################################################################ 

app.get "/",
    (req, res) ->
        ua          = req.headers['user-agent'].toLowerCase()
        session     = req?.session?.id        
        loggedin    = false    
        token$      = token$$ = err = null
        categories  = categoriesWithTotal = null  
        await service.getCategoriesWithTotal service.db, defer categoriesWithTotal
        categories  = Object.keys(categoriesWithTotal)
        ##
        # Check if it is mobile phone.  If yes, send res to mobile page.
        # Test string is from: http://detectmobilebrowsers.com/.
        ##
        if isMobilePhone(ua)
          res.render("mobile", {
              "categories": categories
              "categoriesWithTotal": categoriesWithTotal
          })
        else    
          token       = req?.cookies?.logintoken
          if token
              console.log "token " + token
              token   = JSON.parse(token)
              await LoginToken.findOne { username: token.username }, defer err, token$
              #TODO take care of the err.
              console.log err if err
              if token$
                  console.log "found token$ " + token$.username
                  loggedin = true
                  loginToken = new LoginToken({ username: token$?.username, rememberme: true
                    , address: { city: token$?.address?.city, state: token$?.address?.state, country: token$?.address?.country
                    , neighborhood: token$?.address?.neighborhood }
                    , location: [parseFloat(token$?.location?["0"]), parseFloat(token$?.location?["1"])]})

                  await loginToken.save defer err, token$$
                  ##TODO check the err and take care of it.
                  console.log err if err
                  if token$$
                      token$.remove()
                      token = token$$
                  else
                      token = ""
              else
                  console.log "not found token$ "
                  #The token has already changed and not in the system, so return "" for token.
                  token = ""
              res.render("index", {
                  "categories": categories                                                                                  
                  "loggedin": loggedin
                  "username": token?.username
                  "session": session
                  "token": JSON.stringify(token)
              })
          else
              console.log "token no token " + token
              res.render("index", {
                  "categories": categories                                                                                  
                  "loggedin": false
                  "username": ""
                  "session": ""
                  "token": ""
              }) 

#################################################################################
# Setup post item query code. 
################################################################################# 
# TODO setup the query for retrieving postitems and take care of the err.
# TODO we return all of the relevant info for this user - postitems, user profile object, wishlist.
# TODO delete sensitive user info before sending it over the wire.!!!
# the format will be {user: {user object}, postitems: [{postitem objects}, wishlist: {wishlist objects}]}
app.get "/api/alluserinfo/:username/",
  (req, res) ->
    postitems = wishlist = user   = error = ""
    username                      = req.params.username
    if username
      await PostItem.find { username: username }, defer err, postitems
      if err
        console.log err
        error                   = error.concat(err)
      await WishList.find { username: username }, defer err, wislist
      if err
        console.log err
        error                   = error.concat(", ").concat(err)
      await User.findOne { username: username }, defer err, user
      if err
        console.log err
        error                   = error.concat(", ").concat(err)
    if error
      res.send generateResponse("error", "User info query encounter error: " + error, null, null)
    else
      result                    = {}
      postitemMap               = {}
      wishlistMap               = {}
      if wishlist
        wishlistMap[postitem.id]  = postitem for postitem in wishlist.postitem 
      if postitems
        postitemMap[postitem.id]  = postitem for postitem in postitems
      result["user"]            = user; result["postitemMap"] = postitemMap; result["wishlist"] = wishlistMap
      res.send generateResponse("success", "User info query was successfully.", result, {})

app.get "/api/postitems/:username/",
  (req, res) ->  
    PostItem.find({}, 
          (err, postitems) ->
              #TODO take care of the error.
              res.send err if (err)
              console.log "/postitem is called"
              console.log postitems
              result              = {}
              result[postitem.id] = postitem for postitem in postitems
              res.send generateResponse("success", "PostItems query by username.", result, {}) 
    )

app.get "/api/postitems/:city/:state/:country/",
  (req, res) ->  
    PostItem.find({}, 
          (err, postitems) ->
              #TODO take care of the error.
              res.send err if (err)
              console.log "/postitem is called"
              console.log postitems
              result              = {}
              result[postitem.id] = postitem for postitem in postitems
              res.send generateResponse("success", "PostItems query by city, state.", result, {}) 
    )

#################################################################################
# Setup wish list item query code. 
# We return just the array of postitems.
################################################################################# 
app.get "/api/wishlist/:username/",
  (req, res) ->  
    console.log "wishlist"
    WishList.find({username: req.params.username}, 
          (err, wishlist) ->
              #TODO take care of the error.
              res.send err if err
              res.send generateResponse("success", "Array of wishlist by the user.", wishlist, {})
    )

app.delete "/api/wishlist/:id/",
  (req, res) -> 
    wishlistID = req.params.id 
    console.log "wishlist delete"
    WishList.findById(wishlistID, (err, wishlist) ->
      if err
        #TODO take care of the error.
        console.log "err " + err 
        res.send generateResponse("error", "Remove WishList fail. " + err, wishlistID, {})
      else
        wishlist.remove()
        res.send generateResponse("success", "Remove WishList successfully.", wishlistID, {})
    )
#################################################################################
# Setup upload processing code. 
################################################################################# 

app.get "/api/getProcessID/",
  (req, res) ->  
    result = random.uint32().toString()
    res.send result     

app.get "/api/uploadStatus/:processId/",
  (req, res) ->  
    processId = req.params.processId
    res.send Process[processId]  

app.post("/api/abortPosting/", 
  (req, res) ->
    processId = req.body.processId
    if processId isnt "" and abortedFlag[processId] isnt undefined
      abortedFlag[processId] = true;
      res.send generateResponse("success", "The posting is aborted.", null, null)
    else
      res.send generateResponse("success", "The posting id given is not found.", null, null)
)



app.post "/api/postitem/:processId/", 
    (req, res) ->
      service.addPostingItem req, res, abortedFlag, Process

app.post "api/savephotos/:processId",
    (req, res) ->
      service.saveUploadData req, res, abortedFlag, Process, "photo"

app.post "api/savevoice/:processId",
    (req, res) ->
      service.saveUploadData req, res, abortedFlag, Process, "voice"

app.post "api/savevideo/:processId",
    (req, res) ->
      service.saveUploadData req, res, abortedFlag, Process, "video"

app.post "api/deletephoto/:processId",
    (req, res) ->
      service.deletePhoto req, res, abortedFlag, Process

app.post "api/deletevoice/:processId",
    (req, res) ->
      service.deleteVoice req, res, abortedFlag, Process

app.post "api/deletevideo/:processId",
    (req, res) ->
      service.deleteVideo req, res, abortedFlag, Process
###
app.post "/api/editpostitem/:processId/", 
    (req, res) ->
      processId = req.params.processId
      abortedFlag[processId] = false;
      form = new formidable.IncomingForm()
      form.uploadDir = "./public/data"
      form.keepExtensions = false
      aborted = false
      beginfiles  = []
      overSizeFile = []
      files  = {}
      fields = {}
      _this=this

      form.addListener "progress",
           (recvd, expected) ->
             progress = (recvd / expected * 100).toFixed(2)
             Process[processId] = progress
      form.on "aborted", ()->
              abortedFlag[processId] = undefined
              for file in beginfiles
                fs.unlink(file.path)
              logger.log "info", " (Posting module) The posting id : "+processId+" is aborted by user"
              res.send generateResponse "abort", "The posting is aborted by user", null, null 
          .on "fileBegin",
           (name, file) ->
              
              beginfiles.push file
          .on "error" ,
           (err) ->
              res.send generateResponse "error", err, null, null 
          .on "field",
           (field, value) ->
              if fields[field] is undefined
                fields[field]=value
              else
                if typeof fields[field] is "string"
                  fields[field] = [].concat( fields[field] );
                  fields[field].push value
                else
                  fields[field].push value

          .on "file",
           (field, file) ->
              if(file.type.split("/")[0] is "image")
                if file.size > 2500000
                  abortedFlag[processId]=true
                  overSizeFile.push field
                else
                  files["photoFile"+photoNumber]=file
                  photoNumber++

              else if(file.type.split("/")[0] is "audio")
                if file.size > 10000000
                  abortedFlag[processId]=true
                  overSizeFile.push field
                else
                  files[field]=file
              else if(file.type.split("/")[0] is "video")
                if file.size > 10000000
                  abortedFlag[processId]=true
                  overSizeFile.push field
                else 
                  files[field]=file
          .on "end",
           ->
              item = 
                      "fields" : fields
                      "files" : files
              item.processId = processId;
              item._id = item.fields.id;
              item.photoId = item.fields.photoId;
              item.processType = item.fields.processType
              postitem = undefined
              await PostItem.findOne {_id:item._id,status:"published"}, defer err,postitem
              if !abortedFlag[processId] and postitem
                abortedFlag[processId] = undefined

                if item.fields.fileType is "photo"
                  if item.processType is "delete"
                    item.files.photoFile0 = "none"
                    numberOfPhotos = postitem.numberOfPhotos
                    numberOfPhotos--
                    postitem.set 'numberOfPhotos',numberOfPhotos
                  else
                    numberOfPhotos = postitem.numberOfPhotos
                    numberOfPhotos++
                    postitem.set 'numberOfPhotos',numberOfPhotos
                  await postitem.save defer err
                  if err
                    res.send generateResponse "error", "the post item is not available or published", null, null 
                  else
                    postingJob.publish JSON.stringify(item) , (err, data, id)->
                        logger.log "info", " (Posting module) Add process id "+processId+" to Posting system" 
                    ,false, item.processId
                    res.send generateResponse "success", "add the post item to process successfully", null, null 
        
                else if item.fields.fileType is "voice"
                  if item.processType is "delete" then item.files.voiceFile = "none"
                  postitem.set 'isVoiceProcessing',true
                  await postitem.save defer err
                  if err
                    res.send generateResponse "error", "the post item is not available or published", null, null 
                  else
                    postingJob.publish JSON.stringify(item) , (err, data, id)->
                        logger.log "info", " (Posting module) Add process id "+processId+" to Posting system" 
                    ,false, item.processId
                    res.send generateResponse "success", "add the post item to process successfully", null, null 
                  
                else if item.fields.fileType is "video"
                  if item.processType is "delete" then item.files.videoFile = "none"
                  postitem.set 'isVideoProcessing',true
                  await postitem.save defer err
                  if err
                    res.send generateResponse "error", "the post item is not available or published", null, null 
                  else
                    postingJob.publish JSON.stringify(item) , (err, data, id)->
                      logger.log "info", " (Posting module) Add process id "+processId+" to Posting system" 
                    ,false, item.processId
                    res.send generateResponse "success", "add the post item to process successfully", null, null 
                  
              else
                for file in beginfiles
                  fs.unlink(file.path)
                abortedFlag[processId] = undefined
                if postitem
                  if overSizeFile.length > 0
                    message=""
                    for file in overSizeFile
                      message+=file+","
                    logger.log "info", " (Posting module) The posting id : "+processId+" is aborted because oversize file" 
                    res.send generateResponse "oversize", message, null, null  
                  else
                    logger.log "info", " (Posting module) The posting id : "+processId+" is aborted by user"
                    res.send generateResponse "abort", "The posting is aborted by user", null, null 
                else
                  logger.log "info", " (Posting module) The posting id : "+processId+" is aborted because the item is not available"
                  res.send generateResponse "abort", "the item is not available", null, null 


      form.parse req
###
#################################################################################
# Setup directory code. 
################################################################################# 

app.get("/pages/directory/:listby/:alphabet/:sort/:page", 
  (req, res) ->
    page      = req.params.page
    listby    = req.params.listby
    alphabet  = req.params.alphabet
    sort      = 1

    if req.params.sort is "desc"
      sort = -1 

    AToZ = []
    AToZ.push "all"
    a = ("a").charCodeAt(0)
    z = ("z").charCodeAt(0)
    for character in [a..z]
        AToZ.push String.fromCharCode character 

    rows = []
    users = undefined
    numberOfPages = undefined
    await service.getUserPostingTotal service.db,alphabet,sort,page, defer users,numberOfPages
    if listby is "username"
      for username of users
          row = {}
          row.username = username
          row.location = users[username].location
          row.numOfItem = users[username].numberOfPosting
          rows.push row

    else if listby is "location" 
      for username of users
          row = {}
          row.username = username
          row.location = users[username].location
          row.numOfItem = users[username].numberOfPosting
          rows.push row
      if sort is 1
          rows.sort (a, b)->
            if  a.location.toLowerCase() < b.location.toLowerCase() 
              return -1 
            if  a.location.toLowerCase() > b.location.toLowerCase() 
              return 1
            return 0

    else if listby is "number" 
      for username of users
          row = {}
          row.username = username
          row.location = users[username].location
          row.numOfItem = users[username].numberOfPosting
          rows.push row
      if sort is 1
          rows.sort (a, b)->
             return a.numOfItem-b.numOfItem
        else
          rows.sort (a, b)->
             return b.numOfItem-a.numOfItem
     

    res.render "directory", 
                            "AToZ"                  : AToZ
                            "rows"                  : rows
                            "listby"                : listby
                            "alphabet"              : alphabet
                            "sort"                  : req.params.sort
                            "numberOfPages"         : numberOfPages
                            "page"                  : page
                            "paginationShowNumber"  : settings.paginationShowNumber
)

app.get "/pages/postinglist/:username/:sortby/:sort/:page", 
  (req, res) ->
    page      = req.params.page
    username  = req.params.username
    sortby    = req.params.sortby
    sort      = 1
    rows      = []
    if req.params.sort is "desc"
      sort = -1 

    count             = undefined
    numberOfPages     = undefined
    postitemsPerPage  = settings.postitemsPerPage
    await PostItem.count {"username": username, "status" : "published"}, defer err,count
    numberOfPages = Math.ceil(count/postitemsPerPage)
    if sortby is "title"
      await PostItem.find({"username": username, "status" : "published"}).sort("title",sort).skip((page-1)*postitemsPerPage).limit(postitemsPerPage).execFind defer err,items
      if err
        logger.log "info", " (directory module) cannot query err :"+ err
      else
        for item in items
          row           = {}
          row.item_id   = item._id
          row.title     = item.title
          row.location  = item.address.city+", "+item.address.state+", "+item.address.country
          date = new Date(item.createdDate)
          row.date      = date.toLocaleTimeString()+" "+date.toLocaleDateString()
          rows.push row 

    else if sortby is "location"
      await PostItem.find({"username": username, "status" : "published"}).skip((page-1)*postitemsPerPage).limit(postitemsPerPage).execFind defer err,items
      if err
        logger.log "info", " (directory module) cannot query err :" + err
      else
        for item in items
          row           = {}
          row.item_id   = item._id
          row.title     = item.title
          row.location  = item.address.city+", "+item.address.state+", "+item.address.country
          date = new Date(item.createdDate)
          row.date      = date.toLocaleTimeString()+" "+date.toLocaleDateString()
          rows.push row
        if sort is 1
          rows.sort (a, b)->
            if  a.location.toLowerCase() < b.location.toLowerCase() 
              return -1 
            if  a.location.toLowerCase() > b.location.toLowerCase() 
              return 1
            return 0
        else
          rows.sort (a, b)->
            if  b.location.toLowerCase() < a.location.toLowerCase() 
              return -1 
            if  b.location.toLowerCase() > a.location.toLowerCase() 
              return 1
            return 0

    else if sortby is "date"
      await PostItem.find({"username": username, "status" : "published"}).sort("createdDate",sort).skip((page-1)*postitemsPerPage).limit(postitemsPerPage).execFind defer err,items
      if err
        logger.log "info", " (directory module) cannot query err :"+err
      else
        for item in items
          row           = {}
          row.item_id   = item._id
          row.title     = item.title
          row.location  = item.address.city+", "+item.address.state+", "+item.address.country
          date = new Date(item.createdDate)
          row.date      = date.toLocaleTimeString()+" "+date.toLocaleDateString()
          rows.push row 

    res.render "postinglist", 
                              "rows"                  : rows
                              "username"              : username
                              "sortby"                : sortby
                              "sort"                  : req.params.sort
                              "numberOfPages"         : numberOfPages
                              "page"                  : page
                              "paginationShowNumber"  : settings.paginationShowNumber

#################################################################################
# Setup account settings page.
# loadUser will guard for those who has loggedin.
################################################################################# 

app.get("/pages/account-settings/", loadUser, 
    (req, res) ->
      token     = req?.cookies?.logintoken
      token     = JSON.parse(token)
      loggedin  = if token then true else false 
      res.render("account-settings", {                                                                                 
                "loggedin": loggedin
                "token": JSON.stringify(token)
      })
)

#################################################################################
# Static page for search indexing.
################################################################################# 

app.get "/pages/:name/",
    (req, res) ->
      res.render req.params.name

#################################################################################
# Location validation.
################################################################################# 

app.get "/api/getCountries/",
    (req, res) ->
      result      = []
      urlParts    = url.parse(req.url, true)
      term        = urlParts.query.term
      limit       = urlParts.query.maxRows
      await service.getCountries term, limit, defer result 
      res.send result

app.get "/api/getCitiesByZipcode/",
    (req, res) ->
      result      = []
      urlParts    = url.parse(req.url, true)
      term        = urlParts.query.term
      limit       = urlParts.query.maxRows
      await service.getCitiesByZipcode term,limit , defer result 
      res.send result

app.get "/api/getCities/",
    (req, res) ->
      result      = []
      urlParts    = url.parse(req.url, true)
      term        = urlParts.query.term
      limit       = urlParts.query.maxRows
      ISO2        = urlParts.query.ISO2
      await service.getCities term,limit, ISO2, defer result 
      res.send result

#################################################################################
# Account settings - User management.
################################################################################# 

app.get "/api/user/:username/",
    (req, res) ->
      username = req.params.username
      if username
        user = err = null
        await User.findOne { "username": username }, defer err, user
        #TODO take care of the err.
        res.send generateResponse "success", "Users has been retrieved successfully", user, null  
      else
        res.send generateResponse "error", "The id given for user search can not be empty.", null, null 

app.delete "/api/user/:username/",
    (req, res) ->
      username = req.params.username
      if username
          user$ = err = null
          await User.findOne { "username": username }, defer err, user$
          #TODO decide if the user is deleted or just flag.
          res.send generateResponse "success", "Users has been removed successfully", user$, null
      else
          res.send generateResponse "error", "The user given for user remove can not be empty.", null, null 

app.put "/api/user/:username/",
    (req, res) ->
      username = req.params.username
      if username
          user$ = err = null
          await User.findOne { "username": username }, defer err, user$
          user$.username = user.username
          user$.password = user.password
          user$.email    = user.email
          user$.status   = user.status
          #TODO take care of the err.
          user$.save((err) -> console.log err)
          res.send generateResponse "success", "Users has been updated successfully", user$, null
      else
          res.send generateResponse "error", "The user given for user remove can not be empty.", null, null

#################################################################################
# Media update processing code.
################################################################################# 

app.get '/testEdit/',
    (req, res) ->
        res.render 'test'



# app.get "/dbconfig/",
#     (req, res) ->
#       service.CountryInfo.find {}, (err, countries)->
#         for country in countries
#           if country.ISO2 and country.Country isnt undefined
#               console.log "start: "+country.Country
#               await service.LocationInfo.find {"ISO2":country.ISO2}, defer err, locations
#               for location in locations
#                 if location
#                   location.country = country.Country
#                   location.save (err)->
#                         if (err)
#                           console.log location.country+"is error"
#                           console.log err
#               console.log "end: "+country.Country
#         console.log "Done!!!"
#       render("index")


#################################################################################
# Mobile website rendering code.
################################################################################# 

app.get "/pages/mobile/",
  (req, res) -> 
    res.render("mobile", {})

app.listen mainPort

#################################################################################
# Socket.IO setup
# We set up the queue for each city.state.country items.
# 1. We start off by querying the db for all city.state.country that
#    are in the db - SOCKET_IO_CHANNELS {"city.state.country": channelRef}.
# 2. We setup the socket io for each.
# 3. Within each socket io connection, we loop check the global 
#    {city.state.country: [array]} for new items.
#    3.1 If found, we push them though the socket.
#    (This assume that the client will automatically setup the correct
#     socket to listen to and also update it when the location is change)
# 4. We expand the channel whenever there is an update/add postitem.
#
# We use transformToLocationString found in service.coffee for string transform.
#
# The event postitem:published is triggered in checkupload.coffee in server-lib.
################################################################################# 
HALF_AN_HOUR                    = 1800000
SOCKET_IO_CHANNELS              = {}
channels                        = []

await service.getAllDistinctLocationString service.db, defer channels

io                              = require("socket.io").listen(socketIOPort)

tmp                             = io.of("/" + socketIOMainChannel).on("connection", (socket) ->
    socket.on("postitem:published", (postitem) ->
      channel                   = service.transformToLocationString(postitem.address.city, postitem.address.state, postitem.address.country)
      ## We recieve the event that the postitem is added to the db.
      ## We have to save the socket to the map and reuse it to send.
      createSocketIOChannel(channel)
      ##We just need to push it out.
      emitter                   = SOCKET_IO_CHANNELS[channel]
      emitter.broadcast.emit("postitems", postitem)
    )

    socket.on('disconnect',  () ->
      console.log "disconnect"
    )
)

##
# Create the socket and save it in the channels map for reuse.
##
createSocketIOChannel           = (channel) ->
  if not SOCKET_IO_CHANNELS[channel]
    tmp                           = io.of("/" + channel).on("connection", (socket) ->
      SOCKET_IO_CHANNELS[channel] = socket
      socket.on('disconnect',  () ->
        console.log "disconnect"
      )
    )
  

for channel in channels
  createSocketIOChannel(channel)

#################################################################################
# Cron jobs for maintainence and db updates - i.e. get unique location string
#################################################################################

cronJob                         = require('cron').CronJob
# midnight on 1st of month and every Sun.
job                             = new cronJob("0 0 1 * 7"
  , () ->
    service.updateUniqueLocation(db)
  , null
  , true
  , "America/New_York")