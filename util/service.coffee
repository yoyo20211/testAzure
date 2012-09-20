  ##
  # Convienient method to call to generate response back to the callers over the wire.
  # @param - type can be string that indicates status of the operation done success/error/exception.
  # @param - message it is the message to convey to the caller.
  # @param - context it can be any dictionary data that will be passed back to the caller.
  ##

path                      = require "path"
fs                        = require "fs"
Settings                  = require "settings"
settings                  = new Settings(path.join __dirname, "/../config/environment.js").getEnvironment()
models                    = require "../models/models"
_                         = require "underscore"
mongoose                  = require "mongoose"


generateResponse          = 
  (type, message, context, session) -> {response: type, message: message, context: context, session: session}

winston         	        = require "winston"

##
# Logger instantiation.
##

logger                    = new (winston.Logger)({
    transports: [
      new (winston.transports.Console)(),
      new (winston.transports.File)({ filename: "system.log" })
    ]
})

formidable                = require "formidable"
Thoonk                    = require("thoonk").Thoonk
thoonk                    = new Thoonk settings.redisServer, settings.redisPort, 1
postingJob                = thoonk.job "postingJob"
##
# Interpret the errors coming back from the backend to be more user friendly.
# @params 	the error object.
# @return	the user friendly string description of the error. 
##
interpretError            = 
	(error) ->
		@result               = "Generic Server Error" 
		@result               = "Duplicate Unique Key" if error.stack.indexOf("E11000 duplicate key error") isnt -1
		return @result


##
# Emailer setup
##

##
# This class depends on the node_mailer module.
##

class Mailer
  constructor: ->
    @email                = require("mailer")
  send:(@to, @from, @subject, @body) ->
    @email.send({
        host              : settings.mailServer,            
        port              : settings.mailServerSSLPort,
        ssl               : true,                     
        domain            : "gmail.com",             
        to                : @to,
        from              : @from,
        subject           : @subject,
        body              : @body,
        authentication    : "login",        
        username          : settings.mailUserAccount,       
        password          : settings.mailUserPassword
      }, (error, result) -> console.log(error) if error ## TODO see how to deal with the errors
    )
  ##
  # This method assumes that the template is found in the templates folder.
  # Template passed in just have to be the name of the template file.
  ##  
  sendWithTemplate:(@to, @from, @subject, @template, @data) ->
    @email.send({
        host              : settings.mailServer,            
        port              : settings.mailServerSSLPort,
        ssl               : true,                     
        domain            : "gmail.com",             
        to                : @to,
        from              : @from,
        subject           : @subject,
        template          : path.join __dirname, "/../templates/", @template
        data              : @data,
        authentication    : "login",        
        username          : settings.mailUserAccount,       
        password          : settings.mailUserPassword
      },
      (error, result) -> console.log(error) if error ## TODO see how to deal with the errors
    )

##
# Set up the persistence models.
##
LocationInfo  = ZipInfo       = CityInfo  = RegionInfo  = CountryInfo   = PostItem            = null 
Photo         = WishList      = User      = LoginToken  = RatingComment = RatingCommentTopic  = null
UniqueLocation                = null
db            = null
models.defineModels(mongoose, 
  ->
      User                = mongoose.model("User")
      PostItem            = mongoose.model("PostItem")
      Photo               = mongoose.model("Photo")
      WishList            = mongoose.model("WishList")
      LoginToken          = mongoose.model("LoginToken")
      RatingComment       = mongoose.model("RatingComment")
      RatingCommentTopic  = mongoose.model("RatingCommentTopic")
      CityInfo            = mongoose.model("CityInfo")
      RegionInfo          = mongoose.model("RegionInfo")
      CountryInfo         = mongoose.model("CountryInfo")
      ZipInfo             = mongoose.model("ZipInfo")
      LocationInfo        = mongoose.model("LocationInfo")
      UniqueLocation      = mongoose.model("UniqueLocation")
      db                  = mongoose.connect(settings.serverDBURL)
)

##
# This take term, limit, callback.
##

getCountries = (term,limit,callback) ->
  result  = []
  countries  = undefined
  error   = undefined
  await LocationInfo.find({"country" : {$regex : "^(?i)"+term}},["country", "ISO2"]).limit(limit).execFind defer error,countries
  if error then throw error
  for country in countries
      row = {}
      row.value     = country.country
      row.ISO2      = country.ISO2
      exist = false
      for temp in result
        if temp.value is row.value
          exist = true
          break;

      if !exist then result.push row
  # if countries.length is 0
  #   row = {}
  #   row.value     = "no available data"
  #   row.ISO2      = undefined
  callback(result)

getCitiesByZipcode = (term, limit, callback) ->
  result  = []
  zipcodes  = undefined
  error   = undefined
  await LocationInfo.find({"postalCode" : {$regex : "^"+term}}).limit(limit).execFind defer error,zipcodes
  if error then throw error
  for zipcode in zipcodes
    row = {}

    row.latitude    = zipcode.latitude
    row.longitude   = zipcode.longitude
    if isNaN parseInt(zipcode.region)
        row.address = zipcode.city+", "+zipcode.region
        row.value = zipcode.postalCode+": "+zipcode.city+", "+zipcode.region+", "+zipcode.ISO2
        row.country = zipcode.ISO2
      else
        row.address = zipcode.city
        row.value = zipcode.postalCode+": "+zipcode.city+", "+zipcode.ISO2
        row.country = zipcode.ISO2
    result.push row
  callback(result)


getCities = (term, limit, ISO2, callback) ->
  result  = []
  cities  = undefined
  error   = undefined
  await LocationInfo.find({"city" : {$regex : "^(?i)"+term},"ISO2":ISO2}).limit(limit).execFind defer error,cities
  
  # await CityInfo.find({"City" : {$regex : "(?i)["+term+"]*"}}).limit(20).execFind defer error,cities
  # await CityInfo.find({"CountryID":countryID}).execFind defer error,cities
  if error then throw error
  for city in cities
    # if metaphone.compare(city.city, term) or soundEx.compare(city.city, term) or natural.JaroWinklerDistance(city.City, term) > 0.49
      row = {}
      row.latitude    = city.latitude
      row.longitude   = city.longitude
      # if city.region is undefined or city.region is "" or !isNaN(city.region)
      if isNaN parseInt(city.region)
        row.value = city.city+", "+city.region
      else
        row.value = city.city
      # else
      #   row.value = city.city+", "+city.region+", "+city.ISO2
      for temp in result
        if temp.value is row.value
          exist = true
          break;

      if !exist then result.push row
  
  callback(result)

getCategories = (db, callback) -> 
    defaultArray = [ "Appliances"          , "Antiques"      , "Barter"      , "Bycycles"      , "Boats"     ,  
                     "Computer"            , "Free"          , "Furniture"   , "Others"        , "Jewelry"   ,  
                     "Sporting Goods"      , "Event Tickets" , "Tools"       , "Arts & Crafts" , "Auto Parts", 
                     "Beauty & Health"     , "Cars & Trucks" , "CDs/DVD/VHS" , "Cell Phones"   , "Music Instruments",         
                     "Garage Sale"         , "Household"     , "Motorcycles" , "Photo & Video" , "Foreign Goods",
                     "Toys & Games"        , "Video Games"   , "Baby & Kids" , "Farm & Garden" , "Books",
                     "Collectibles"        , "Electronics"   , "Materials & Supplies"          , "Clothes & Accessories"   
    ] 
    result    = null
    error     = null
    await PostItem.distinct("category", {}, defer(error, result))
    #TODO take care of the error when pass a sane result as a backup.
    concole.log error if error ##we just union found categories with the predefined ones for seeding the db.
    result    = _.union(defaultArray, result)
    result    = result.map((category) -> capitalizeFirstLetters(category))
    callback(result)

##
# This takes mongoose object to query the db.
##
getCategoriesWithTotal = (db, callback) ->
    defaultArray  = {  
        "Appliances"          :"0", "Antiques"      :"0", "Barter"      :"0", "Bycycles"      :"0", "Boats"     :"0",  
        "Computer"            :"0", "Free"          :"0", "Furniture"   :"0", "Others"        :"0", "Jewelry"   :"0",  
        "Sporting Goods"      :"0", "Event Tickets" :"0", "Tools"       :"0", "Arts & Crafts" :"0", "Auto Parts":"0", 
        "Beauty & Health"     :"0", "Cars & Trucks" :"0", "CDs/DVD/VHS" :"0", "Cell Phones"   :"0", "Music Instruments":"0",         
        "Garage Sale"         :"0", "Household"     :"0", "Motorcycles" :"0", "Photo & Video" :"0", "Foreign Goods":"0",
        "Toys & Games"        :"0", "Video Games"   :"0", "Baby & Kids" :"0", "Farm & Garden" :"0", "Books":"0",
        "Collectibles"        :"0", "Electronics"   :"0", "Materials & Supplies":"0"              , "Clothes & Accessories":"0"    
    }
    reduce        = (doc, prev) -> prev.count =+ 1
    command       = {
        "group": {
            ns: "postitems",
            initial: {"count": 0},
            "$reduce": reduce.toString(),
            "key": {"category": true}
        }
    }
    error         = null
    result        = null
    await db.connection.db.executeDbCommand(command, defer(error, result))
    #TODO take care of the error and pass sane default to the callback. 
    console.log error if error
    @array        = _.first(result.documents).retval
    values        = {}
    @array.forEach((value) -> 
         value.category         = capitalizeFirstLetters(value.category)
         values[value.category] = value.count;
    )
    #We merge the values with defaultArray to get the default if the values return from the db do not include the defaults.
    _.extend(defaultArray, values) 
    callback(defaultArray)

##
# Get posting total for each user.
##
getUserPostingTotal = (db, alphabet, sort, page, callback) ->
    users           = undefined
    count           = undefined
    numberofPages   = undefined
    defaultArray    = {}
    userSet         = []

    if alphabet is "all"
      await User.count {"status": "active"}, defer error,count
      #TODO take care of the error and pass sane default to the callback.
      console.log error if error
      numberofPages = Math.ceil(count/settings.postItemsPerPage)
      await User.find({"status": "active"}).sort("username",sort).skip((page-1)*settings.postItemsPerPage).limit(settings.postItemsPerPage).execFind defer error,users
    else
      await User.count {"username": {$regex : "^(?i)"+alphabet},"status": "active"}, defer error,count
      numberofPages = Math.ceil(count/settings.postItemsPerPage)
      await User.find({"username": {$regex : "^(?i)"+alphabet},"status": "active"}).sort("username",sort).skip((page-1)*settings.postItemsPerPage).limit(settings.postItemsPerPage).execFind defer error,users
  
    for user in users
      defaultArray[user.username] = {}
      defaultArray[user.username].numberOfPosting = 0
      defaultArray[user.username].location = user.address.city+", "+user.address.state+", "+user.address.country
      userSet.push user.username

    reduce = (doc, prev) -> prev.count++
    command =
        "group":
            ns        : "postitems"
            "cond"    : { "status" : "published", "username": {$in : userSet} }
            initial   : {"count": 0}
            "$reduce" : reduce.toString()
            "key"     : {"username": 1}
    
    error = null
    result = null
    await db.connection.db.executeDbCommand(command, defer(error, result))
    #TODO take care of the error and pass sane default to the callback.
    console.log error if error

    for obj in result.documents[0].retval
      defaultArray[obj.username].numberOfPosting = obj.count

    callback(defaultArray,numberofPages)

##
# Get all valid email domain names found in the db + initial seed valid domain names.
##
getAllValidEmailDomainNames = (db, callback) ->
  defaultArray              = ["hotmail.com", "gmail.com", "aol.com", "yahoo.com"]
  result                    = null
  error                     = null
  await User.distinct("email", {}, defer(error, result))
  #TODO take care of the error and pass sane default to the callback.
  console.log error if error
  domainNames               = _.map(result, (email) -> email.substring(email.indexOf("@") + 1, email.length))
  domainNames               = _.union(defaultArray, domainNames)
  callback(defaultArray)

##
# Get the distinct city.state.country values from the db.
getAllDistinctLocationString  = (db, callback) ->
  result                      = null
  error                       = null
  await UniqueLocation.find({}).execFind defer error, result
  #TODO take care of the error and pass sane default to the callback.
  console.log error if error
  locations                   = _.pluck(result, "value")
  callback(locations)

##
# Running mapreduce on the db to create unique location - i.e new.york.new.york.usa.
# This is used for Socket.IO queue names.
##
updateUniqueLocation      = (db) ->
    map                   = () ->
      result              = transformToLocationString(this.address.city, this.address.state, this.address.country)
      emit(result, result)

    reduce                = (key, values) ->
      return key

    command = {
        mapreduce: "postitems", 
        ns: "postitems"
        map: map, 
        reduce: reduce, 
        out: "uniquelocations" 
    }

    error                 = null
    result                = null
    await db.connection.db.executeDbCommand(command, defer(error, result))
    #TODO take care of the error and pass sane default to the callback. 
    console.log error if error
    errMsg                = result.documents[0].assertion
    console.log errMsg if errMsg

transformToLocationString = (city, state, country) ->
  city                    = city.trim().replace(" ", ".").toLowerCase() + "."
  state                   = state.trim().replace(" ", ".").toLowerCase() + "."
  country                 = country.trim().replace(" ", ".").toLowerCase()
  return city + state + country 
##
##
# authentication ajax methods
##
authFromLoginTokenAjax  = (req, res, next) -> 
  cookie                = req.cookies.logintoken
  LoginToken.findOne({ username: cookie.username, token: cookie.token, series: cookie.series }, 
    (error, token) ->
        if !token or error
            res.send generateResponse("authentication-required", "The token is not found in the cookie.  The user is required to login again.", null, null)
        else 
            User.findOne({ username: token.username }, 
                (error, user) ->
                    console.log "authFromLoginTokenAjax found user"
                    if (user and user.status is "active")
                        req.session.userId  = user.id
                        req.currentUser     = user
                        
                        token.token         = token.randomToken()
                        token.save(() ->
                            res.cookie("logintoken", JSON.stringify(token), { expires: new Date(Date.now() + 2 * 604800000), path: "/" })
                            next()
                        )
                    else
                        res.send generateResponse("authentication-required", "The token is not found in the cookie.  The user is required to login again.", null, null) 
            )
  )

##
# authentication methods
##
authFromLoginToken  = (req, res, next) -> 
  cookie            = JSON.parse(req?.cookies?.logintoken) if req?.cookies?.logintoken
  console.log "authFromLoginToken " + JSON.stringify(cookie)
  LoginToken.findOne({ username: cookie?.username }, 
    (error, token) ->
        if !token or error
            console.log "authFromLoginToken no token"
            res.redirect("/login/")
        else
            User.findOne({ username: token.username }, 
              (error, user) ->
                  console.log "authFromLoginToken found user"
                  if (user and user.status is "active")
                      req.session.userId  = user.id
                      req.currentUser     = user
                      
                      token.token         = token.randomToken()
                      token.save((error) ->
                        if !error
                          res.cookie("logintoken", JSON.stringify(token), { expires: new Date(Date.now() + 2 * 604800000), path: "/" })
                          next()
                      )
                  else
                     res.redirect("/login/")
            )
  )

##
# Check user loggedin status and send ajax reply.
##
loadUserAjax = (req, res, next) ->
  if (req.session.userId)
      User.findById(req.session.userId, 
          (error, user) ->
              if (user and user.status is "active")
                  console.log "found user " + user
                  req.currentUser = user
                  next()
              else
                  res.send generateResponse("authentication-required", "The user found in session is not valid.  The user must try to log in again.", null, null)
      )
  else if (req.cookies.logintoken)
      authFromLoginTokenAjax(req, res, next)
  else
      res.send generateResponse("authentication-required", "There is no user information found in the session or cookie. The user must log in again.", null, null)

##
# Check user loggedin status and send redirect to error page.
##
loadUser = (req, res, next) ->
  if (req.session.user_id)
    User.findById(req.session.user_id, 
      (error, user) ->
        if (user)
          req.currentUser = user
          next()
        else
          res.redirect("/login/")
    )
  else if (req.cookies.logintoken)
    authFromLoginToken(req, res, next)
  else
    res.redirect("/login/")
##
# Take in string as words - i.e. "one two three" and capitalize first letters into "One Two Three".
##
capitalizeFirstLetters              = (words) ->
  if words and trim(words) isnt ""
    words.split(/\s+/).map((word) -> 
      if word[0]
        word[0].toUpperCase() + word[1..-1].toLowerCase()
    ).join " "
  else
    ""

# Check and create directory

mkdirs  = (path, mode, callback)->
    if path.indexOf "\\"  >= 0
      path = path.replace "\\", "/"

    if path.substr(path.length - 1) is "/" #remove trailing slash
        path = path.substr(0, path.length - 1);
    tryDirectory = (dir, cb)->
        fs.stat dir, (error, stat)->

            if error #the file doesn"t exist, try one stage earlier then create
                if error.errno is 2 or error.errno is 32 or error.errno is 34

                    if  dir.lastIndexOf("/") is dir.indexOf("/") #only slash remaining is initial slash
                        #should only be triggered when path is "/" in Unix, or "C:/" in Windows
                        cb new Error("notfound")
                    else 
                        tryDirectory dir.substr 0, dir.lastIndexOf("/"), (error)->
                            if error #error, return
                                cb error 
                            else #make this directory
                                fs.mkdir dir, mode, (error)->
                                    if error && error.errno != 17
                                        console.log("Failed to make " + dir)
                                        cb new Error("failed") 
                                    else 
                                        cb()
                else #unkown error
                    console.log util.inspect(error, true) 
                    cb error
            else  
                if stat.isDirectory() #directory exists, no need to check previous directories
                    cb()
                else #file exists at location, cannot make folder
                    cb new Error("exists")  
    tryDirectory(path, callback);


# trim string

trim = (string)->
    string.replace(/^\s*|\s*$/g, "")

##
# Unique ID generator from http://coffeescriptcookbook.com/chapters/strings/generating-a-unique-id
##
uniqueId = (length=18) ->
  id = ""
  id += Math.random().toString(36).substr(2) while id.length < length
  id.substr 0, length

##
# Check if it is mobile phone.  If yes, send res to mobile page.
# Test string is from: http://detectmobilebrowsers.com/.
##
isMobilePhone = (ua) ->
  return /android.+mobile|avantgo|bada\/|blackberry|blazer|compal|elaine|fennec|hiptop|iemobile|ip(hone|od)|iris|kindle|lge |maemo|midp|mmp|netfront|opera m(ob|in)i|palm( os)?|phone|p(ixi|re)\/|plucker|pocket|psp|symbian|treo|up\.(browser|link)|vodafone|wap|windows (ce|phone)|xda|xiino/i.test(ua)||/1207|6310|6590|3gso|4thp|50[1-6]i|770s|802s|a wa|abac|ac(er|oo|s\-)|ai(ko|rn)|al(av|ca|co)|amoi|an(ex|ny|yw)|aptu|ar(ch|go)|as(te|us)|attw|au(di|\-m|r |s )|avan|be(ck|ll|nq)|bi(lb|rd)|bl(ac|az)|br(e|v)w|bumb|bw\-(n|u)|c55\/|capi|ccwa|cdm\-|cell|chtm|cldc|cmd\-|co(mp|nd)|craw|da(it|ll|ng)|dbte|dc\-s|devi|dica|dmob|do(c|p)o|ds(12|\-d)|el(49|ai)|em(l2|ul)|er(ic|k0)|esl8|ez([4-7]0|os|wa|ze)|fetc|fly(\-|_)|g1 u|g560|gene|gf\-5|g\-mo|go(\.w|od)|gr(ad|un)|haie|hcit|hd\-(m|p|t)|hei\-|hi(pt|ta)|hp( i|ip)|hs\-c|ht(c(\-| |_|a|g|p|s|t)|tp)|hu(aw|tc)|i\-(20|go|ma)|i230|iac( |\-|\/)|ibro|idea|ig01|ikom|im1k|inno|ipaq|iris|ja(t|v)a|jbro|jemu|jigs|kddi|keji|kgt( |\/)|klon|kpt |kwc\-|kyo(c|k)|le(no|xi)|lg( g|\/(k|l|u)|50|54|e\-|e\/|\-[a-w])|libw|lynx|m1\-w|m3ga|m50\/|ma(te|ui|xo)|mc(01|21|ca)|m\-cr|me(di|rc|ri)|mi(o8|oa|ts)|mmef|mo(01|02|bi|de|do|t(\-| |o|v)|zz)|mt(50|p1|v )|mwbp|mywa|n10[0-2]|n20[2-3]|n30(0|2)|n50(0|2|5)|n7(0(0|1)|10)|ne((c|m)\-|on|tf|wf|wg|wt)|nok(6|i)|nzph|o2im|op(ti|wv)|oran|owg1|p800|pan(a|d|t)|pdxg|pg(13|\-([1-8]|c))|phil|pire|pl(ay|uc)|pn\-2|po(ck|rt|se)|prox|psio|pt\-g|qa\-a|qc(07|12|21|32|60|\-[2-7]|i\-)|qtek|r380|r600|raks|rim9|ro(ve|zo)|s55\/|sa(ge|ma|mm|ms|ny|va)|sc(01|h\-|oo|p\-)|sdk\/|se(c(\-|0|1)|47|mc|nd|ri)|sgh\-|shar|sie(\-|m)|sk\-0|sl(45|id)|sm(al|ar|b3|it|t5)|so(ft|ny)|sp(01|h\-|v\-|v )|sy(01|mb)|t2(18|50)|t6(00|10|18)|ta(gt|lk)|tcl\-|tdg\-|tel(i|m)|tim\-|t\-mo|to(pl|sh)|ts(70|m\-|m3|m5)|tx\-9|up(\.b|g1|si)|utst|v400|v750|veri|vi(rg|te)|vk(40|5[0-3]|\-v)|vm40|voda|vulc|vx(52|53|60|61|70|80|81|83|85|98)|w3c(\-| )|webc|whit|wi(g |nc|nw)|wmlb|wonu|x700|xda(\-|2|g)|yas\-|your|zeto|zte\-/i.test(ua.substr(0,4))

saveUploadData = (req, res, abortedFlag, Process, fileType)->
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
              postitem = undefined
              await PostItem.findOne {_id:item._id,status:"published"}, defer err,postitem
              if !abortedFlag[processId] and postitem
                abortedFlag[processId] = undefined

                if fileType is "photo"
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
        
                else if fileType is "voice"
                  postitem.set 'isVoiceProcessing',true
                  await postitem.save defer err
                  if err
                    res.send generateResponse "error", "the post item is not available or published", null, null 
                  else
                    postingJob.publish JSON.stringify(item) , (err, data, id)->
                        logger.log "info", " (Posting module) Add process id "+processId+" to Posting system" 
                    ,false, item.processId
                    res.send generateResponse "success", "add the post item to process successfully", null, null 
                  
                else if fileType is "video"
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

deletePhoto = (req, res, abortedFlag, Process)->
      processId = req.params.processId
      abortedFlag[processId] = false;
      form = new formidable.IncomingForm()
      form.uploadDir = "./public/data"
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
          .on "end",
           ->
              item = 
                      "fields" : fields
                      "files" : files
              item.processId = processId;
              item._id = item.fields.id;
              item.photoId = item.fields.photoId;
              item.processType = "delete"
              postitem = undefined
              await PostItem.findOne {_id:item._id,status:"published"}, defer err,postitem
              if !abortedFlag[processId] and postitem
                  abortedFlag[processId] = undefined
                  found = false

                  for i in [0..postitem.photos.length]
                    if(photo._id == item.photoId)
                      item.files["photoFile"+i] = "none"
                      found = true

                  if found
                    numberOfPhotos = postitem.numberOfPhotos
                    numberOfPhotos--
                    postitem.set 'numberOfPhotos',numberOfPhotos
                    await postitem.save defer err
                    if err
                      res.send generateResponse "error", "the post item is not available or published", null, null 
                    else
                      postingJob.publish JSON.stringify(item) , (err, data, id)->
                          logger.log "info", " (Posting module) Add process id "+processId+" to Posting system" 
                      ,false, item.processId
                      res.send generateResponse "success", "add the post item to process successfully", null, null 
                  else
                    logger.log "info", " (Deleteing photo module) Can not found the photoID "+item.photoId+" in database; ProcessID :"+processId
              else
                abortedFlag[processId] = undefined
                if postitem
                   logger.log "info", " (Posting module) The posting id : "+processId+" is aborted by user"
                   res.send generateResponse "abort", "The posting is aborted by user", null, null 
                else
                  logger.log "info", " (Posting module) The posting id : "+processId+" is aborted because the item is not available"
                  res.send generateResponse "abort", "the item is not available", null, null 
                  
      form.parse req

deleteVoice = (req, res, abortedFlag, Process)->
      processId = req.params.processId
      abortedFlag[processId] = false;
      form = new formidable.IncomingForm()
      form.uploadDir = "./public/data"
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
          .on "end",
           ->
              item = 
                      "fields" : fields
                      "files" : files
              item.processId = processId;
              item._id = item.fields.id;
              item.photoId = item.fields.photoId;
              item.processType = "delete"
              postitem = undefined
              await PostItem.findOne {_id:item._id,status:"published"}, defer err,postitem
              if !abortedFlag[processId] and postitem
                  abortedFlag[processId] = undefined

                  item.files.voiceFile = "none"
                  postitem.set 'isVoiceProcessing',true
                  await postitem.save defer err
                  if err
                    res.send generateResponse "error", "the post item is not available or published", null, null 
                  else
                    postingJob.publish JSON.stringify(item) , (err, data, id)->
                        logger.log "info", " (Posting module) Add process id "+processId+" to Posting system" 
                    ,false, item.processId
                    res.send generateResponse "success", "add the post item to process successfully", null, null 
              else
                abortedFlag[processId] = undefined
                if postitem
                   logger.log "info", " (Posting module) The posting id : "+processId+" is aborted by user"
                   res.send generateResponse "abort", "The posting is aborted by user", null, null 
                else
                  logger.log "info", " (Posting module) The posting id : "+processId+" is aborted because the item is not available"
                  res.send generateResponse "abort", "the item is not available", null, null 
                  
      form.parse req

deleteVideo = (req, res, abortedFlag, Process)->
      processId = req.params.processId
      abortedFlag[processId] = false;
      form = new formidable.IncomingForm()
      form.uploadDir = "./public/data"
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
          .on "end",
           ->
              item = 
                      "fields" : fields
                      "files" : files
              item.processId = processId;
              item._id = item.fields.id;
              item.photoId = item.fields.photoId;
              item.processType = "delete"
              postitem = undefined
              await PostItem.findOne {_id:item._id,status:"published"}, defer err,postitem
              if !abortedFlag[processId] and postitem
                  abortedFlag[processId] = undefined

                  item.files.videoFile = "none"
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
                abortedFlag[processId] = undefined
                if postitem
                   logger.log "info", " (Posting module) The posting id : "+processId+" is aborted by user"
                   res.send generateResponse "abort", "The posting is aborted by user", null, null 
                else
                  logger.log "info", " (Posting module) The posting id : "+processId+" is aborted because the item is not available"
                  res.send generateResponse "abort", "the item is not available", null, null 
                  
      form.parse req

addPostingItem = (req, res, abortedFlag, Process)->
      processId = req.params.processId
      abortedFlag[processId] = false;
      form = new formidable.IncomingForm()
      form.uploadDir = "./public/data"
      form.keepExtensions = false
      aborted = false
      beginfiles  = []
      overSizeFile = []
      photoNumber = 0
      files  = {}
      fields = {}
      _this=this

      form.addListener "progress",
           (recvd, expected) ->
             #console.log "get in progress";
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
              #console.log err;
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
              
              if !abortedFlag[processId]
                abortedFlag[processId] = undefined
                user=null
                err=null
                await User.findOne { _id:req.session.userId}, defer err,user
                if !err
                  fields.username = user.username
                item = 
                      "fields" : fields
                      "files" : files

                #console.log item.files
                item.processId = processId;
                postitem_temp = new PostItem();
                item._id = postitem_temp._id;
                postingJob.publish JSON.stringify(item) , (err, data, id)->
                    logger.log "info", " (Posting module) Add process id "+processId+" to Posting system" 
                ,false, item.processId
                res.send generateResponse "success", "add the post item to process successfully", null, null 
              else
                for file in beginfiles
                  fs.unlink(file.path)
                abortedFlag[processId] = undefined
                if overSizeFile.length > 0
                  message=""
                  for file in overSizeFile
                    message+=file+","
                  logger.log "info", " (Posting module) The posting id : "+processId+" is aborted because oversize file" 
                  res.send generateResponse "oversize", message, null, null  
                else
                  logger.log "info", " (Posting module) The posting id : "+processId+" is aborted by user"
                  res.send generateResponse "abort", "The posting is aborted by user", null, null 

      form.parse req

##
# Export for other files to reference.
##
exports.mailer             	           = new Mailer()
exports.interpretError 		             = interpretError  
exports.generateResponse               = generateResponse
exports.logger 				                 = logger
exports.getCategories                  = getCategories
exports.getCategoriesWithTotal         = getCategoriesWithTotal
exports.authFromLoginToken             = authFromLoginToken
exports.loadUser                       = loadUser
exports.loadUserAjax                   = loadUserAjax
exports.db                             = db
exports.User                           = User
exports.PostItem                       = PostItem
exports.Photo                          = Photo
exports.WishList                       = WishList
exports.LoginToken                     = LoginToken
exports.RatingComment                  = RatingComment
exports.RatingCommentTopic             = RatingCommentTopic
exports.CityInfo                       = CityInfo
exports.RegionInfo                     = RegionInfo
exports.LocationInfo                   = LocationInfo
exports.CountryInfo                    = CountryInfo
exports.UniqueLocation                 = UniqueLocation
exports.capitalizeFirstLetters         = capitalizeFirstLetters
exports.transformToLocationString      = transformToLocationString
exports.mkdirs                         = mkdirs
exports.trim                           = trim
exports.uniqueId                       = uniqueId
exports.getUserPostingTotal            = getUserPostingTotal
exports.getAllValidEmailDomainNames    = getAllValidEmailDomainNames
exports.getAllDistinctLocationString   = getAllDistinctLocationString
exports.getCities                      = getCities
exports.getCitiesByZipcode             = getCitiesByZipcode
exports.getCountries                   = getCountries
exports.isMobilePhone                  = isMobilePhone
exports.updateUniqueLocation           = updateUniqueLocation
exports.addPostingItem                 = addPostingItem
exports.deletePhoto                    = deletePhoto
exports.deleteVoice                    = deleteVoice
exports.deleteVideo                    = deleteVideo
exports.saveUploadData                 = saveUploadData