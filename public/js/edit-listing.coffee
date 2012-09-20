#################################################################################
# Knockout.js is use to bind those dom elements in the page to values in this file.
#
# i.e. model and data-bind:visible.
#################################################################################
head.ready(() ->
    POSTITEM_DETAIL_INDEX       = 0
    PHOTOS_INDEX                = 1
    VIDEO_INDEX                 = 2
    VOICE_INDEX                 = 3
    $documentBody               = jQuery("body")
    postitem                    = JSON.parse(jQuery("div#current-postitem").text().trim())
    #################################################################################
    # Setup the tabs.
    #################################################################################
    postitemID                  = postitem._id
    map                         = null
    marker                      = null
    $tabs                       = jQuery("div#listing-edit").tabs({
        create: (event, ui) ->
            ##
            # Setup the postiem detail tab section.
            ##
            setTimeout(() -> 
                    setupMap()
                , 3000)
            event.preventDefault()
            $documentBody.on("modelInitialized", (event, model) ->
                setupUploaders(model)
            )
        show: (event, ui) ->
            event.preventDefault()
        cache: true,
        collapsible: false,
        select: (event, ui) ->
            index       = ui.index
            switch index
                when POSTITEM_DETAIL_INDEX
                    console.log "POSTITEM_DETAIL_INDEX"
                    #$documentBody.trigger("refreshMap")
                    # A hack to refresh the leaflet map - 
                    # http://stackoverflow.com/questions/10762984/leaflet-map-not-displayed-properly-inside-tabbed-panel
                    L.Util.requestAnimFrame(map.invalidateSize,map,!1,map._container)
                when PHOTOS_INDEX
                    console.log "PHOTOS_INDEX"
                when VIDEO_INDEX
                    console.log "VIDEO_INDEX"
                when VOICE_INDEX
                    console.log "VOICE_INDEX"
                else 
                    console.log "INDEX ERROR"
    })

    $tabs.tabs('select', POSTITEM_DETAIL_INDEX)
    ##
    # Utility functions for tabs init.
    ##
    setupMap = () ->
        map = L.map("item-detail-map", {doubleClickZoom: false}).setView(postitem.location, 8)
        L.tileLayer("http://{s}.tile.cloudmade.com/552ed20c2dcf46d49a048d782d8b37e6/997/256/{z}/{x}/{y}.png", {
            attribution: 'Map data &copy; <a href="http://openstreetmap.org">OpenStreetMap</a> contributors, <a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>, Imagery © <a href="http://cloudmade.com">CloudMade</a>',
            maxZoom: 18
        }).addTo(map)
        marker = L.marker(postitem.location, {draggable: true, clickable: true}).addTo(map)
        popup = L.popup()
        showLocation    = (event) ->
            target      = null
            if event.hasOwnProperty("target")
                target  = event.target
            latlng      = event.latlng or target.getLatLng()
            latitude    = latlng.lat
            longitude   = latlng.lng
            jQuery.ajax({
                url: "http://open.mapquestapi.com/geocoding/v1/reverse?lat={0}&lng={1}".format(latitude, longitude)
                , dataType: 'jsonp'
                , success:(response) ->
                    location        = response.results[0].locations[0] if response.results[0]
                    if location
                        neighborhood    = location.street or "Not Available"
                        city            = location.adminArea5 or ""
                        state           = location.adminArea3 or ""
                        country         = location.adminArea1 or ""
                        if city and country
                            map.closePopup()
                            popup
                                .setLatLng(latlng)
                                .setContent("The location clicked is {0}, {1}".format(city, country))
                                .openOn(map)
                            setTimeout(() ->
                                map.closePopup()
                            , 12000)
                        else
                            console.log "error"
                    else
                        console.log "error"
                , error:(error) ->
                    # TODO take care of the error.
                    alert("Error")
            })
        changeLocation  = (event) ->
            target      = null
            if event.hasOwnProperty("target")
                target  = event.target
            latlng      = event.latlng or target.getLatLng()
            latitude    = latlng.lat
            longitude   = latlng.lng
            jQuery.ajax({
                url: "http://open.mapquestapi.com/geocoding/v1/reverse?lat={0}&lng={1}".format(latitude, longitude)
                , dataType: 'jsonp'
                , success:(response) ->
                    location            = response.results[0].locations[0] if response.results[0]
                    if location
                        neighborhood    = location.street or "Not Available"
                        city            = location.adminArea5 or ""
                        state           = location.adminArea3 or city
                        country         = location.adminArea1 or ""
                        if city and country
                            map.closePopup()
                            popup
                                .setLatLng(latlng)
                                .setContent("You have updated your location to {0}, {1}".format(city, country))
                                .openOn(map)
                            setTimeout(() ->
                                map.closePopup()
                            , 12000)
                            marker.setLatLng(latlng)
                            model.location([latitude, longitude])
                            model.address.city(city)
                            model.address.state(state)
                            model.address.country(country)
                            model.address.neighborhood(neighborhood)
                        else
                            console.log "error"
                    else
                        console.log "error"
                , error:(error) ->
                    # TODO take care of the error.
                    alert("Error")
            }) 
        marker.on("dragend", changeLocation)
        marker.on("click", showLocation)
        map.on("click", showLocation)
        map.on("dblclick", changeLocation)

    setupUploaders = (model) ->
        ##
        # Setup the photo tab section.
        ##
        $photoFileUpload        = jQuery("input.media-input-listing-edit-photo")
        $photoFileUpload.kendoUpload({
            localization: {select: "Photos"},
            success: (event) -> onSuccess(event, "photos"),
            error: (event) -> onError(event, "photos"),
            upload: (event) -> onUpload(event, "photos"),
            select: (event) -> onSelect(event, "photos"),
            remove: (event) -> onRemove(event, "photos")
        })
        photoFileUploader       = $photoFileUpload.data("kendoUpload")
        $videoFileUpload        = jQuery("input#media-input-listing-video")
        $voiceFileUpload        = jQuery("input#media-input-listing-voice")
        ##
        # TODO Setup the handlers for file upload widget.
        # 
        # TODO take care of the error.
        ##
        numberOfPhotosUploaded  = model.numberOfPhotos()
        numberOfVideoUploaded   = model.video ? 1 : 0
        numberOfVoiceUploaded   = model.voice ? 1 : 0
        onSuccess   = (event, type) ->
            console.log type + " success" 
        onError     = (event, type) ->
            console.log type + " error"
        onUpload    = (event, type) ->
            files   = event.files
            console.log "select " + files + type
            switch type
                when "photos"
                    console.log "onUpload"
                when "video"
                    console.log "onUpload"
                when "voice"
                    console.log "onUpload"
                else 
                    console.log "error type is not of photos or video or voice."
        onSelect    = (event, type) ->
            files   = event.files
            len     = files.length
            console.log "select " + files + type
            switch type
                when "photos"
                    if  numberOfPhotosUploaded < 4
                        jQuery.each(files, (index, file) ->
                            if jQuery.inArray(file.extension.toLowerCase(), [".gif", ".png", ".jpeg", ".jpg", ".bmp"]) is -1
                                #$mediaError.html("<p>Photo has to be in gif or png or jpeg or bmp format.</p>").fadeIn(1500).delay(3500).fadeOut(1500)
                                event.preventDefault()
                            if file.size > 246800
                                console.log "file is too big"
                                #$mediaError.html("<p>Photo file is bigger than 2.5 mb limit.</p>").fadeIn(1500).delay(3500).fadeOut(1500)
                        )
                        numberOfPhotosUploaded = numberOfPhotosUploaded + len
                    else
                        #$mediaError.html("<p>Only 4 photos are allowed for the upload.</p>").fadeIn(1500).delay(3500).fadeOut(1500)
                        event.preventDefault()
                when "video"
                    if numberOfVideoUploaded < 1
                        jQuery.each(files, (index, file) ->
                            if jQuery.inArray(file.extension.toLowerCase(), [".mp4", ".mpeg", ".mov", ".x-msvideo", ".avi", ".msvideo", ".x-msvideo", ".3gpp", ".mpeg", ".quicktime", ".MP2P", ".MP1S", ".x-flv"]) is -1
                                #$mediaError.html("<p>Video recording has to be in the acceptable video formats i.e. mp4, mpeg, etc.</p>").fadeIn(1500).delay(3500).fadeOut(1500)
                                event.preventDefault()
                            if file.size > 1024000
                                console.log "file is too big"
                                #$mediaError.html("<p>Video file is bigger than 10 mb limit.</p>").fadeIn(1500).delay(3500).fadeOut(1500)
                                event.preventDefault()
                        )
                        numberOfVideoUploaded = numberOfVideoUploaded + len
                    else
                        #$mediaError.html("<p>Only 1 video is allowed for the upload.</p>").fadeIn(1500).delay(3500).fadeOut(1500)
                        event.preventDefault()
                when "voice"
                    if numberOfVoiceUploaded  < 1
                        jQuery.each(files, (index, file) ->
                            if jQuery.inArray(file.extension.toLowerCase(), [".mp3"]) is -1
                                #$mediaError.html("<p>Voice recording has to be in mp3 format.</p>").fadeIn(1500).delay(3500).fadeOut(1500)
                                event.preventDefault()
                            if file.size > 1024000
                                console.log "file is too big"
                                #$mediaError.html("<p>Voice file is bigger than 10 mb limit.</p>").fadeIn(1500).delay(3500).fadeOut(1500)
                                event.preventDefault()
                        )
                        numberOfVoiceUploaded = numberOfVoiceUploaded + len
                    else
                        #$mediaError.html("<p>Only 1 voice recording is allowed for the upload.</p>").fadeIn(1500).delay(3500).fadeOut(1500)
                        event.preventDefault()
                else 
                    console.log "error type is not of photos or video or voice."
        onRemove    = (event, type) ->
            files   = event.files
            len     = files.length
            switch type
                when "photos"
                    numberOfPhotosUploaded  = numberOfPhotosUploaded - len
                when "video"
                    numberOfVideoUploaded   = numberOfVideoUploaded - len
                when "voice"
                    numberOfVoiceUploaded   = numberOfVoiceUploaded - len
                else 
                    console.log "error type is not of photos or video or voice."
    #################################################################################
    # Setup the binding for the tab postitem detail edit.
    #################################################################################
    # TODO take care of the error.
    if not postitem
        console.log "error with parsing postitem"
        return
    model                       = ko.mapping.fromJS(postitem)
    previousPostItem            = postitem
    console.log "------------------ " + JSON.stringify(postitem.photos[0])
    console.log "------------------ " + JSON.stringify(model.photos())
    console.log model.exchangeOptions()
    ##
    # There is a bug in ko.mapping.  The photos array is not converted.
    ##
    #model.photos                = ko.observableArray([{}])
    #################################################################################
    # Setup the binding for validation.  We use knockout-validation.js
    #################################################################################
    ko.validation.rules.pattern.message = 'Invalid.'
    

    ko.validation.configure({
        registerExtenders: true,
        messagesOnModified: true,
        insertMessages: true,
        parseInputAttributes: true,
        messageTemplate: null
    })

    model.email.extend({email: true, required: true})
    model.itemDescription.extend({required: true, minLength: 10, notEqual: "click to edit"})
    model.category.extend({required: true, minLength: 3, notEqual: "click to edit"})
    model.price.extend({min: 0, number: true})
    model.errors = ko.validation.group(model);
    
    #################################################################################
    # Setup the model functions.
    #################################################################################
    model.numberOfProcessedPhotos       = ko.computed(() ->
        array                           = @photos()
        photos                          = _.reject(array, (photo) -> return _.isEmpty(photo) or photo is {} or photo is [{}])
        console.log "numberOfProcessedPhotos " + @photos().length
        return @photos().length                               
    , model)
    model.numberOfPhotosBeingProcessed  = ko.computed(() ->
        console.log "@numberOfPhotos() " + @numberOfPhotos()
        console.log "@numberOfProcessedPhotos() " + @numberOfProcessedPhotos()
        photosBeingProcessed            = @numberOfPhotos() - @numberOfProcessedPhotos()
        return "You have {0} file(s) being processed.".format(photosBeingProcessed )
    , model)
    model.exchangeOptionsString         = ko.computed(() ->
        return @exchangeOptions() or "n/a"                               
    , model)
    model.mainImageDisplay              = ko.computed(() ->
        len = @photos().length
        if len > 0
            return "/images/sampleImage_001_120x90.jpg" # this.photos()[0].image
        else
            #TODO define default image for display when none is uploaded.
            return "/images/sampleImage_001_120x90.jpg"                               
    , model)
    model.createdDate                   = model.createdDate.extend({
        isoDate: 'mm/dd/yyyy'
    })
    model.deletePhoto                   = (postitem, event) ->
        jQuery.confirm({
            'title'     : 'Delete Confirmation',
            'message'   : 'You are about to delete this item. <br />It cannot be restored at a later time! Continue?',
            'buttons'   : {
                'Yes'   : {
                    'class' : 'blue',
                    'action': () ->
                        console.log "yes"
                        console.log postitem
                        console.log event.currentTarget.id
                        photoID                 = event.currentTarget.id
                        photos                  = model.photos()
                        console.log "photos " + JSON.stringify(photos)
                        photos                  = _.reject(photos, (photo) -> return photo._id() is photoID or _.isEmpty(photo))
                        console.log JSON.stringify(photos)
                        model.photos(photos)
                },
                'No'    : {
                    'class' : 'gray',
                    'action': () -> {}  
                }
            }
        })
    
    model.deleteVideo               = (postitem, event) ->  
        console.log "deleteVideo"  
    
    model.deleteVoice               = (postitem, event) ->
        console.log "deleteVoice"
    
    model.updatePostItem            = (postitem, event) ->
        if model.errors() is 0
            alert('Thank you.')
        else 
            model.errors.showAllMessages(true)
        
        console.log ko.mapping.toJS(postitem)
        event.preventDefault()

    model.cancelUpdatePostItem      = (postitem, event) ->
        model                       = ko.mapping.fromJS(previousPostItem, postitem)
        model.errors.showAllMessages(false)
        location                    = model.location()
        map.setView(location, 8)
        marker.setLatLng(location)
        marker.update() 
        removeFilesFromUPloader()
        event.preventDefault()

    model.updateVideo               = (postitem, event) ->
        console.log "updateVideo"
        removeFilesFromUPloader()
        event.preventDefault()
    model.cancelUpdateVideo         = (postitem, event) ->
        console.log "cancelUpdateVideo"
        removeFilesFromUPloader()
        event.preventDefault()

    model.updateVoice               = (postitem, event) ->
        console.log "updateVoice"
        removeFilesFromUPloader()
        event.preventDefault()

    model.cancelUpdateVoice         = (postitem, event) ->
        console.log "cancelUpdateVoice"
        removeFilesFromUPloader()
        event.preventDefault()

    ##
    # A hack from http://www.telerik.com/community/forums/aspnet-mvc/upload/programmatically-remove-clear-uploaded-files.aspx.
    ##    
    removeFilesFromUPloader         = () ->
        setTimeout(() -> 
            jQuery("ul.t-upload-files").remove()
        , 1300)

    ko.applyBindings(model, jQuery("#listing-edit")[0])
    $documentBody.trigger("modelInitialized", model)
    $documentBody.off("modelInitialized")
)