##
# This will serve as the main file that we configure the server for api access using restify.
#
##
require.paths.unshift('./server-lib/')
require.paths.unshift('./node_modules/rxjs-node/')
require.paths.unshift('./util/')

db                  = require 'FastLegs'

connectionParams    = {
	       user		   : 'postgres',
	       password	   : 'postgres',
	       database	   : 'postgres',
	       host		   : 'localhost',
	       port		   :  5432	
}

db.connect(connectionParams)

##post = db.Base.extend({
##  tableName: 'posts',
##  primaryKey: 'id'
##})

##post.create({ title: 'Some Title 1', body: 'Some body 1' }, (err, results) -> console.log results)

restify 	 	= require 'restify'

server 		 	= restify.createServer();

authenticate 	= (req, res, next) -> 
							console.log('authenticate is called')
							next()

authorize 		= (req, res, next) -> 
							console.log('authorize is called')
							next()

audit 			= (req, res, next) -> 
							console.log('this is called')
							next()

preprocessor 	= [authenticate, authorize]

postprocessor 	= [audit]

server.get('/postitem/:country/:state/:city/:neighborhood/', 
	(req, res) ->
  		res.send(200, { id: req.uriParams.id })
)

server.get('/postitem/:id/', 
	(req, res) ->
  		res.send(200, { id: req.uriParams.id })
)


formaline = require('./node_modules/formaline/index')

server.post('/postitem/',  preprocessor, 
	(req, res, next) ->
        @req            = req
        @res            = res
        @next           = next
        @receivedFields = {}
        @currFile       = null
        @config         = {
                holdFilesExtensions : true,
                    #specify a path, with at least a trailing slash
                    #default is /tmp/ -->
                uploadRootDir : '/tmp/',
                    #default is false
                    #to create and check directories existence in the sync way
                mkDirSync : false,
                    #retrieve session ID for creating unique upload directory for authenticated users
                    #the upload directory gets its name from the returned session identifier,
                    #and will remain the same across multiple posts ( for the authenticated user with this session identifier )
                    #this function have to return the request property that holds session id 
                    #the returned session id param, must contain a String, not a function or an object 
                    #the function takes http request as a parameter at run-time 
                getSessionID : (req) -> req?.session?.id,
                    #default is 120000 milliseconds ( default nodeJS timeout for connection requests )
                    #the client connection is closed after the specified milliseconds ( minimum is 100 millisecs )
                requestTimeOut : 5000, # 5 secs
                    #default is true
                    #when a fatal exception was thrown, the client request is resumed instead of immediately emitting 'loadend' event
                    #if false, the client request will be never resumed, the 'loadend' event will be emitted and the module doesn't handle the request anymore  
                resumeRequestOnError : true,
                    #default is false
                    #return sha1 digests for files received?
                    #turn off for better perfomances
                sha1sum : false,
                    #switch on/off 'fileprogress' event
                    #default is false
                    #it serves to monitor the progress of the file upload
                    #and also to move the data to another stream, while the file is being uploaded 
                emitFileProgress : false,
                    #switch on/off 'progress' event
                    #default is false, or integer chunk factor, 
                    #every n chunk emits a dataprogress event:  1 + ( 0 * n ) 1 + ( 1 * n ), 1 + ( 2 * n ), 1 + ( 3 * n ), 
                    #minimum factor value is 2 
                emitProgress : false, # 3, 10, 100
                    #max bytes allowed for file uploads ( multipart/form-data ), it is a writing threshold, this is the max size of bytes written to disk before stopping
                uploadThreshold : 1024 * 1024 * 1024 ,# bytes
                    #max bytes allowed for serialized fields, it limits the parsing of data received with serialized fields ( x-www-urlencoded ) 
                    #when it was exceeded, no data was returned 
                serialzedFieldThreshold : 1024 * 1024 * 1024,
                    #max bytes allowed for a single file
                maxFileSize : 1024 * 1024 * 1024, # bytes, default 1GB
                    #default is false, bypass content-length header value ( it must be present, otherwise an 'error'->'header' will be emitted ), 
                    #also if it exceeds max allowable bytes; the module continues to write to disk until |uploadThreshold| bytes are written. 
                    #if true ->  when headers content length exceeds uploadThreshold, module stops to receive data
                checkContentLength : false,
                    #default is false
                    #remove file not completed due to uploadThreshold, 
                    #if true formaline emit fileremoved event, 
                    #otherwise return a path array of incomplete files 
                removeIncompleteFiles : true,
                    #default is 'debug:off,1:on,2:on,3:off,4:off,console:on,file:off,record:off';
                    #enable various logging levels
                    #it is possible to switch on/off one or more levels at the same time
                    #debug: 'off' turn off logging
                    #file: 'on' --> create a log file in the current upload directory with the same name and .log extension
                    #console: 'off' --> disable console log output 
                    #record: 'on' --> record binary data from client request
                    #See the Readme!
                logging : {'debug:on,1:on,2:off,3:off,4:off,console:on,file:off,record:off'}, # <-- turn off 2nd level to see only warnings, and parser overall results

                    #listeners
                listeners : {
                    'message'       : (json)      		-> {
                    },
                    'error'         : (json)      		-> {json:{ type: '..', isupload: true , msg: '..', fatal: true}
                    },
                    'abort'         : (json)      		-> {   
                    },
                    'timeout'       : (json)      		-> {   
                    },
                    'loadstart'     : (json)      		-> {
                    },
                    'fileprogress'  : (json, payload)	-> { 
                        #json is the same for 'load' event ( when a file was received, see Readme ) , 
                        #'payload' is a binary Buffer
                        #you can direct the data payload to another stream, while the file is being uploaded   
                    },
                    'progress'      : (json)	      	-> {                              
                    },
                    'load'          : (json)     	 	-> {
                        
                    },
                    'loadend'       : (json, res, cback) -> {
                        
                    }
                }
        } #end config obj   
        form = new formaline(@config)
        form.parse(@req, @res, null) 
)

server.del('/postitem/:id/',  preprocessor, postprocessor)

server.listen(8080);
