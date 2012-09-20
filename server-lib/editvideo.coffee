http              = require 'http' 
GoogleClientLogin = require('googleclientlogin').GoogleClientLogin;
Settings 		  = require 'settings'
fs 				  = require 'fs'
path 		 	= require 'path'
service 		= require '../util/service'
Thoonk 			= require("thoonk").Thoonk
thoonk          = new Thoonk "localhost", "6379", 1
editVideoJob    = thoonk.job 'editVideoJob' 
util   			= require "util" 
mongoose 		= require 'mongoose' 
models 			= require '../models/models' 
logger          = service.logger
mailer          = service.mailer
PostItemModel   = service.PostItem
db 				= null

settings 		= new Settings(path.join(__dirname, '../config/environment.js')).getEnvironment();
run = ()-> 

        editVideoJob.get 0, (err, data, gid)->
            item = JSON.parse data
            console.log item
            editVideoJob.finish gid, (err, fid)->
                                process.nextTick run
            , false, 'pass'
            authentication item.processId, (err,authId)->
                if err 
                    logger.log 'error', ' (Editing module) edit video id '+item.processId+' error : \n'+err
                else
                    logger.log 'info', ' (Editing module) authentication to youtube process id '+item.processId+' is success'
                    editVideo item.files.videoFile, authId, item.processId,item._id, (err,link)->
                        if err 
                            message         = {}
                            message.id      = item.processId
                            message.type    = 'video'
                            message.result  = 'error'
                            message.data    = err
                            checkJob.publish JSON.stringify(message), (err, data, id)->
                                logger.log 'info', ' (Posting module) sent message id '+gid+' to the checking system' 
                            ,false, gid
                            editVideoJob.stall gid, (err, fid)->
                            	process.nextTick run
                            , false, 'error'
                        else
                            message         = {}
                            message.id      = item.processId
                            message.type    = 'video'
                            message.result  = 'pass'
                            message.data    = link
                            checkJob.publish JSON.stringify(message), (err, data, id)->
                                logger.log 'info', ' (Posting module) sent message id '+gid+' to the checking system' 
                            ,false, gid
                            videoJob.finish gid, (err, fid)->
                            	process.nextTick run
                            , false, 'pass'


editVideoJob.once "ready", ()->
	run()




editVideo = (incommingFile,authId,processId, objectId, callback)->
        if check incommingFile['mime'] 
            filePath = incommingFile.path
            fileReader = fs.createReadStream filePath, encoding: 'binary' 
            fileContent = ''
            fileReader.on 'data', (data)->
                fileContent += data;
            
            fileReader.on 'end', ()->
                xml =
                    '<?xml version="1.0"?>' +
                    '<entry xmlns="http://www.w3.org/2005/Atom" xmlns:media="http://search.yahoo.com/mrss/" xmlns:yt="http://gdata.youtube.com/schemas/2007">' +
                    '   <media:group>' + 
                    '       <media:title type="plain">' + incommingFile.filename + '</media:title>' +
                    '       <media:description type="plain">' + incommingFile.filename + '</media:description>' +
                    '       <media:category scheme="http://gdata.youtube.com/schemas/2007/categories.cat">' + 'People' + '</media:category>' +
                    '       <media:keywords>' + 'goods MeListing melisting' + '</media:keywords>' + 
                    '   </media:group>' + 
                    '</entry>';

                boundary = Math.random()
                postData = []
                part = ''

                part = "--" + boundary + "\r\nContent-Type: application/atom+xml; charset=UTF-8\r\n\r\n" + xml + "\r\n"
                postData.push new Buffer part, "utf8"

                part = "--" + boundary + "\r\nContent-Type: "+incommingFile.mime+"r\nContent-Transfer-Encoding: binary\r\n\r\n"
                postData.push new Buffer part, 'ascii' 
                postData.push new Buffer fileContent, 'binary' 
                postData.push new Buffer "\r\n--" + boundary + "--" , 'ascii' 

                postLength = 0
                postLength += postData[i].length for i in [0..postData.length-1]
                
                
                options = 
                  host: 'gdata.youtube.com'
                  port: 80,
                  path: '/feeds/api/users/default/uploads?alt=json'
                  method: 'PUT'
                  headers: 
                        'Authorization': 'GoogleLogin auth=' + authId
                        'GData-Version': '2'
                        'X-GData-Key': 'key=' + settings.googleDevelopKey
                        'Slug': 'video.mp4'
                        'Content-Type': 'multipart/related; boundary="' + boundary + '"'
                        'Content-Length': postLength
                        'Connection': 'close'
                    
                

                req = http.request options, (res)->
                    res.setEncoding('utf8');

                    response = '';

                    res.on 'data', (chunk)->
                        response += chunk;

                    res.on 'end', ()->    
                        try
                            response = JSON.parse response
                            fs.unlink(filePath);
                            callback undefined,response.entry.link[0].href
                               
                        catch e
                            err="unable to upload the file to youtube \n youtube_response: "+response;
                            callback(err,undefined);
                            # fs.unlink(filePath);
                   

                
                req.write postData[i] for i in [0..postData.length-1]
                

                req.on 'error', (err)->
                  callback(err,undefined);
                  

                req.end()
        else
            callback 'This file type of '+processId+' is not a video file'
       
check = (mime)->
        if mime is 'video/mp4' or 
        mime is 'video/x-msvideo' or 
        mime is 'video/avi' or  
        mime is 'video/msvideo' or
        mime is 'video/x-msvideo' or 
        mime is 'video/3gpp' or 
        mime is 'video/mpeg' or 
        mime is 'video/quicktime' or 
        mime is 'video/MP2P' or 
        mime is 'video/MP1S' or
        mime is 'video/x-flv'
            return true
        else
            return false

authentication = (processId,callback)->
        googleAuthentication = new GoogleClientLogin  
                                                      email: settings.youtubeUsername
                                                      password: settings.youtubePassword
                                                      service: 'youtube'
                                                      accountType: GoogleClientLogin.accountTypes.google
                                                    
         
        googleAuthentication.on GoogleClientLogin.events.login, ()->
            callback undefined,googleAuthentication.getAuthId()
         
        googleAuthentication.on GoogleClientLogin.events.error, (e)->
            callback e.message,undefined
         
        googleAuthentication.login()
    

