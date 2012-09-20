
Settings 		= require "settings" 
path 			= require "path" 
service 		= require "../util/service" 
util   			= require "util" 

mongoose 		= require "mongoose" 
models 			= require "../models/models" 
logger          = service.logger 
PostItemModel   = service.PostItem
db 				= null

Thoonk          = require("thoonk").Thoonk
thoonk          = new Thoonk "localhost", "6379", 1
fieldsJob       = thoonk.job "fieldsJob"
checkJob        = thoonk.job "checkJob"

settings 		= new Settings(path.join(__dirname, "../config/environment.js")).getEnvironment();


saveDB = ()-> 
        fieldsJob.get 0, (err, data, gid)->
            item = JSON.parse data
            saveProcess item, (err)->
                if(err)
                    message         = {}
                    message.id      = item.processId
                    message.type    = "fields"
                    message.result  = "error"
                    message.data    = err
                    checkJob.publish JSON.stringify(message), (err, data, id)->
                        logger.log "info", " (Posting module) sent message id "+gid+" to the checking system" 
                    ,false, gid
                    logger.log("error", " (Posting module) cannot save a posting data id "+item.processId+" to database : \n "+err);
                    fieldsJob.stall gid, (err, fid)->
                        process.nextTick saveDB
                    , false, "pass"
                   
                else
                    message = {}
                    message.id = item.processId
                    message.type    = "fields"
                    message.result  = "pass"
                    message.data    = item._id
                    checkJob.publish JSON.stringify(message), (err, data, id)->
                        logger.log "info", " (Posting module) sent message id "+gid+" to the checking system" 
                    ,false, gid
                    logger.log("info", " (Posting module) save a posting data id "+item.processId+" to database successfully");
                    fieldsJob.finish gid, (err, fid)->
                        process.nextTick saveDB
                    , false, "pass"
                    
               


fieldsJob.once "ready", ()->
	saveDB()


saveProcess = (item,callback)->
            logger.log "info", " (Posting module) start insert posting data id "+item.processId+" to database"
            fields = item.fields;
            fields.exchangeOptions = fields["exchange-options"]
            if fields["exchange-options-other-text"] isnt ""
             fields.exchangeOptions.push fields["exchange-options-other-text"]
            fields.location = [fields.longitude,fields.latitude]
            location= fields["city"].split(",")
            fields.address = {}

            if location.length is 3
                fields.address.city = location[0]
                fields.address.state = location[1]
                fields.address.country = location[2]
                fields.address.neighborhood = fields["neighborhood"]
            else
                fields.address.city = location[0];
                fields.address.state = location[0];
                fields.address.country = location[1];
                fields.address.neighborhood = fields["neighborhood"]

            delete fields["neighborhood"]
            delete fields["longitude"]
            delete fields["latitude"]
            delete fields["processId"]

            delete fields["exchange-options-other-text"]
            delete fields["exchange-options"]
            delete fields["photoTitle"+i] for i in [0..4]
            delete fields["photoFile"+i] for i in [0..4]
            
            delete fields.videoFile
            delete fields.voiceFile
            delete fields.neighborhood
            delete fields.city
            delete fields.country
            delete fields.user

            postinfo = new PostItemModel fields
            postinfo.set "status", "draft"
            postinfo.set "video", "http://www.listsil.com"
            postinfo.set "voice", "http://www.listsil.com"
            postinfo.set "_id", item._id
            postinfo.save (err)->
                if (err)
                    iserror=true;
                    errorText = service.interpretError(err);
                    callback(err)
                else
                    callback(null)

