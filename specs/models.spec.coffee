express     = require 'express'
_           = require 'underscore'
async       = require 'async'      
models      = require '../models/models'
mongoose    = require 'mongoose'
db          = null

app = express.createServer()

models.defineModels(mongoose, 
  ->
      app.PostItem      = mongoose.model('PostItem')
      app.User          = mongoose.model('User')
      app.LoginToken    = mongoose.model('LoginToken')
      app.Photo         = mongoose.model('Photo')
      db                = mongoose.connect('mongodb://localhost/db')
)

people                  = [{ 
       email        : 'user2@user.com',
       password     : 'password',
       location     : [12, 21],
       role         : 'role'
    },
    { 
       email        : 'user3@user.com',
       password     : 'password',
       location     : [12, 21],
       role         : 'role'
    }]

photo                   = { 'image':'https://www.ai-class.com/course/video/quizquestion/26', 'imageThumbnail':'https://www.ai-class.com/course/video/quizquestion/26' }

doc                     = new mongoose.Collection 'app.User', db


       
describe 'Test saving of PostItem', ->
    @item = null
    beforeEach () ->
        console.log 'beforeEach Test saving of PostItem'
        @item = {
            title             : 'title',
            username          : 'wpoosanguansit',
            itemDescription   : 'description',
            price             : 10.00,
            category          : 'Others',
            email             : 'email@email.com',
            showEmail         : true,
            exchangeOptions   : ['pickup'],
            address           : { country : 'usa', state : 'illinoi', city : 'chicago', neighborhood : 'down town' },
            location          : [12, 21],
            status            : 'published',
            video             : 'https://www.ai-class.com/course/video/quizquestion/26',
            voice             : 'https://www.ai-class.com/course/video/quizquestion/26',
            userRating        : '2'
        }
    it 'should save the PostItem and assign the shortkey', ->
      console.log 'In Test saving of PostItem'
      for i in [1..1]
        console.log i  
        @postItem   = new app.PostItem @item
        @photo      = new app.Photo photo
        @photo.save((err, result) -> console.log err if err)
        @postItem.photos.push(@photo)
        #@postItem.location[0]['latitude']
        #@postItem.location[0]['longitude']
        @postItem.save((err, result) ->
          console.log err if err
          expect(result.id).toBeDefined()
          #expect(result.shortkey).toBeDefined()
          #expect(result.location[0]['latitude']).toEqual(-91)
          #expect(result.location[0]['longitude']).toEqual(-180)
          expect(result.photos.length).toEqual(1)
          #expect(result.photos[0].image).toBeDefined()
          console.log result.photos[0].image + " photo image"
          asyncSpecDone();
        )
      asyncSpecWait()
  
  afterEach () ->
      console.log 'afterEach Test saving of PostItem'
      app.PostItem.find({}, 
        (err, postitems) ->
          console.log err if err
          #for item in postitems
            #console.log item
            #console.log 'removing item ' + item._id
            #item.remove((err) -> console.log(err) if err)
      )

describe 'Test LoginToken', ->
  loginToken = null   
  beforeEach () ->
      loginToken = new app.LoginToken({ username: "username", rememberme: true
                                  , address: { city: "address?.city", state: "address?.state", country: "address?.country"
                                  , "neighborhood: address?.neighborhood" }
                                  , location: [ 1, 2]})
  it 'should save the login token', ->
      loginToken.save((err, token) ->
          #TODO take care of the err.
          console.log err if err
      )
  afterEach () ->
      app.LoginToken.find({},
        (err, tokens) ->
          for token in tokens
            #token.remove((err) -> console.log(err) if err)
            console.log 'remove token'
      )