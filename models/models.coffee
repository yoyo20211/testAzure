##
# Models defined with Mongoose for MongoDB
# For location element, MongoDB expect the array [] for the values. 
# Longitude is first and Latitude is second (assumed/required by the db).
##

urlShortener 					= require "../util/urlshortener"
kybos 							= require "../util/Kybos"
crypto 							= require "crypto"
dateFormat 						= require "dateformat"

random 							= kybos.Kybos()

toLower 						= 
	(v, next) ->
		if v
  			v.toLowerCase()
  		next()

validatePresenceOf 				= 
	(value) ->
  		value && value.length

defineModels 					= (mongoose, next) ->
	User 						= undefined
	Schema 						= mongoose.Schema
	ObjectId 					= Schema.ObjectId
	mongooseTypes 				= require "mongoose-types"
	mongooseTypes.loadTypes(mongoose)
	EmailType 					= mongoose.SchemaTypes.Email
	UrlType	 					= mongoose.SchemaTypes.Url

	@userStatuses 				= ["active", "inactive"]
	@postitemStatuses			= ["draft", "saved", "published", "wishlist", "expired"]
	@smsOptions 				= ["none", "paid", "ads-support"]
	@categories					= [ "Appliances"          , "Antiques"      , "Barter"      , "Bycycles"      , "Boats"     ,  
                     "Computer"            , "Free"          , "Furniture"   , "Others"        , "Jewelry"   ,  
                     "Sporting Goods"      , "Event Tickets" , "Tools"       , "Arts & Crafts" , "Auto Parts", 
                     "Beauty & Health"     , "Cars & Trucks" , "CDs/DVD/VHS" , "Cell Phones"   , "Music Instruments",         
                     "Garage Sale"         , "Household"     , "Motorcycles" , "Photo & Video" , "Foreign Goods",
                     "Toys & Games"        , "Video Games"   , "Baby & Kids" , "Farm & Garden" , "Books",
                     "Collectibles"        , "Electronics"   , "Materials & Supplies"          , "Clothes & Accessories"   
    ] 
	Photo	 		            = new Schema({
		image	          	: {type	: String			, required: true },
		imageThumbnail	   	: {type	: UrlType			, required: false },
		createdDate	      	: {type : Date,      default : Date.now,required : true},
		title     			: {type : String,    default : "",      required : false},
		isPhotoProcessing	: {type : Boolean,    default : false,      required : false}	
	})
	
	PostItem 		            = new Schema({ 
	    title     			: {type : String,    default : "",      required : true},
	    username     		: {type : String,    default : "",      required : true},
	    itemDescription		: {type : String,    default : "",      required : true},
	    price				: {type : Number,    default : 0.00,    required : true},
	    category			: {type : String,    default : "others", enum : @categories, required : true},
	    status				: {type : String,    default : "draft" , enum : @postitemStatuses, required : true},
	    createdDate	      	: {type : Date,      default : Date.now,required : true},
	    email				: {type : EmailType, default : "", 	    required : true},
	    showEmail			: {type : Boolean,   default : false,   required : false},
	    exchangeOptions		: [String],
	    photos  			: [Photo],
	    #first number is longitude, second is latitude
	    location 			: {type: [Number], index: "2d", required : false},
	    address				: {
	    					# This is embedded structure but coffeescript will complain if the block contains tabs.
	    country				: {type : String,    default : "",      required : true},
	    state				: {type : String,    default : "",      required : true},
	    city				: {type : String,    default : "",      required : true},
	    neighborhood		: {type : String,    default : "",      required : false},
							  },
		video				: {type : UrlType,   default : "", 		required : false},
		isVideoProcessing	: {type : Boolean,   default : false,   required : false},
		voice				: {type : UrlType,   default : "", 		required : false},
		isVoiceProcessing	: {type : Boolean,   default : false,   required : false},
		numberOfPhotos		: {type : Number,    default : 0,   	required : false}, # the array and the numberOfPhotos might not match in case of processing
		shortKey 			: {type : String,    default : "", 		required : false, index: {unique: true, dropDups: true}, safe: true},
		userRating          : {type : String,    default : "0",     required : false},
		sms					: {type : Number,    default : 0,    	required : false},
		smsOption			: {type : String,    default : "none" , enum : @smsOptions, required : false}
	})

	PostItem.pre "save", (next) ->
	    #Automatically create the shortkey for use in routing emails to this postiem.
	    @shortKey 				= urlShortener.encode(random.uint32())
	    next()
	
	PostItem.method "publish", () -> 
		@status 			= "published"
		@.save()

	PostItem.method "activate", () -> 
		@status 			= "published"
		@.save()

	PostItem.method "deActivate", () -> 
		@status 			= "expired"
		@.save()

	PostItem.method "expire", () -> 
		@status 			= "expired"
		@.save()

	PostItem.method "delete", () -> 
		@status 			= "deleted"
		@.save()
	#TODO set: toLower can not be set on the User email declaration.  Make sure the email is set to lower letters. 
	User 						= new Schema({
	    username        : {type : String,    default : "", required : true, index: {unique: true, dropDups: true}, safe: true}, 
	    email			: {type : EmailType, default : "", required : true, index: {unique: true, dropDups: true}, safe: true},
	    status			: {type : String,    default : "inactive", 	enum : @userStatuses,  required : true},
	    hashedPassword	: {type : String,    default : "", 			required : true},
	    salt			: {type : String,    default : "", 			required : true},
	    role 			: {type : String,    default : "", 			required : true},
	    createdAt	   	: {type : Date,      default : Date.now,	required: true},
	    rating          : {type : Number,    default : "0", 		required : false},
	    #first number is longitude, second is latitude
	    location 		: {type: [Number], index: "2d", 			required : false},
	    address			: {
	    					# This is embedded structure but coffeescript will complain if the block contains tabs.
	    country			: {type : String,    default : "",      	required : true},
	    state			: {type : String,    default : "",      	required : true},
	    city			: {type : String,    default : "",      	required : true},
	    neighborhood	: {type : String,    default : "",      	required : false}
						  },
		sms				: {type : Number,    default : 0,    		required : false},
		smsOption		: {type : String,    default : "none", enum : @smsOptions, required : false},
		paymentToken 	: {type : String,    default : "", 			required : false}
	})

	User.virtual("id").get () -> this._id.toHexString()

	User.virtual("nickname").get () ->
	    return this.username
	    
	User.virtual("password").set (password) ->
	    @_password = password
	    @salt = @makeSalt()
	    @hashedPassword = @encryptPassword password
	  .get () -> @_password

	User.method "authenticate", (plainText) ->
	    @encryptPassword(plainText) is @hashedPassword
	  
	User.method "makeSalt", () ->
	    Math.round(new Date().valueOf() * Math.random()) + ""

	User.method "encryptPassword", (password) ->
	    crypto.createHmac("sha1", @salt).update(password).digest("hex")

	User.pre "save", (next) ->
	    if !validatePresenceOf this.hashedPassword
	      next new Error("Invalid password")
	    else
	      next()

	User.method "activate", () -> 
		@status 			= "active"
		@.save()

	User.method "deActivate", () -> 
		@status 			= "inactive"
		@.save()
      
	User.method "hasRoles", (roles, next) ->
	    Role = mongoose.model "Role"
	    Group = mongoose.model "Group"
	    
	    tasks = []
	    userId = @_id    
	    
	    for rk in roles
	      do (rk) ->
	        tasks.push (cb) ->
	          Role.findOne {name: rk}, (err, role) ->
	            if err || !role
	              return cb(null, 0)
	            if role.hasUser userId
	              cb(null, 1)
	            else if role.groups.length > 0
	              async.forEach role.groups, (grp, cbb) ->
	                Group.findOne {_id: grp.groupId}, (e, group) ->
	                  if group && group.hasUser userId
	                    return cbb()
	                  else
	                    return cbb(0)
	              , (e, r) ->
	                if e
	                  cb(null, 0)
	                else
	                  cb(null, 1)
	            else
	              cb(null, 0)
	    
	    async.series tasks, (err, results) ->
	      tot = 0
	      for r in results
	        tot += r
	      next(tot)

	RatingCommentTopic				= new Schema({
        createdAt	      	: {type : Date,      default : Date.now,	required : true},
        topic				: {type : String,    default : "",      required : true},
        comment				: [RatingComment],
        username 			: {type : String,    default : "",      required : true}
    }) 
          
	RatingComment					= new Schema({
        createdAt	      	: {type : Date,      default : Date.now,	required : true},
        rater				: {type : String,    default : "",      required : true},
        comment				: {type : String,    default : "",      required : true},
        reply				: {type : String,    default : "",      required : false},
        username 			: {type : String,    default : "",      required : true}
    })    

	WishList        				= new Schema({
        postitem           	: [PostItem],
        createdAt	      	: {type : Date,      default : Date.now,	required : true},
        username 			: {type : String,    default : "",      	required : true}
    })    
	  ###
	  Model: GroupUser
	  ###
	GroupUser 						= new Schema({
	    userId 				: ObjectId,
	    username 			: {type : String,    default : "",      required : true},
	    name 				: {
	      						first		: {type : String,    default : "",      required : true},
	      						last 		: {type : String,    default : "",      required : true},
	      						full 		: {type : String,    default : "",      required : false}
	  		  				  }
	})

	Group 							= new Schema({
	    username 			: {type : String,   validate: [validatePresenceOf, "name is required"],     index: {unique: true}},
	    users 				: [GroupUser]
	})    
	Group.method "hasUser", (userId) ->
	    for user in this.users
	      if user.userId.toString() == userId.toString()
	        return true
	    return false

	RoleGroup 						= new Schema({
	    groupId 			: ObjectId,
	    name 				: {type : String,    default : "",      required : true}
	})

	RoleUser 						= new Schema({
	    userId 				: ObjectId
	    username			: {type : String,    default : "",      required : true},
	    name 				: {
	      						first		: {type : String,    default : "",      required : true},
	      						last 		: {type : String,    default : "",      required : true},
	      						full 		: {type : String,    default : "",      required : false}
	  		  				  }
	})

	Role 							= new Schema({
	    name 				: {type : String,   validate: [validatePresenceOf, "name is required"], index: {unique: true}, set: toLower},
	    groups 	 			: [RoleGroup]
	    users 				: [RoleUser]
	})

	Role.method "hasGroup", (groupId) ->
	    for grp in this.groups
	      if grp.groupId.toString() == groupId.toString()
	        return true
	    return false

	Role.method "hasUser", (userId) ->
	    for user in this.users
	      if user.userId.toString() == userId.toString()
	        return true
	    return false
	  
	  ###
	  # Model: LoginToken
	  # Used for session persistence.
	  ###
	LoginToken 						= new Schema
	    username:
	      type: String
	      index: true
	    series:
	      type: String
	      index: true
	    token:
	      type: String
	      index: true
	    rememberme:
	      type : Boolean
	      default : false
	    #first number is longitude, second is latitude
	    location 		: {type: [Number], required : false},
	    address			: {
	    					# This is embedded structure but coffeescript will complain if the block contains tabs.
	    country			: {type : String,    default : "",      required : true},
	    state			: {type : String,    default : "",      required : true},
	    city			: {type : String,    default : "",      required : true},
	    neighborhood	: {type : String,    default : "",      required : false},
						  }

	LoginToken.method "randomToken", () ->
	    Math.round (new Date().valueOf() * Math.random()) + ""

	LoginToken.pre "save", (next) ->
	    #Automatically create the tokens
	    this.token = this.randomToken()
	    if this.isNew
	      this.series = this.randomToken()
	    next()

	LoginToken.virtual("id").get () ->
	    this._id.toHexString()

	LoginToken.virtual("latitude").get () ->
	    this?.location?["0"]?.latitude

	LoginToken.virtual("longitude").get () ->
	    this?.location?["0"]?.longitude
	        
	LoginToken.virtual("cookieValue").get () ->
	    JSON.stringify username: this.username, token: this.token, series: this.series
	##
	# Model: ShortKeyPostItemMapping
	# It is used to store the random key generated with Kybos.js that maps to the PostItem id.
	# The random key is generated and passed to the urlshortener to generate the url string.
	# The string is used to prepend the email address associated with the PostItem posted.
	# Once the email is recieved, the username of the email part is captured to map to the real
	# email of the PostItem.
	##
	ShortKeyPostItemMapping 		= new Schema
		shortkey 			:	
			type 			: Number
			required		: true
			index			: true
		postitemid			:
			type 			: String
			required 		: true
			index			: true

	CityInfo 						= new Schema
		CityId 			:	{type : Number,required : true}
		CountryID 		:	{type : Number,required : true}
		RegionID		:	{type : Number,required : true}
		City 			:	{type : String,required : true}
		Latitude		:	{type : Number,required : true}
		Longitude 		:	{type : Number,required : true}
		TimeZone 		:	{type : String,required : true}
		DmaId 			:	{type : Number,required : true}
		Code 			:	{type : String,required : true}
	RegionInfo 						= new Schema
		CountryId 		:	{type : Number,required : true}
		RegionId		:	{type : Number,required : true}
		Region 			:	{type : String,required : true}
		Code 			:	{type : String,required : true}
		ADM1Code		:	{type : String,required : true}
	CountryInfo 					= new Schema
		CountryId 		:	{type : Number,required : true}
		Country 		:	{type : String,required : true}
		FIPS104 		:	{type : String,required : true}
		ISO2			:	{type : String,required : true}
		ISO3			:	{type : String,required : true}
		ISON			:	{type : String,required : true}
		Internet		:	{type : String,required : true}
	ZipInfo 					= new Schema
		Zipcode	 		:	{type : String,required : true}
		ZipCodeType 	:	{type : String,required : true}
		City 			:	{type : String,required : true}
		Lat				:	{type : Number,required : true}
		Long			:	{type : Number,required : true}
		Location		:	{type : String,required : true}
	LocationInfo 					= new Schema
		cityId	 		:	{type : String,required : false}
		ISO2 			:	{type : String,required : false}
		country			:	{type : String,required : false}
		region 			:	{type : String,required : false}
		city 			:	{type : String,required : false}
		postalCode 		:	{type : String,required : false}
		latitude		:	{type : Number,required : false}
		longitude		:	{type : Number,required : false}
		
	UniqueLocation		= new Schema
		_id 			:	{type : String,required : true}
		value			:	{type : String,required : true}

	mongoose.model "PostItem"					, PostItem
	mongoose.model "Photo"						, Photo
	mongoose.model "WishList"					, WishList
	mongoose.model "User"						, User
	mongoose.model "Group"						, Group
	mongoose.model "Role"						, Role
	mongoose.model "GroupUser"					, GroupUser
	mongoose.model "RoleGroup"					, RoleGroup
	mongoose.model "RoleUser"					, RoleUser
	mongoose.model "LoginToken"					, LoginToken
	mongoose.model "ShortKeyPostItemMapping"	, ShortKeyPostItemMapping
	mongoose.model "RatingComment"				, RatingComment
	mongoose.model "RatingCommentTopic"			, RatingCommentTopic
	mongoose.model "CityInfo"					, CityInfo
	mongoose.model "RegionInfo"					, RegionInfo
	mongoose.model "CountryInfo"				, CountryInfo
	mongoose.model "ZipInfo"					, ZipInfo
	mongoose.model "LocationInfo"				, LocationInfo
	mongoose.model "UniqueLocation"				, UniqueLocation
	next()
  
exports.defineModels = defineModels
