
Settings 		= require 'settings' 
path 			= require 'path' 
service 		= require '../util/service' 
util   			= require "util" 
fs              = require 'fs'
mongoose 		= require 'mongoose' 
models 			= require '../models/models' 
logger          = service.logger 
PostItemModel   = service.PostItem
db 				= null

Thoonk          = require("thoonk").Thoonk
thoonk          = new Thoonk "localhost", "6379", 1
fieldsJob       = thoonk.job 'fieldsJob' 
voiceJob        = thoonk.job 'voiceJob' 
videoJob        = thoonk.job 'videoJob' 
photoJob        = thoonk.job 'photoJob'
checkJob        = thoonk.job 'checkJob'
postingJob      = thoonk.job 'postingJob'

settings 		= new Settings(path.join(__dirname, '../config/environment.js')).getEnvironment();


posting = ()-> 
        postingJob.get 0, (err, data, gid)->
            item = JSON.parse data
            initCheckJob item, (postItem,postingInformation)->
                logger.log 'info', ' (Posting module) posting id '+postItem.processId+' is success! and start uploading files' 
                deployUploading postItem,postingInformation
                postingJob.finish gid, (err, fid)->
                    process.nextTick posting
                , false, 'pass'
          


postingJob.once "ready", ()->
    posting()

initCheckJob = (item,callback)->
    checklist               = {}
    checklist.title         = item.fields.title
    checklist.email         = item.fields.email
    checklist.processId     = item.processId
    checklist._id           = item._id

    checklist.fields        = {}
    if item.processType is undefined
        checklist.fields.has    = true
    else
        checklist.fields.has    = false
    checklist.fields.result = undefined
    checklist.fields.data   = undefined

    checklist.voice         = {}
    checklist.voice.has     = false
    if item.files.voiceFile
        if item.files.voiceFile.size!=0 
            checklist.voice.has     = true
            checklist.voice.result  = undefined
            checklist.voice.data    = undefined
        else
            fs.unlink item.files.voiceFile.path

    checklist.video         = {}
    checklist.video.has      = false
    if item.files.videoFile
        if item.files.videoFile.size!=0 
            checklist.video.has     = true
            checklist.video.result  = undefined
            checklist.video.data    = undefined
        else
            fs.unlink item.files.videoFile.path

    for i in [0..4]
        checklist['photo'+i] = {}
        checklist['photo'+i].has = false
        if eval 'item.files.photoFile'+i
            if eval('item.files.photoFile'+i+'.size')!=0
                checklist['photo'+i].has     = true
                checklist['photo'+i].name    = eval 'item.files.photoFile'+i+'.name'
                checklist['photo'+i].result  = undefined
                checklist['photo'+i].data    = undefined
            else
                fs.unlink(eval('item.files.photoFile'+i+'.path'));
                
    init_data = {}
    init_data.type = 'init'
    init_data.id   = item.processId
    init_data.data = checklist
    logger.log 'info', ' (Posting module) add checking process id '+item.processId+' to the posting system'
    checkJob.publish JSON.stringify(init_data), (err, data, id)-> 
        callback(item,init_data)
    ,false, item.processId


deployUploading = (item,postingInformation)->
            if item.processType is undefined
                fieldsJob.publish JSON.stringify(item) , (err, data, id)->
                      logger.log('info', ' (Posting module) save form process id '+item.processId+' to database'); 
                ,false, 'field_'+item.processId
    
            if postingInformation.data.voice.has
                voiceJob.publish JSON.stringify(item), (err, data, id)->
                    logger.log 'info', ' (Posting module) add voice process id '+item.processId+' to the voice uploading system' 
                ,false, 'voice_'+item.processId
                logger.log 'info', ' (Posting module) a temporary voice of process id '+item.processId+' is '+item.files.voiceFile.path 
            
            if postingInformation.data.video.has
                videoJob.publish JSON.stringify(item), (err, data, id)->
                    logger.log 'info', ' (Posting module) add video process id '+item.processId+' to the video uploading system' 
                ,false, 'video_'+item.processId
                logger.log 'info', ' (Posting module) a temporary video of process id '+item.processId+' is '+item.files.videoFile.path 
     
            for i in [0..4]
                if postingInformation.data['photo'+i].has
                    photoData = {}
                    photoData._id = item._id
                    photoData.processId = item.processId
                    photoData.photoId = item.photoId
                    photoData.processType = item.processType
                    photoData.photos= {}
                    photoData.photos= eval('item.files.photoFile'+i)
                    photoJob.publish JSON.stringify(photoData), (err, data, id)->
                            logger.log 'info', ' (Posting module) add photo process id '+id+' to the photo uploading system' 
                    ,false, 'photo_'+i+'_'+item.processId
                    logger.log 'info', ' (Posting module) a temporary photo of process id '+'photo_'+i+'_'+item.processId+' is '+photoData.photos.path 
                

    

