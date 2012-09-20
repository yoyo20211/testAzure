Alleup          = require 'alleup' 
Settings 		= require 'settings'
fs 				= require 'fs'
path 			= require 'path'
service 		= require '../util/service'
Thoonk 			= require("thoonk").Thoonk
thoonk          = new Thoonk "localhost", "6379", 1
photoJob        = thoonk.job 'photoJob'
checkJob        = thoonk.job 'checkJob'
util   			= require "util" 
mongoose 		= require 'mongoose' 
models 			= require '../models/models' 
logger          = service.logger
mailer          = service.mailer
PostItemModel   = service.PostItem
db 				= null

settings 		= new Settings(path.join(__dirname, '../config/environment.js')).getEnvironment();
alleup          = new Alleup
                             storage : "dir" 
                             config_file: "config/photo_upload_config.json"
                            

run = ()-> 

        photoJob.get 0, (err, data, gid)->
            error_message = ''
            photoData = JSON.parse data
            if photoData.processType is "delete"
                logger.log 'info', ' (Posting module) process delete photo id '+gid 
                deletePhoto gid,photoData._id,photoData.photoId, (err,photoId)->
                    if(err)
                        message = {}
                        temp = gid.split('_');
                        message.id = photoData.processId
                        message.type = temp[0]+temp[1];
                        message.result  = 'error'
                        message.processType = 'delete'
                        message.data    =  err
                        checkJob.publish JSON.stringify(message), (err, data, id)->
                            logger.log 'info', ' (Posting module) sent message id '+gid+' to the checking system' 
                        ,false, gid

                        photoJob.stall gid, (err, fid)->
                            process.nextTick run
                        , false, 'error'
                    else
                        message = {}
                        temp = gid.split('_');
                        message.id = photoData.processId
                        message.type = temp[0]+temp[1];
                        message.result  = 'pass'
                        message.processType = 'delete'
                        message.data    =  photoId
                        checkJob.publish JSON.stringify(message), (err, data, id)->
                            logger.log 'info', ' (Posting module) sent message id '+gid+' to the checking system' 
                        ,false, gid
                        
                        photoJob.finish gid, (err, fid)->
                            process.nextTick run
                        , false, 'pass'
            else
                upload photoData.photos, gid,photoData._id, (err,link)->
                    if(err)
                        message = {}
                        temp = gid.split('_');
                        message.id = photoData.processId
                        message.type = temp[0]+temp[1];
                        message.result  = 'error'
                        message.data    =  err
                        checkJob.publish JSON.stringify(message), (err, data, id)->
                            logger.log 'info', ' (Posting module) sent message id '+gid+' to the checking system' 
                        ,false, gid

                        photoJob.stall gid, (err, fid)->
                            process.nextTick run
                        , false, 'error'
                    else
                        message = {}
                        temp = gid.split('_');
                        message.id = photoData.processId
                        message.type = temp[0]+temp[1];
                        message.result  = 'pass'
                        message.data    =  link
                        checkJob.publish JSON.stringify(message), (err, data, id)->
                            logger.log 'info', ' (Posting module) sent message id '+gid+' to the checking system' 
                        ,false, gid
                        
                        photoJob.finish gid, (err, fid)->
                            process.nextTick run
                        , false, 'pass'


photoJob.once "ready", ()->
	run()

deletePhoto = (processId, itemId, photoId, callback)->
    PostItemModel.findOne {_id:itemId}, (err, postitem)->
        if err
            callback err,undefined
        else
            for photo in postitem.photos
                if photo._id.toString() is photoId
                    photoPath = photo.image.split('/')
                    photoPath = photoPath[photoPath.length-1]
                    photoPath = photoPath.substring(0,photoPath.length-1)
                    err = undefined
                    await alleup.remove photoPath, defer err
                    if err
                        callback err,undefined
                    else
                        callback undefined, photoId
                    break;


upload = (incommingFile,processId, objectId, callback)->
    if check incommingFile['mime']
        alleup.makeVariants incommingFile, (err, file)->
            if err 
                callback err,undefined
            else
                callback undefined, file
                
             
    else
        callback 'This file type of process id: '+processId+' is not a photo file',undefined


check = (mime)->
        if mime is 'image/jpeg' or mime is 'image/png' or mime is 'image/gif'
            return true
        else
            return false

