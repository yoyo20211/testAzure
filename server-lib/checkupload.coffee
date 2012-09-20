
Settings 		            = require 'settings'
path 			            = require 'path'
service 		            = require '../util/service'
Thoonk 			            = require("thoonk").Thoonk
thoonk                      = new Thoonk "localhost", "6379", 1
checkJob                    = thoonk.job 'checkJob' 
util   			            = require "util" 
mongoose 		            = require 'mongoose' 
models 			            = require '../models/models' 
logger                      = service.logger;
mailer                      = service.mailer;
PostItemModel               = service.PostItem
PhotoModel                  = service.Photo
socketIOMainChannel         = service.socketIOMainChannel
db 				            = null
checkList                   = []
settings 		            = new Settings(path.join(__dirname, '../config/environment.js')).getEnvironment();
socketIOURL                 = settings.socketIOURL
## We need socket client to inform the server about the newly added postitem.                            
io                          = require('socket.io-client')

run = ()-> 
    checkJob.get 0, (err, data, gid)->
        message = JSON.parse data
        if message.type is 'init'
            init message
        else
            check message

        checkJob.finish gid, (err, fid)->
            process.nextTick run
        , false, 'done'
              
                


checkJob.once "ready", ()->
	run()

init = (message)->
    checkList[message.id] = message.data

check = (message)->
    list = checkList[message.id]
    list[message.type].result = message.result
    list[message.type].data   = message.data
    list[message.type].processType   = message.processType
    
    ready = true

    if list.fields.has
        if list.fields.result is undefined
                ready = false

    if list.voice.has
        if list.voice.result is undefined
            ready = false

    if list.video.has
        if list.video.result is undefined
            ready = false

    for i in [0..4]
        if list['photo'+i].has
            if list['photo'+i].result is undefined
                ready = false

    if ready
        error = undefined
        await genMessage list, defer error
        
        if error is undefined
            err = undefined
            postitem = undefined
            await PostItemModel.findById list._id, defer err,postitem
            if postitem
                postitem.set 'status', 'published'
                await postitem.save defer err
                if err
                    data = 
                        "title" : list.title,
                        "result": 'publication of the posting item ------>'+ 'Error' +'\n'
                    mailer.sendWithTemplate(list.email, settings.mainEmailAccount, 'MeListing Item Posting is failure', 'posting-result-email-template.txt', data)
                    logger.log('info', ' (Posting module) posting process id '+list.processId+' can not to be published :\n'+err)
                else
                    logger.log('info', ' (Posting module) posting process id '+list.processId+' is published')
                    ## We need to emit ean event published for socket.io setup.
                    socket          = io.connect(socketIOURL + "/" +socketIOMainChannel, {"force new connection":true})
                    socket.emit("postitem:published", postitem)
                    socket.emit("disconnect", {})
                    socket.disconnect()
            else
                data = 
                        "title" : list.title,
                        "result": 'publication of the posting item ------>'+ 'Error' +'\n'
                mailer.sendWithTemplate(list.email, settings.mainEmailAccount, 'MeListing Item Posting is failure', 'posting-result-email-template.txt', data)
                logger.log('info', ' (Posting module) posting process id '+list.processId+' can not to be published :\n'+err)
        else
            mailer.sendWithTemplate(list.email, settings.mainEmailAccount, 'MeListing Item Posting is failure', 'posting-result-email-template.txt', error)
            logger.log('info', ' (Posting module) posting process id '+list.processId+' can not to be published because there is some error :')  

genMessage = (list,callback)->
        message = ''
        
        for i in [0..4]
            if list['photo'+i].has 
                if list['photo'+i].result is 'pass'
                    if list['photo'+i].processType isnt 'delete'
                        photoField=
                                    'image':list['photo'+i].data
                                    'createdDate':Date.now()
                        photoDoc = new  PhotoModel photoField
                        err = undefined
                        postitem = undefined
                        await PostItemModel.findById list._id, defer err,postitem
                        if postitem
                            photoDoc.set 'isPhotoProcessing',false
                            postitem.photos.push photoDoc
                            #numberOfPhotos = postitem.numberOfPhotos
                            #numberOfPhotos++
                            postitem.set 'numberOfPhotos',postitem.photos.length
                            await postitem.save defer err
                            if err
                                message += 'Uploading of photo name : '+list['photo'+i].name+' ------>'+ 'Error' +'\n';
                                logger.log('error', ' (Posting module) photo'+i+' process id '+list.processId+' error : \n'+err);
                            else
                                logger.log('info', ' (Posting module) photo'+i+' process id '+list.processId+' is success');
                        else
                            message += 'Uploading of photo name : '+list['photo'+i].name+' ------>'+ 'Error' +'\n';
                            logger.log('error', ' (Posting module) photo'+i+' process id '+list.processId+' error : \n'+ err);        
                    else
                        await PostItemModel.findById list._id, defer err,postitem
                        if postitem
                            photoStack = []
                            for photo in postitem.photos
                                if photo._id.toString() isnt list['photo'+i].data
                                    photo.set 'isPhotoProcessing',false
                                    photoStack.push photo

                            postitem.photos = photoStack
                            #numberOfPhotos = postitem.numberOfPhotos
                            #numberOfPhotos--
                            postitem.set 'numberOfPhotos',postitem.photos.length
                            await postitem.save defer err
                            if err
                                message += 'Uploading of photo name : '+list['photo'+i].name+' ------>'+ 'Error' +'\n';
                                logger.log('error', ' (Posting module) photo'+i+' process id '+list.processId+' error : \n'+err);
                            else
                                logger.log('info', ' (Posting module) photo'+i+' process id '+list.processId+' is success');
                        else
                            message += 'Uploading of photo name : '+list['photo'+i].name+' ------>'+ 'Error' +'\n';
                            logger.log('error', ' (Posting module) photo'+i+' process id '+list.processId+' error : \n'+ err);
                else
                    message += 'Uploading of photo name : '+list['photo'+i].name+' ------>'+ 'Error' +'\n';
                    logger.log('error', ' (Posting module) photo'+i+' process id '+list.processId+' error : \n'+ util.inspect(list['photo'+i].data));
                  
        if list.video.has
            if list.video.result is 'pass'
                err = undefined
                postitem = undefined
                await PostItemModel.findById list._id, defer err,postitem
                if postitem
                    postitem.set 'video', list.video.data
                    postitem.set 'isVideoProcessing',false
                    await postitem.save defer err
                    if err
                        message += 'Uploading of video ------>'+ 'Error' +'\n';
                        logger.log 'error', ' (Posting module) video process id '+list.processId+' error : \n'+err 
                    else
                        logger.log 'info', ' (Posting module) video process id '+list.processId+' is success' 
                else
                    message += 'Uploading of video ------>'+ 'Error' +'\n';
                    logger.log 'error', ' (Posting module) video process id '+list.processId+' error : \n'+err 
                       
            else
                message += 'Uploading of video ------>'+ 'Error' +'\n';
                logger.log 'error', ' (Posting module) video process id '+list.processId+' error : \n'+list.video.data 
          

        if list.voice.has
            if list.voice.result is 'pass'
                err = undefined
                postitem = undefined
                await PostItemModel.findById list._id, defer err,postitem
                if postitem
                    postitem.set 'voice',list.voice.data
                    postitem.set 'isVoiceProcessing',false
                    await postitem.save defer err
                    if err
                        message += 'Uploading of voice ------>'+ 'Error' +'\n';
                        logger.log 'error', ' (Posting module) voice process id '+list.processId+' error : \n'+err 
                    else
                        logger.log('info', ' (Posting module) voice process id '+list.processId+' is success');
                else
                    message += 'Uploading of voice ------>'+ 'Error' +'\n';
                    logger.log 'error', ' (Posting module) voice process id '+list.processId+' error : \n'+err 
                            
            else
                message += 'Uploading of voice ------>'+ 'Error' +'\n';
                logger.log 'error', ' (Posting module) voice process id '+list.processId+' error : \n'+list.voice.data 

        
        if message isnt ''
            data = 
                "title" : list.title,
                "result": message
            callback data
        else
            callback undefined

        



