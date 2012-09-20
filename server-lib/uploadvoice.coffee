
Settings 		= require 'settings'
fs 				= require 'fs'
path 			= require 'path'
service 		= require '../util/service'
Thoonk 			= require("thoonk").Thoonk
thoonk          = new Thoonk "localhost", "6379", 1
util   			= require "util" 
voiceJob 		= thoonk.job 'voiceJob'
checkJob        = thoonk.job 'checkJob'
mongoose 		= require 'mongoose'
models 			= require '../models/models'
logger          = service.logger
mailer          = service.mailer
PostItemModel   = service.PostItem
db 				= null

settings 		= new Settings(path.join(__dirname, '../config/environment.js')).getEnvironment();

run = ()-> 
        voiceJob.get 0, (err, data, gid)->
            item = JSON.parse data
            if item.processType is "delete"
                logger.log 'info', ' (Posting module) process delete voice id '+gid 
                deleteVoice item.processId, item._id, (err,link)->
                    if(err)
                        message         = {}
                        message.id      = item.processId
                        message.type    = 'voice'
                        message.result  = 'error'
                        message.data    = err
                        checkJob.publish JSON.stringify(message), (err, data, id)->
                            logger.log 'info', ' (Posting module) sent message id '+gid+' to the checking system' 
                        ,false, gid
                        voiceJob.stall gid, (err, fid)->
                            process.nextTick run
                        , false, 'error'
                    else
                        message         = {}
                        message.id      = item.processId
                        message.type    = 'voice'
                        message.result  = 'pass'
                        message.data    = link
                        checkJob.publish JSON.stringify(message), (err, data, id)->
                            logger.log 'info', ' (Posting module) sent message id '+gid+' to the checking system' 
                        ,false, gid
                        
                        voiceJob.finish gid, (err, fid)->
                            process.nextTick run
                        , false, 'pass'
            else
                upload item.files.voiceFile, item.processId,item._id, (err,link)->
                    if(err)
                        message         = {}
                        message.id      = item.processId
                        message.type    = 'voice'
                        message.result  = 'error'
                        message.data    = err
                        checkJob.publish JSON.stringify(message), (err, data, id)->
                            logger.log 'info', ' (Posting module) sent message id '+gid+' to the checking system' 
                        ,false, gid
                        voiceJob.stall gid, (err, fid)->
                        	process.nextTick run
                        , false, 'error'
                    else
                        message         = {}
                        message.id      = item.processId
                        message.type    = 'voice'
                        message.result  = 'pass'
                        message.data    = link
                        checkJob.publish JSON.stringify(message), (err, data, id)->
                            logger.log 'info', ' (Posting module) sent message id '+gid+' to the checking system' 
                        ,false, gid
                        
                        voiceJob.finish gid, (err, fid)->
                        	process.nextTick run
                        , false, 'pass'


voiceJob.once "ready", ()->
	run()

deleteVoice =  (processId,itemId, callback)->
    PostItemModel.findOne {_id:itemId}, (err, item)->
        if err
            callback err,undefined
        else
            voicePath = item.voice.split('/')
            voicePath = voicePath[voicePath.length-1]
            voicePath = './public/data/voice/'+voicePath.substring(0,voicePath.length-1)
            fs.unlink voicePath, (err)->
                if err
                    callback err,undefined
                else
                    callback undefined,'http://www.melisting.com'
                            


upload = (incommingFile,processId, objectId, callback)->
        if check incommingFile['mime']
            new_file = Math.round new Date().getTime()
            ext = setExtension incommingFile['mime']
            new_file += ext
            
            fs.rename incommingFile.path, './public/data/voice/'+new_file, (err)-> 
                if err
                    callback err,undefined
                else
                    callback undefined, settings.mainURL+'/data/voice/'+new_file

        else
            callback('This file type of '+processId+' is not a voice file',undefined);


check = (mime)->
        if mime is 'audio/x-wav' or mime is 'audio/mp3' or mime is 'audio/x-ms-wma' or mime is 'audio/mpeg' or mime is 'audio/mpeg3' or mime is 'audio/x-mpeg-3'
            return true
        else
            return false

setExtension = (content_type)->

        switch content_type 
            when 'audio/x-wav'then ext = '.wav'
            when 'audio/x-ms-wma' then ext = '.wma'
            when 'audio/mpeg' then ext = '.mp3'
            when 'audio/mpeg3' then ext = '.mp3'
            when 'audio/x-mpeg-3' then ext = '.mp3'
            when 'audio/mp3' then ext = '.mp3'

        return ext;


