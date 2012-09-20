
    #########################################################################################
    # The main script in the main page.
    #########################################################################################


    username    = null
    key         = "key" + Math.floor(Math.random() * 100000000 % 100000000)

    jQuery.noConflict()
    #################################################################################
    # Setup X domain rpc.
    #################################################################################
    # rpc = new easyXDM.Rpc({
    #     remote: "http://58.185.193.190:7575/js/easyXDM/cors/index.html",
    #     remoteHelper: "http://58.185.193.190:7575/js/easyXDM/name.html",
    #     swf: "http://58.185.193.190:7575/js/easyXDM/easyxdm.swf",
    #     local: "http://58.185.193.190:7575/js/easyXDM/name.html"
    # },
    rpc = new easyXDM.Rpc({
        remote: "http://listingserver.cloudapp.net/js/easyXDM/cors/index.html",
        remoteHelper: "http://listingserver.cloudapp.net/js/easyXDM/name.html",
        swf: "http://listingserver.cloudapp.net/js/easyXDM/easyxdm.swf",
        local: "http://listingserver.cloudapp.net/js/easyXDM/name.html"
    },
    {
        remote: { request: {} }
    })
    #################################################################################
    # State Abbreviation utility for use in form sign up address and posting.
    #################################################################################
    abbreviatedStateName = { "alabama": "AL", "alaska": "AK" , "arizona": "AZ"
        , "arkansas": "AR"      , "california": "CA"            , "colorado": "CO"
        , "connecticut": "CT"   , "delaware": "DE"              , "district of columbia": "DC"
        , "florida": "FL"       , "georgia": "GA"               , "hawaii": "HI"
        , "idaho": "ID"         , "illinois": "IL"              , "indiana": "IN"
        , "iowa": "IA"          , "kansas": "KS"                , "kentucky": "KY"
        , "louisiana": "LA"     , "maine": "ME"                 , "maryland": "MD"
        , "massachusetts": "MA" , "michigan": "MI"              , "minnesota": "MN"
        , "mississippi": "MS"   , "missouri": "MO"              , "montana": "MT"
        , "nebraska": "NE"      , "nevada": "NV"                , "new hamspire": "NH"
        , "new jersey": "NJ"    , "new mexico": "NM"            , "new york": "NY"
        , "north carolina": "NC", "north dakota": "ND"          , "ohio": "OH"
        , "oklahoma": "OK"      , "oregon": "OR"                , "pennsylvania": "PA"
        , "rhode island": "RI"  , "south carolina": "SC"        , "south dakota": "SD"
        , "tennessee": "TN"     , "texas": "TX"                 , "utah": "UT"
        , "vermont": "VT"       , "virginia": "VA"              , "washington": "WA"
        , "west virginia": "WV" , "wisconsin": "WI"             , "wyoming": "WY"
    }

    #################################################################################
    # Setup form validators.
    # TODO should try to get rid of duplicate in account-settings.
    #################################################################################
    validateEmail       = (email) ->
        reEmail         = /^[A-Za-z0-9][a-zA-Z0-9._-][A-Za-z0-9]+@([a-zA-Z0-9.-]+\.)+[a-zA-Z0-9.-]{2,4}$/
        return email?.match(reEmail)
    validateUsername    = (username) ->
        return (username?.length >= 6 and username.length <= 18)
    validatePassword    = (password) ->
        strongRegex     = new RegExp("^(?=.{8,})(?=.*[A-Z])(?=.*[a-z])(?=.*[0-9])(?=.*\\W).*$", "g")
        mediumRegex     = new RegExp("^(?=.{7,})(((?=.*[A-Z])(?=.*[a-z]))|((?=.*[A-Z])(?=.*[0-9]))|((?=.*[a-z])(?=.*[0-9]))).*$", "g")
        enoughRegex     = new RegExp("(?=.{6,}).*", "g")
        return strongRegex.test(password) || mediumRegex.test(password) || enoughRegex.test(password)
    validateCountry     = (country) ->
        return true
    validateCity        = (cityAndState) ->
        @stack = parseCityAndState(cityAndState)
        #we only allow the format to be City, State, Country or City/State, Country.
        if @stack.length is 1 or @stack.length is 2
            return true
        return false
    validateTitle       = (title) ->
        return title?.length > 5
    validateDescription = (description) ->
        return description?.length > 5
    validatePrice       = (price) ->
        return price isnt "" and isNumber(price)
    validateCategory    = (category) ->
        return category?.length > 3
    validateZipcode     = (zipcode) ->
        zipcodePattern  = /^\d{5}$|^\d{5}-\d{4}$/
        return zipcodePattern.test(zipcode)
    isNumber = (value) ->
        if undefined is value || null is value
            return false
        if typeof value is "number"
            return true
        return !isNaN(value - 0)
    parseCityAndState   = (cityAndState) ->
        @stack = cityAndState.split(",")
        return @stack

    jQuery(window).load(() ->
        $documentBody       = jQuery(document.body)
        $signinForm         = jQuery("signin")
        $alert              = jQuery("div#alert")
        $notice             = jQuery("div#notice")         
        $container          = jQuery("div#container")
        rowHeight           = $container.height()
        ##
        # GLOBAL CONSTANTS DECLARATION.
        ##
        NUMBER_OF_ITEMS     = 12;               TIME_INTERVAL   = 8000; ENTER_KEY   = 13;
        SHOW_EMAIL_TAB      = "SHOW_EMAIL_TAB"; SHOW_POSTITEM_DETAIL_TAB            = "SHOW_POSTITEM_DETAIL_TAB";
        SHOW_VIDEO_TAB      = "SHOW_VIDEO_TAB"; SHOW_PHOTOS_TAB                     = "SHOW_PHOTOS_TAB";
        SHOW_VOICE_TAB      = "SHOW_VOICE_TAB"; SHOW_COMMENTS_TAB                   = "SHOW_COMMENTS_TAB"
        ################################################################################################
        #  We setup the socket io client.  By assumption, we setup the channel to be city.state.country
        #  Therefore, we have to make sure we disconnect and reconnect to the new location.
        #  Once we receive the new items coming in, we have to add them to the isotope display.
        ################################################################################################
        setUpSocketIOClient = (city, state, country, isotope) ->
            channel         = city.replace(" ", ".").toLowerCase() + "." + state.replace(" ", ".").toLowerCase() + "." + country.replace(" ", ".").toLowerCase()
            socket          = io.connect("http://localhost:8080/" + channel, {"force new connection":true})
            socket.on("connect", () ->
                socket.on("postitem", (postitem) -> 
                  $newItem = transformToJQueryElement(postitem)
                  isotope.addNewItem($newItem) if isotope         
                )
            )
    
        # Display IsotopeDisplay object reference and the grid for table list.
        isotope             = null
        grid                = null
        ##
        # Setup isotope watcher to call setup SocketIOClient when the value is set.
        # This is a little tricky since isotope is being set within the closure
        # of the rpc response from the server.
        ##
        isotopeObject                       = {value: null}
        isotopeWatcher                      = createWatcher(isotopeObject)
        isotopeWatcher.watch("value", (property, oldValue, newValue) ->
            if newValue
                setUpSocketIOClient(city, state, country, newValue)
            return newValue
        )
        ################################################################################
        # Check if browser supports cookies.  If not, notify the user.
        ################################################################################
        if !jQuery.cookies.test()
            message         = """<p>The browser does not allow the application to save cookies.
                                    Please enable cookies in your browser to use full functinality of the site.
                                </p>"""
            $alert.html(message).fadeIn(1500).delay(4500).fadeOut(1500)
        ################################################################################
        # Check login session for the user.
        # The location info from IPDBInfo
        #    "location": {
        #        "statusCode": "OK",
        #        "statusMessage": "",
        #        "ipAddress": "64.134.66.156",
        #        "countryCode": "US",
        #        "countryName": "UNITED STATES",
        #        "regionName": "TEXAS",
        #        "cityName": "AUSTIN",
        #        "zipCode": "78744",
        #        "latitude": "30.3811",
        #        "longitude": "-97.7581",
        #        "timeZone": "-06:00",
        #        "source": "ipinfodb"
        #      }
        # The location from google
        #   "location": {
        #    "latitude": 35.046,
        #    "longitude": -85.31,
        #    "address": {
        #      "city": "Chattanooga",
        #      "region": "TN",
        #      "country": "USA",
        #      "country_code": "US"
        #    }
        ################################################################################
        updateLoggedInNav = (loggedin) ->
            if loggedin ##token? and token? != "" and typeof token != undefined
                jQuery("div#loggedin-account-nav").show()
                jQuery("div#non-loggedin-account-nav").hide()
                jQuery("#username").text(username)
            else
                jQuery("div#loggedin-account-nav").hide()
                jQuery("div#non-loggedin-account-nav").show()
            $signinForm.hide()

        loggedin                = jQuery("input#loggedin").val() is "true"
        string                  = jQuery("input#token").val()
        categories              = jQuery("input#categories").val()
        categories              = categories.split(",")
        console.log categories + " categories"
        token                   = JSON.parse(string) if string isnt "" and string isnt null and string isnt undefined
        if loggedin and !token
            cookie              = jQuery.cookies.get("logintoken")
            token               = JSON.parse(cookie) if cookie
        username                = token?.username
        location                = window?.session?.location
        address                 = token?.address or location?.address or []
        longitude               = token?.location?["0"] or location?.longitude
        latitude                = token?.location?["1"] or location?.latitude
        #Set the current location city, state and country for search.
        #Also set up the watch object for changes of the currentLocation.
        city                    = address["city"]?.toString() or location?.cityName or ""
        state                   = address["state"]?.toString() or location?.regionName or address["region"]?.toString()
        state                   = abbreviatedStateName[state?.toLowerCase()] or state or ""
        country                 = address["country"]?.toString() or location?.countryCode or address["country_code"]?.toString() or ""
        neighborhood            = address["neighborhood"]?.toString() or ""
        city                    = city.trim()
        state                   = state.trim()
        country                 = country.trim()
        neighborhood            = neighborhood.trim()
        $cityDisplay            = jQuery("li#mylocation-city-state")
        $countryDisplay         = jQuery("li#mylocation-country")
        $locationIndicatorCity  = jQuery("li#location-indicator-city")
        $locationIndicatorState = jQuery("li#location-indicator-state-or-country")
        #Check to make sure that the city, state and country values are filled.  Else set default.
        if city is "" or state is "" or country is ""
            city                = "New York"
            state               = "Ny"
            country             = "Us"
            latitude            = 40.75
            longitude           = -73.997
        currentLocation         = {"city": city, "state": state, "country": country, "neighborhood": neighborhood}
        locationWatcher         = createWatcher(currentLocation)
        #For autocomplete search.
        ISO2                    = country
        locationWatcher.watch("country", (property, oldValue, newValue) ->
            tmpCountry                          = newValue
            locationWatcher.watch("city", (property, oldValue, newValue) ->
                stack                           = parseCityAndState(newValue)
                currentLocation.city            = stack[0]
                currentLocation.state           = stack[1] if stack[1]
                currentLocation.country         = tmpCountry
                console.log "currentLocation.country tmpCountry " + currentLocation.country
                console.log "tmpCountry " + tmpCountry
                console.log "current state " + currentLocation.state
                console.log "current city " + currentLocation.city
                console.log currentLocation.city == currentLocation.state
                ISO2                            = tmpCountry
                currentLocation.neighborhood    = ""
                #Check if the current country is us.
                if not _.include(["us", "usa", "united states", "united states of america"], currentLocation.country.toLowerCase())
                    $cityDisplay.text(currentLocation.city)
                    $locationIndicatorCity.text(currentLocation.city)
                    $locationIndicatorState.text(currentLocation.country)
                else
                    $cityDisplay.text(currentLocation.city + ", " + currentLocation.state)
                    $locationIndicatorCity.text(currentLocation.city)
                    $locationIndicatorState.text(currentLocation.state)
                $countryDisplay.text(currentLocation.country)
                ##
                # We resetup the socket.io client when the location change.
                ##
                city                            = currentLocation.city
                state                           = currentLocation.state
                country                         = currentLocation.country
                setUpSocketIOClient(city, state, country, isotopeWatcher.value)
                return newValue
            )
            return newValue
        )
        locationWatcher.country         = country
        locationWatcher.state           = state
        locationWatcher.city            = city
        locationWatcher.neighborhood    = neighborhood
        rememberMe                      = token?.rememberme is "true"
        console.log " setup currentLocation.country " + currentLocation.country

        #if remember me is true then we save the cookie over a period of time else just save cookie for this session only.
        if token and rememberMe
            jQuery.cookies.set("username", username, { expires: new Date(Date.now() + 2 * 604800000), path: "/" })
            jQuery.cookies.set("logintoken", JSON.stringify(token), { expires: new Date(Date.now() + 2 * 604800000), path: "/" })
        else if token and !rememberMe
            jQuery.cookies.set("username", username)
            jQuery.cookies.set("logintoken", JSON.stringify(token))
        updateLoggedInNav(loggedin)
        ################################################################################
        # Setup Location indicator.
        ################################################################################
        $locationIndicatorCity.text(city)
        $locationIndicatorState.text(state)
        $documentBody.off("click", "li#location-indicator-change-location a").on("click", "li#location-indicator-change-location a", (event)  ->
            console.log "location change clicked"
            jQuery("a#location-filter").click()
        )

        ################################################################################
        # Setup Search input.
        # 
        # We query the db and populate the display with the result.
        # 
        # 2 scenarios:
        # 
        # 1. Display: either isotope display or table list display.
        # 2. Either there is data found or there is no data found.
        ################################################################################
        # clean up the textbox when load.
        # TODO setup the search functionality.
        $searchInput                    = jQuery("input[type='text']#search")
        $searchInput.val("")
        $documentBody.off("focus", "input[type='text']#search").on("focus", "input[type='text']#search", (event)  ->
            console.log "input search focus"
            $searchInput.val("")
            event.preventDefault()
        )
        $documentBody.off("keypress", "input[type='text']#search").on("keypress", "input[type='text']#search", (event)  ->
            console.log "input search is in keypress"
            if event.keyCode is ENTER_KEY
                console.log "enter is pressed"
            event.preventDefault()
        )
        ################################################################################
        # Prevent the enter key from submission of form.
        ################################################################################
        jQuery(window).keydown((event) ->
            if event.keyCode is ENTER_KEY
                event.preventDefault()
                return false
        )
        ################################################################################
        # Setup the main display, isotope and kendo ui grid.
        ################################################################################
        postitemMap                         = {} # hashmap that keeps track of all the postitems passed from the server.
        hasIsotopeBeenInitialized           = false
        $mediaListingContainer              = jQuery("div#media-listing-container")
        $textListingContainer               = jQuery("div#text-listing-container")
        $documentBody.off("click", "a#media-listing-selector").on("click", "a#media-listing-selector", (event)  ->
            console.log "media listing"
            jQuery.colorbox.close()
            if jQuery.isEmptyObject(postitemMap)
                await jQuery.getJSON "/api/postitems/{0}/{1}/{2}/".format(city, state, country), defer result
                # TODO take care of the error
                if result.response is "success"
                    postitemMap             = result.context
                else
                    console.log "error ------------------------- " + result.response
                    return
            postitemArray                   = _.values(postitemMap)
            jQElementArray                  = []
            for i in [1..20]
                array                       = _.map(postitemArray, transformToJQueryElement)
                jQElementArray              = jQElementArray.concat(array) 
            if not hasIsotopeBeenInitialized and not jQuery.isEmptyObject(postitemMap)
                setUpIsotope($container, jQElementArray)
                isotope.play()  
                hasIsotopeBeenInitialized   = true
                # TODO bind to item added to postitemMap event.
            else if hasIsotopeBeenInitialized and not jQuery.isEmptyObject(postitemMap)
                isotope.reset()
                isotope.addNewItems(jQElementArray)
                isotope.play()

            $mediaListingContainer.show()
            $textListingContainer.hide()
            event.preventDefault()
        )
        setUpIsotope = ($container, @jQElementArray) ->
            #################################################################################
            # Setup the items in the main display for images.  In this case we use Isotope.
            #################################################################################
            # We configure Isotope to display images 
            $container.imagesLoaded(() ->
                $container.isotope({
                    resizable: true,
                    animationEngine: "best-available",
                    sortBy : "random",
                    animationOptions: {
                     duration: 800,
                     easing: 'linear',
                     queue: true
                    },
                    masonryHorizontal: {
                        rowHeight: rowHeight
                    }
                })
            )
            isotope                 = new IsotopeDisplay($container, @jQElementArray)
            # We set the value of the isotope for the watcher so it is visible in the global scope.
            isotopeWatcher.value    = isotope
            # Set up the event handlers for all isotope interactions here.
            #The playback interaction for Isotope display.
            $documentBody.off("click", "li#play, li#pause").on("click", "li#play, li#pause", (event) ->
                $playButton.toggle()
                $pauseButton.toggle()
                if $playButton.is(":visible")
                    isotope.stop()
                    console.log "isotope stops"
                else
                    isotope.play()
                    console.log "isotope plays"
                event.preventDefault()
            )
            $documentBody.off("click", "li#rewind").on("click", "li#rewind", (event) ->
                console.log "rewind clicked"
                $element = jQuery(this)
                $element.find("span a").addClass("active")
                setTimeout (()->
                    $element.find("span a").removeClass("active")
                ), 36
                isInitiallyPlaying = isotope.isPlaying()
                isotope.stop() if isInitiallyPlaying
                isotope.rewind()
                isotope.play() if isInitiallyPlaying
                event.preventDefault()
            )
            $documentBody.off("click", "li#forward").on("click", "li#forward", (event) ->
                console.log "forward clicked"
                $element = jQuery(this)
                $element.find("span a").addClass("active")
                setTimeout (()->
                    $element.find("span a").removeClass("active")
                ), 36
                isInitiallyPlaying = isotope.isPlaying()
                isotope.stop() if isInitiallyPlaying
                isotope.forward()
                isotope.play() if isInitiallyPlaying
                event.preventDefault()
            )
            #Show the post item detail.
            alreadyclicked = false
            $documentBody.off("click", ".image").on("click", ".image", (event) ->
                console.log "click .image"
                $self                               = jQuery(this)
                # double click
                if alreadyclicked
                    alreadyclicked                  = false # reset
                    clearTimeout(@alreadyclickedTimer) if @alreadyclickedTimer
                    postitemID                      = $self.parents("item").attr("id")
                    try
                        showPostItemDetailIsotopePage(isotope, postitemMap[postitemID])
                    catch error
                        # TODO take care of the error
                        console.log error
                else
                    #single click
                    alreadyclicked                  = true
                    @alreadyclickedTimer            = setTimeout(() =>
                        alreadyclicked              = false
                        postitemID                  = $self.attr("id")
                        console.log("postitemID " + postitemID)
                        image                       = $self.find(".image").first()
                        console.log "image length " + image.length
                        swapFirstLast($self)
                    , 250)
                event.preventDefault()
            )
            #these are the hover effects on the left and right and the images
            $documentBody.off("hover", "div#scrolling-hotspot-left").on("hover", "div#scrolling-hotspot-left", (event) ->
                console.log "hover left"
                if event.type is "mouseenter"
                    jQuery(this).css("background-color", "#CCCCCC")
                    isotope.rewind()
                    @timer = setInterval(isotope.rewind, (TIME_INTERVAL / 5))
                else
                    clearInterval(@timer) if @timer
                    jQuery(this).css("background-color", "transparent")
                event.preventDefault()
            )
            $documentBody.off("hover", "div#scrolling-hotspot-right").on("hover", "div#scrolling-hotspot-right", (event) ->
                if event.type is "mouseenter"
                    jQuery(this).css("background-color", "#CCCCCC")
                    isotope.forward()
                    @timer = setInterval(isotope.forward, (TIME_INTERVAL / 5))
                else
                    clearInterval(@timer) if @timer
                    jQuery(this).css("background-color", "transparent")
                isotope.forward(4)
                event.preventDefault()
            )
            ##
            # Stop the player when hover over the item.
            ##
            $documentBody.off("hover", "item").on("hover", "item", (event) ->
                if event.type is "mouseenter"
                    @hoverIntent = setTimeout(() -> 
                        isotope.stop()
                    , 5000)
                else
                    try
                        console.log("clear hover")
                        clearTimeout(@hoverIntent) if @hoverIntent
                        #isotope.play()
                    catch error
                        console.log(error)
                event.preventDefault()
            )
        ################################################################################
        # Setup the utility functions for media isotope display.
        ################################################################################
        ###
        # The Isotope display is set to auto play by default.
        #
        # Steps:
        # 1. We first query the server for all the items in the specified city and state.
        # 2. Then we put them in the display buffer array.
        # 3. We take (n) items to display.
        #    3.1 We check first if new item buffer is not empty
        #    3.2 If it is not, we take those items and append to the display buffer and
        #        put them into the display.
        #    3.3 If the new item buffer is empty, we just take the first (n) elements
        #        from the display buffer and insert them into Isotope for display.
        #    3.4 Once we have taken the (n) items for display, we remove them from the front
        #        of the display buffer and append them to the buffer.
        # 4. We hook up the new item buffer to the socket.io for live update from the
        #    server and we filter in only those that are for the city and state specified.
        # 5. The forward and backward button would step through the steps going back and 
        #    forth on the display buffer and the new item buffer.
        ###
        ##
        # We expect result's context as a hash of postitem - {id: postitem}.
        # Note: the filters string is a global variable found in the category filter section.!!!!!!!
        ##
        $playButton                                 = jQuery("li#play")
        $pauseButton                                = jQuery("li#pause")
        #We encapsulate the Isotope display in a class below.
        class IsotopeDisplay
            timeInterval                    = TIME_INTERVAL
            numberOfItems                   = NUMBER_OF_ITEMS    # the number of items to fetch each time
            playing                         = false              # is the display in play loop.  
            ##
            # @container        - the Isotope container.
            # @newItemBuffer    - the array of jQuery dom elements that we use to temporary 
            #                     store newly added items.
            # @filters          - the filter strings that we pass on to Isotope.
            ##
            constructor: ($container, @newItemBuffer) ->
                @displayBuffer              = []
                setTimeout(() => 
                    @_setUpFirstBatch()
                    @play()
                , 1200)

                # We process the stack images once the images are in place.
                processStackImages()

                # We setup touchswipe action.  This uses the code found in jquery.elasticslide.js.
                # Which points to http://www.netcu.de/jquery-touchwipe-iphone-ipad-library.
                $container.touchwipe({
                     wipeLeft: () -> 
                        @forward()
                     wipeRight: () -> 
                        @rewind()
                     min_move_x: 20
                     min_move_y: 20
                     preventDefaultEvents: true
                })

                $documentBody.off("mousewheel", $container).on('mousewheel', $container, (event,delta) =>
                 if delta > 0
                   @forward() 
                 else 
                   @rewind()
                )

                              
            ##
            # Scenarios:
            # 1 there are new items in newItemsBuffer
            #   1.1 there are more than (numberOfItems) in the newItemBuffer
            #   1.2 there are fewer than (numberOfItmes) in the newItemBuffer
            # 2. there is no new item
            # 3. there are items in displayBuffer
            #   3.1 there are new items in newItemBuffer
            #       3.1.1 case 1.1
            #       3.1.2 case 1.2
            #   3.2 there are no items in newItemBuffer
            # 4. there is no item in displayBuffer
            ##
            _setUpFirstBatch: () =>
                @firstBatch                 = @newItemBuffer.splice(0, numberOfItems)
                @displayBuffer              = @displayBuffer.concat(@firstBatch)
                $container.isotope('insert', item).isotope({filter : filters}) for item in @firstBatch   
            _fetchAndInsertNewItems: () =>
                @newItems                   = @newItemBuffer.splice(0, numberOfItems)
                length                      = @newItems.length
                if length <= 0
                    @newItems               = @displayBuffer.splice(0, numberOfItems)
                else if length > 0 and length < numberOfItems
                    extra                   = @displayBuffer.splice(0, numberOfItems - length)
                    @newItems.concat(extra)
                if @newItems
                    @_rotateItems(@newItems)
                    @clear() 
                    @_insertItems(@newItems)
            _fetchAndRevertOldItems: () =>
                @_retrievePriorItems()
                @clear() 
                @_insertItems(@newItems)
            _retrievePriorItems: () =>
                length                      = @displayBuffer.length
                @newItems                   = @displayBuffer.splice(length - numberOfItems, numberOfItems)
            _rotateItems: (newItems) =>
                @displayBuffer              = @displayBuffer.concat(@newItems)
            _insertItems: (newItems) =>
                for item in newItems    
                    @displayBuffer.unshift(item)    
                    $container.isotope('insert', item).isotope({filter : filters})
                processStackImages()
            _setupPlayer: () =>
                clearInterval(@timer) if @timer
                @timer                      = setInterval(@_fetchAndInsertNewItems, timeInterval)
                playing                     = true
                if $playButton.is(":visible")
                    $playButton.toggle()
                    $pauseButton.toggle()
            play: () =>
                if @hasBeenReset
                    # We have to delay for the container to show correctly first before applying isotope.
                    setTimeout(() => 
                        @_setUpFirstBatch()
                        @_setupPlayer()
                    , 1200)
                    @hasBeenReset           = false
                else 
                    length                  = @displayBuffer.length
                    if length < numberOfItems
                        return
                    else
                        @_setupPlayer() 
                return @
            forward: () =>
                length                      = @displayBuffer.length
                if length < numberOfItems
                    return 
                @_fetchAndInsertNewItems()
                return @
            rewind: () =>
                length                      = @displayBuffer.length
                if length < numberOfItems
                    return
                @_fetchAndRevertOldItems()
                return @
            stop: () =>
                clearInterval(@timer) if @timer
                playing                     = false
                if $pauseButton.is(":visible")
                    $playButton.toggle()
                    $pauseButton.toggle()
                return @
            ##
            # @params $item                 - jQuery dom element
            ##
            addNewItem: ($item) =>
                @newItemBuffer.push($item) if $item
                return @
            ##
            # @params $items                - array of jQuery dom elements
            ##
            addNewItems: ($items) =>
                @newItemBuffer              = @newItemBuffer.concat($items) if $items
                return @
            ##
            # @params filter                - filter string for used with Isotope container.
            ##
            addFilter: (filter) =>
                array                       = filters.split(",")
                array.push(filter)
                filters                     = array.join(",")
                return @
            removeFilter: (filter) =>
                array                       = fitlers.split(",")
                array                       = _.without(array, filter)
                filters                     = array.join(",")
                return @
            clear: () ->
                $removable                  = $container.children();
                $removable.detach()
                #$container.isotope('remove', $removable);
                $container.isotope("remove", $container.data('isotope').$allAtoms)
                return @
            reset: () =>
                @clear()
                @displayBuffer              = []
                @newItemBuffer              = []
                @hasBeenReset               = true
                return @
            refresh: () =>
                $container.isotope("reloadItems", @newItems).isotope({filter : filters})
                return @
            isPlaying: () ->
                return playing

        ##
        # Swap function for the image items in the main display.
        ##
        swapFirstLast           = ($element) ->
            $elements            = $element.siblings()
            if $elements.length is 1 then return
            console.log "swapFirstLast " + $elements.siblings().length + " " + $elements.css('z-index') 
            processZindex       = $elements.siblings().length
            $element.animate({ 'top' : "-" + $element.height() + 'px' }, 'slow', () -> #animate the img above/under the gallery (assuming all pictures are equal height)
              jQuery(this).css('z-index', 1) #set new z-index
                .animate({ 'top' : '0' }, 'slow', () -> {})#animate the image back to its original position
            )
            $elements.each(() ->
                $element         = jQuery(this)
                $element.animate({ 'top' : '0' }, 'slow', () -> #make sure to wait swapping the z-index when image is above/under the gallery
                  console.log "increase zindex" + parseInt(jQuery(this).css('z-index')) + 1
                  jQuery(this).css('z-index', parseInt(jQuery(this).css('z-index')) + 1) #in/de-crease the z-index by one
                )
            )
            return false #don"t follow the clicked link
        ##
        # Seperate the click from dblclick event.
        ##
        singleDoubleClick = (click, dblClick) ->
            return (() -> 
                @alreadyclicked                 = false;
                @alreadyclickedTimeout;

                return (event) ->
                    #dblClick
                    if @alreadyclicked
                        @alreadyclicked         = false
                        @alreadyclickedTimeout and clearTimeout(@alreadyclickedTimeout)
                        dblClick and dblClick(event)
                    else
                        #click
                        @alreadyclicked         = true;
                        @alreadyclickedTimeout  = setTimeout(() ->
                            @alreadyclicked     = false
                            click and click(event)
                        , 300)
            )()
        ##
        # This is a transform function turning a postitem json into an appropriate html fragment for
        # Isotope display.
        #
        # We put all the logic of creating item fragment in this function.
        #
        # json                  - the json string of postitem to be transformed into jQuery element
        #                         of the appropriate html fragment.  
        ##
        transformToJQueryElement    = (json) ->
            console.log "transformToJQueryElment " + json
            result = '''
                    <item id="4f637a520a9046122a000006" class="item fourxfive Appliances" style="border:1px solid red;"> 
                        <p>
                            <img src="listing-images/sampleImage_001_400x300.jpg" alt="{0}" />
                            <img src="listing-images/picture2.png" alt="{1}" />
                            <img src="listing-images/picture3.png" alt="{2}" />
                            <img src="listing-images/picture4.png" alt="{3}" />
                            <img src="listing-images/picture5.png" alt="{4}" />
                            <img src="listing-images/picture5.png" alt="{5}" />
                        </p>
                        <p class="desc">Kurt 1</p>
                    </item>
                    '''.format(1,2,3,4,5,6)
            return jQuery(result)

        processStackImages      = () ->
            jQuery("item p").each((index, value) ->  #set the initial z-index"sjQuery
              $self             = jQuery(this)
              return if $self.hasClass("processed")
              $self.addClass("processed")
              z                 = 0 #for setting the initial z-index"s
              imageLoaded       = 0 #for checking if all images are loaded
              $self.children().each((index, value) ->
                  z++ #at the end we have the highest z-index value stored in the z variablejQuery
                  jQuery(this).css("z-index", z) #/apply increased z-index to <img>jQueryi
                  jQuery(this).addClass("image")
                  image         = new Image()
                  src           = jQuery(this).attr("src")
                  image.src     = src if src
                  jQuery(image).load(() ->  #create new image object and have a callback when it"s loaded
                      imageLoaded++ #one more image is loaded
                      if imageLoaded is z #do we have all pictures loaded?
                          jQuery(".loader-" + index).fadeOut("slow") #if so fade out the loader div

                  )
              )
              $self.append("<div class=loader-" + index + "></div>") #append the loader div, it overlaps all picturesjQuery jQuery
            )

        #################################################################################
        # Setup show postitem detail popup page.
        #################################################################################
        hasListingTableBeenIntialized   = false
        $documentBody.off("click", "a#text-listing-selector").on("click", "a#text-listing-selector", (event)  ->
            $mediaListingContainer.hide()
            $textListingContainer.show()
            jQuery.colorbox.close()
            isotope.stop() if isotope
            #################################################################################
            # Setup the items in table list display.  We use KendoUI grid for display.
            #################################################################################
            # We configure KendoUI grid to display table list.
            if jQuery.isEmptyObject(postitemMap)
                await jQuery.getJSON "/api/postitems/{0}/{1}/{2}/".format(city, state, country), defer result
                # TODO take care of the error
                if result.response isnt "success"
                    console.log "error ------------------------- " + result.response
                    return
                else
                    postitemMap                 = result.context
            if not hasListingTableBeenIntialized and not jQuery.isEmptyObject(postitemMap)
                postitemArray                   = _.values(postitemMap)
                jQElementArray                  = []
                for i in [1..20]
                    array                       = _.map(postitemArray, transformToJQueryElement)
                    jQElementArray              = jQElementArray.concat(array)
                hasListingTableBeenIntialized   = true
                grid                            = jQuery("div#grid").kendoGrid({
                                                        dataSource: {
                                                            data: postitemArray,
                                                            pageSize: 8,
                                                            schema: {
                                                                model: {
                                                                    fields: {
                                                                        title: { type: "string" },
                                                                        itemDescription: { type: "string" },
                                                                        price: { type: "number" },
                                                                        category: { type: "string" },
                                                                        username: { type: "string" },
                                                                        userRating: { type: "number" },
                                                                        createdDate: { type: "date" },
                                                                        neighborhood: { type: "string" }
                                                                    }
                                                                }
                                                            }
                                                        },
                                                        height: "100%",
                                                        sortable: true,
                                                        reorderable: true,
                                                        resizable: true,
                                                        pageable: true,
                                                        scrollable: true,
                                                        detailTemplate: kendo.template(jQuery("#grid-detail-template").html()),
                                                        detailInit: (event) ->
                                                            detailRow                   = event.detailRow
                                                            postitem                    = event.data

                                                            detailRow.find(".tabstrip").kendoTabStrip({
                                                                animation: {
                                                                    open: { effects: "fadeIn" }
                                                                }
                                                            })
                                                            setUpGridDetailMedia(postitem)
                                                            event.preventDefault()
                                                        ,
                                                        dataBound: () ->
                                                            #this.expandRow(this.tbody.find("tr.k-master-row").first());
                                                            console.log "databound"
                                                        ,
                                                        columns: [
                                                            {
                                                                field: "title",
                                                                title: "Title"
                                                            },
                                                            {
                                                                field: "itemDescription",
                                                                title: "Description",
                                                                width: "38%"
                                                            },
                                                            {
                                                                field: "category",
                                                                title: "Category"
                                                            },
                                                            {
                                                                field: "price",
                                                                title: "Price"
                                                            },
                                                            {
                                                                field: "username",
                                                                title: "Lister",
                                                                width: "10%"
                                                            },
                                                            {
                                                                field: "userRating",
                                                                title: "Lister Rating",
                                                                width: 126
                                                            },
                                                            {
                                                                command: {  
                                                                    text: "Email" 
                                                                    , click: (event) ->
                                                                            postitem = @dataItem(jQuery(event.currentTarget).closest("tr"))
                                                                            setUpGridDetailEmail(postitem)
                                                                            event.preventDefault() 
                                                                }
                                                                , title: "Contact"
                                                                , width: "110px"
                                                            },
                                                            {
                                                                field: "createdDate",
                                                                title: "Date",
                                                                template: '#= kendo.toString(createdDate,"MM/dd/yyyy") #'
                                                            },
                                                            {
                                                                field: "address.neighborhood",
                                                                title: "Neighborhood"
                                                            },
                                                        ]
                                                    })
                ##
                # TODO hide the section if it is not available, i.e. videos, photos, voice.
                # show message alert if it is not available.  show the message when clicked.
                ##
                setUpGridDetailMedia = (postitem) ->
                    console.log "setupGridDetailMedia " + postitem._id
                    $documentBody.off("click", ".grid-detail-media-photos").on("click", ".grid-detail-media-photos", (event) ->
                        showPostItemDetailTableListPage({activeTab: SHOW_PHOTOS_TAB}, postitem)
                    )
                    $documentBody.off("click", ".grid-detail-media-video").on("click", ".grid-detail-media-video", (event) ->
                        showPostItemDetailTableListPage({activeTab: SHOW_VIDEO_TAB}, postitem)
                    )
                    $documentBody.off("click", ".grid-detail-media-voice").on("click", ".grid-detail-media-voice", (event) ->
                        showPostItemDetailTableListPage({activeTab: SHOW_VOICE_TAB}, postitem)
                    )
                    $documentBody.off("click", ".grid-detail-media-comments").on("click", ".grid-detail-media-comments", (event) ->
                        showPostItemDetailTableListPage({activeTab: SHOW_COMMENTS_TAB}, postitem)
                    )
                setUpGridDetailEmail = (postitem) ->
                    showPostItemDetailTableListPage({activeTab: SHOW_EMAIL_TAB}, postitem)
                # TODO bind action to the add item to postitemMap event
            event.preventDefault()
        )
        jQuery("a#media-listing-selector").click() # default set isotope display.
        ################################################################################
        # Setup the utility functions for postitem detail popup page.
        ################################################################################
        $detailTitle = $detailPrice = $detailLocation = $detailUserRating = $detailCategory     = null
        $detailExchangeOptions      = $detailEmail    = $detailEmailLink  = $detailUsernameLink = null
        $detailUsername             = $itemDetail     = $rivets         = null
        VIDEO_VOICE_INDEX               = 1
        COMMENT_INDEX                   = 2
        EMAIL_LIST_INDEX                = 3
        setUpDetailPageTabs             = (postitem) ->
            postitemID                  = postitem._id
            $tabs                       = jQuery("div#tabs").tabs({
                load: (event, ui) ->
                    event.preventDefault()
                cache: true,
                collapsible: false,
                select: (event, ui) ->
                    index       = ui.index
                    jQuery("script#disqus-script").remove()
                    console.log "COMEMENT_INDEX"
                    if index is VIDEO_VOICE_INDEX
                        console.log "video tab is clicked"
                    else if index is COMMENT_INDEX
                        disqus = """
                            <script id="disqus-script" type="text/javascript">
                                var disqus_shortname    = "listsil"; // required: replace example with your forum shortname
                                var disqus_identifier   = disqus_shortname + "-" + "{0}";
                                var disqus_title        = disqus_identifier
                                //site name
                                disqus_url = document.location.href;

                                if (typeof(DISQUS) == "undefined")
                                    jQuery.getScript("http://" + disqus_shortname + ".disqus.com/embed.js");

                                if (jQuery("#disqus_thread").length == 2)
                                    jQuery(".disqus-ajax:has(a)").removeAttr("id").empty();

                                if (typeof(DISQUS) !== "undefined") {
                                    DISQUS.reset({
                                        reload: true,
                                        config: function () {
                                            this.page.url = disqus_url;
                                            this.page.title = disqus_title;
                                            this.page.identifier = disqus_identifier;
                                        }
                                    });
                                }
                            </script>
                            """.format((postitemID).toString()) 
                        jQuery("div#comments").append(disqus)
                    else if index is EMAIL_LIST_INDEX
                        console.log "email lister"
            })
            ##
            # Bind to custom events for tabs.
            ##
            $documentBody.off(SHOW_POSTITEM_DETAIL_TAB).on(SHOW_POSTITEM_DETAIL_TAB, (event,data) ->
                $tabs.tabs('select', 0)
            )
            $documentBody.off(SHOW_EMAIL_TAB).on(SHOW_EMAIL_TAB, (event,data) ->
                $tabs.tabs('select', 3)
            )
            $documentBody.off(SHOW_PHOTOS_TAB).on(SHOW_PHOTOS_TAB, (event,data) ->
                $tabs.tabs('select', 0)
            )
            $documentBody.off(SHOW_VIDEO_TAB).on(SHOW_VIDEO_TAB, (event,data) ->
                $tabs.tabs('select', 1)
            )
            $documentBody.off(SHOW_VOICE_TAB).on(SHOW_VOICE_TAB, (event,data) ->
                $tabs.tabs('select', 1)
            )
            $documentBody.off(SHOW_COMMENTS_TAB).on(SHOW_COMMENTS_TAB, (event,data) ->
               $tabs.tabs('select', 2)
            )
            return $tabs

        setUpDetailPageElements         = (postitem) ->
            postitemID                  = postitem._id
            $itemDetail                 = jQuery("div#listing")
            $detailTitle                = jQuery(".listing-detail-title")
            $detailPrice                = jQuery(".listing-detail-price")
            $detailLocation             = jQuery(".listing-detail-location")
            $detailUsernameLink         = jQuery(".listing-detail-username-link")
            $detailUsername             = jQuery(".listing-detail-username")
            $detailUserRating           = jQuery(".listing-detail-user-rating")
            $detailCategory             = jQuery(".listing-detail-category")
            $detailExchangeOptions      = jQuery(".listing-detail-exchange-options")
            $detailEmailLink            = jQuery(".listing-detail-email-link")
            $detailEmail                = jQuery(".listing-detail-email")
            
            # We extend the ko model with computed values for use.
            model                       = ko.mapping.fromJS(postitem)
            # TODO find out why it is different from that in listing-edit
            # model.numberOfPhotos        = ko.observable(model.photos.length())
            console.log "model.photos[0]() " + model.photos[0].image()
            model.exchangeOptionsString = ko.computed(() ->
                len = this.exchangeOptions.length() - 1
                result = []
                if len
                    result.push(this.exchangeOptions[i]()) for i in [0..len]
                result = result.join(", ") or "n/a"
                return result                                 
            , model)
            model.mainImageDisplay = ko.computed(() ->
                len = this.photos.length()
                if len > 0
                    return "images/sampleImage_001_120x90.jpg" # this.photos[0].imgage()
                else
                    #TODO define default image for display when none is uploaded.
                    return "images/sampleImage_001_120x90.jpg"                               
            , model)
            ko.applyBindings(model)

        showPostItemDetailIsotopePage   = (isotope, postitem) ->
            postitemID                  = postitem._id
            isInitiallyPlaying          = false
            jQuery.colorbox({href:"/pages/listing/", width: "100%", height: "100%", close:""
            , onComplete: () ->
                setUpDetailPageElements(postitem)
                console.log "showPostItemDetailIsotopePage is called"
                isInitiallyPlaying      = isotope.isPlaying()
                isotope.stop()
                $tabs                   = setUpDetailPageTabs(postitem)
                # Setup close event.
                $documentBody.off("click", "#listing-detail-close").on("click", "#listing-detail-close", (event) ->
                    isotope.play() if isInitiallyPlaying
                    jQuery.colorbox.close()
                    ko.cleanNode($itemDetail[0]) if ko
                    event.preventDefault()
                )
                
                audio = audiojs.createAll()

                $tabs.tabs('select', 0)
            })

        showPostItemDetailTableListPage = (options, postitem) ->
            postitemID                  = postitem._id
            jQuery.colorbox({href:"/pages/listing/", width: "100%", height: "100%", close:""
            , onComplete: () ->
                setUpDetailPageElements(postitem)
                console.log "showPostItemDetailTableListPage is called"
                $tabs                   = setUpDetailPageTabs(postitem)
                # Setup close event.
                $documentBody.off("click", "#listing-detail-close").on("click", "#listing-detail-close", (event) ->
                    jQuery.colorbox.close()
                    ko.cleanNode($itemDetail[0]) if ko
                    event.preventDefault()
                )
                
                audio = audiojs.createAll()
                
                $tabs.tabs('select', 0)

                $documentBody.trigger(options.activeTab)
            })
        #################################################################################
        # Setup clear mark X in input boxes.
        #################################################################################
        $documentBody.off("keyup", "input.textInput").on("keyup", "input.textInput", (event)  ->
            if jQuery(this).val().length > 0
                jQuery(this).next("span.clear-mark").fadeIn(300)
            else
                jQuery(this).next("span.clear-mark").fadeOut(300)
            event.preventDefault()
        )
        $documentBody.off("span.clear-mark").on("click", "span.clear-mark", (event) ->
            jQuery(this).prev("input").val("")
            jQuery(this).delay(700).fadeOut(300)
            event.preventDefault()
        )

        #################################################################################
        # Setup days selector slider.  We also hook the change event into the stop
        # function here.
        #################################################################################
        jQuery("select#days").removeAttr("slide").selectToUISlider({
            sliderOptions:
                stop: (error, ui) ->
                    console.log jQuery("select#days").val()
                    ## This is a hack to hide the tooltip for the slider.
                    jQuery("a#handle_days").delay(350).queue(() ->
                        jQuery(this).blur().dequeue()
                    )
        })
        $documentBody.off("change", "select[name=days]").on("change", "select[name=days]", (event) ->
            console.log jQuery("select[name=days] option:selected").attr("name")
        )
        #################################################################################
        # The Sign up and sign in behavior
        #################################################################################
        $documentBody.off("click", "a#signout").on("click", "a#signout", (event) ->
            hideAllFiltersExcept("none")
            rpc.request({
                url: "../../../api/logout/",
                method: "POST",
                data: { "username": username }
            },(response) ->
                result = JSON.parse(response.data)
                if result?.response is "success"
                    loggedin    = false
                    updateLoggedInNav(loggedin)
                    jQuery.cookies.del("logintoken")
                    jQuery.cookies.del("username")
                    jQuery("input#loggedin").val("false")
                    jQuery("input#token").val("")
                else
                    loggedin    = false
                    updateLoggedInNav(loggedin)
                    $alert.html("<p>" + result.message + "</p>").fadeIn(1500).delay(3500).fadeOut(1500)
            , (error) ->
                message         = """<p>There is an error occurred while we try to logout of your account.
                                        Sorry for the inconvenience.  If the problem persists,
                                        please contact admin@melisting.com for further assistance.</p>"""
                $alert.html("<p>" + message + "</p>").fadeIn(1500).delay(3500).fadeOut(1500)
                loggedin    = false
                updateLoggedInNav(loggedin)
            )
            event.preventDefault()
        )
        signinFormHasBeenSetup  = false
        $documentBody.off("click", "a#signin-trigger").on("click", "a#signin-trigger", (event) ->
            console.log "signin-trigger clicked"
            self                = jQuery(this)
            if not self.next("signin").is(":visible")
                hideAllFiltersExcept("none")
            self.next("signin").slideToggle()
            self.toggleClass("active")
            $email              = $email or jQuery("input#signin-email")
            $email.focus()

            if !signinFormHasBeenSetup
                $password       = $password         or jQuery("input#signin-password")
                $rememberMe     = $rememberMe       or jQuery("input#remember-me")
                $emailError     = $emailError       or jQuery("div#signin-email-error")
                $passwordError  = $passwordError    or jQuery("div#signin-password-error")
                $formError      = $formError        or jQuery("div#signin-form-error")

                $documentBody.off("click", "a#close-signin-form").on("click", "a#close-signin-form", (event) ->
                    $email.val("")
                    $password.val("")
                    $rememberMe.removeAttr("checked")
                    $signinForm.hide()
                    event.preventDefault()
                )
                $documentBody.off("keyup", "input#signin-email").on("keyup", "input#signin-email", (event) ->
                    console.log "in email text box key press " + event.keyCode
                    keycode = event?.keyCode or event?.which
                    if keycode is ENTER_KEY and validateEmail(jQuery(this).val())
                        $password.focus()
                        $emailError.text("")
                        event.preventDefault()
                )
                $documentBody.off("keyup", "input#signin-password").on("keyup", "input#signin-password", (event) ->
                    keycode = event?.key or event?.which
                    if keycode is ENTER_KEY and validatePassword(jQuery(this).val())
                        $email.focus()
                        $passwordError.text("")
                        event.preventDefault()
                )
                $documentBody.off("submit", "form#signin-form").on("submit", "form#signin-form", (event) ->
                    if validateForm()
                        email       = $email.val()
                        rememberMe  = if $rememberMe.is(":checked") then true else false
                        rpc.request({
                            url: "../../../api/login/",
                            method: "POST",
                            data: { "email": email, "password": $password.val(), "remember_me": rememberMe }
                        },(response) ->
                            result = JSON.parse(response.data)
                            # 1. Change the singup singin section to logout and account settings.
                            # 2. Slowly fade the login box.
                            if result.response is "success"
                                session                         = result?.session
                                username                        = result?.context?.username
                                loggedin                        = true
                                updateLoggedInNav(loggedin)
                                $email.val("")
                                $password.val("")
                                $rememberMe.removeAttr("checked")
                                token                           = result?.context
                                #We set the current location here from the token gotten back.
                                locationWatcher.neighborhood    = token?.address?.neighborhood
                                locationWatcher.country         = token?.address?.country
                                locationWatcher.state           = token?.address?.state
                                locationWatcher.city            = token?.address?.city
                                latitude                        = token?.location?.latitude
                                longitude                       = token?.location?.longitude
                                if rememberMe
                                    jQuery.cookies.set("username", username, { expires: new Date(Date.now() + 2 * 604800000), path: "/" })
                                    jQuery.cookies.set("logintoken", token, { expires: new Date(Date.now() + 2 * 604800000), path: "/" })
                                else
                                    jQuery.cookies.set("username", username)
                                    jQuery.cookies.set("logintoken", token)
                                #we push the session and email into a cookies.
                                jQuery.cookies.set(key, email)
                                jQuery.cookies.set("session", session)
                            else
                                $formError.html("<p>" + result.message + "</p>").fadeIn(1500).delay(3500).fadeOut(1500)
                        , (error) ->
                            console.log "error"
                            console.log error
                            message         = """<p>An error occurred while we try to login to your account.
                                                    Sorry for the inconvenience.  If the problem persists,
                                                    please contact admin@melisting.com for further assistance.</p>"""
                            $formError.html(message).fadeIn(1500).delay(3500).fadeOut(1500)
                        )

                    event.preventDefault()
                )

                validateForm    = () ->
                    result      = true
                    if !validateEmail($email.val())
                        result  = false
                        $emailError.html("<p>Email has to be in the format: i.e. email@yourdomain.com.</p>")
                        $email.css("border", "3px solid #F00")
                    else
                        $emailError.text("")
                        $email.css("border", "3px solid #CCC")
                    if !validatePassword($password.val())
                        result  = false
                        $passwordError.html("<p>Password has to be at least of 6 characters.  Recommended to have combination of letters and numbers.</p>")
                        $password.css("border","3px solid #F00")
                    else
                        $passwordError.text("")
                        $password.css("border", "3px solid #CCC")

                $documentBody.off("click", "a#forgot-password").on("click", "a#forgot-password", (event) ->
                )

                $documentBody.off("click",  "a#register").on("click",  "a#register", (event) ->
                    $signinForm.hide()
                    jQuery("a#signup").click()
                )

                signupFormHasBeenSetup = true
        )

        #################################################################################
        # Set up the popup boxes for signup.
        #################################################################################
        isInitiallyPlaying      = false
        $documentBody.off("click", "a#signup").on("click", "a#signup", (event)->
            hideAllFiltersExcept("none")
            $signupForm = jQuery("form#signup-form")
            $email      = $username         = $password         = $terms        = null
            $country    = $city             = $neighborhood                     = null
            $emailError = $usernameError    = $passwordError    = $termsError   = null
            $countryError                   = $cityError        = $formError    = null
            jQuery.colorbox.remove()
            jQuery.colorbox({href:"pages/signup/", close:"", escKey: false
            , onComplete: () ->
                $email          = jQuery("input#signup-email")
                $username       = jQuery("input#signup-username")
                $password       = jQuery("input#signup-password")
                $terms          = jQuery("input#accept-terms-of-use")
                $country        = jQuery("input#signup-location-country")
                $city           = jQuery("input#signup-location-city-state")
                $neighborhood   = jQuery("input#signup-location-neighborhood")
                $emailError     = jQuery("div#signup-email-error")
                $usernameError  = jQuery("div#signup-username-error")
                $passwordError  = jQuery("div#signup-password-error")
                $termsError     = jQuery("div#terms-of-use-error")
                $countryError   = jQuery("div#signup-location-country-error")
                $cityError      = jQuery("div#signup-location-city-state-error")
                $formError      = jQuery("div#signup-form-error")
                $email.focus()
                if isotope
                    isInitiallyPlaying = isotope.isPlaying()
                    isotope.stop()
                console.log "currentLocation.country " + currentLocation.country
                #If state and city are the same we know that the country does not have states but only cities.
                if !currentLocation.state or currentLocation.city is currentLocation.state
                    $city.val(currentLocation.city)
                else
                    $city.val(currentLocation.city + ", " + currentLocation.state)
                $country.val(currentLocation.country)
            })
            $documentBody.off("focus", "input#signup-location-country").on("focus", "input#signup-location-country", (event) ->
                $country.val("")
                $city.val("")
                $city.attr("disabled", true)
                #TODO we need to set the current location info after change.
                $country.autocomplete({
                    source       : (request, response) ->
                        #Check it is it is illegal number - http://www.w3schools.com/jsref/jsref_isnan.asp.
                        if isNumber(request.term)
                            jQuery.getJSON "/api/getCitiesByZipcode/",{term:request.term,maxRows:12},response
                        else
                            jQuery.getJSON "/api/getCountries/",{term:request.term,maxRows:12},response
                    , minLength   :  1
                    , select      :  (event, ui) ->
                        if ui.item.ISO2
                            ISO2 = ui.item.ISO2
                        else
                            #TODO change the values in the input fields to appropriate ones.
                            longitude   = ui.item.longitude
                            latitude    = ui.item.latitude
                            $city.val(ui.item.address)
                        $city.removeAttr("disabled")
                    , autoFocus   : true
                    , autoSelect  : true

                })
                $documentBody.off("blur", "input#signup-location-country").on("blur", "input#signup-location-country", (event) ->
                    console.log "on blur country autocomplete"
                    autocomplete    = jQuery(this).data("autocomplete");
                    matcher         = new RegExp("^" + jQuery.ui.autocomplete.escapeRegex(jQuery(this).val()) + "$", "i");
                    myInput         = jQuery(this);
                    autocomplete.widget().children(".ui-menu-item").each(() ->
                        #Check if each autocomplete item is a case-insensitive match on the input
                        item = jQuery(this).data("item.autocomplete");
                        if matcher.test(item.label || item.value || item)
                            #There was a match, lets stop checking
                            autocomplete.selectedItem = item
                            return
                    )
                    #if there was a match trigger the select event on that match
                    #I would recommend matching the label to the input in the select event
                    if autocomplete.selectedItem
                        autocomplete._trigger("select", event, {
                            item: autocomplete.selectedItem
                        })
                    #there was no match, clear the input
                    else
                        jQuery(this).val("")
                )
                $documentBody.off("keyup", "input#signup-location-country").on("keyup", "input#signup-location-country", (event) ->
                    keycode = event?.keyCode or event?.which
                    if keycode is ENTER_KEY
                        $city.focus()
                        event.preventDefault()
                )
            )
            $documentBody.off("focus", "input#signup-location-city-state").on("focus", "input#signup-location-city-state", (event) ->
                console.log "focus input#signup-location-city-state"
                $city.val("")
                $city.autocomplete({
                    source: ( request, response )->
                        jQuery.getJSON "/api/getCities/",{term:request.term,ISO2:ISO2,maxRows:12},response
                    , minLength   :   1
                    , select      :   ( event, ui )->
                        #TODO set the currentLocation to the new values.
                        longitude   = ui.item.longitude
                        latitude    = ui.item.latitude
                    , autoFocus   : true
                    , autoSelect  : true
                })
                $documentBody.off("blur", "input#signup-location-city-state").on("blur", "input#signup-location-city-state", (event) ->
                    console.log "on blur city autocomplete"
                    autocomplete    = jQuery(this).data("autocomplete");
                    matcher         = new RegExp("^" + jQuery.ui.autocomplete.escapeRegex(jQuery(this).val()) + "$", "i");
                    myInput         = jQuery(this);
                    autocomplete.widget().children(".ui-menu-item").each(() ->
                        #Check if each autocomplete item is a case-insensitive match on the input
                        item = jQuery(this).data("item.autocomplete");
                        if matcher.test(item.label || item.value || item)
                            #There was a match, lets stop checking
                            autocomplete.selectedItem = item
                            return
                    )
                    #if there was a match trigger the select event on that match
                    #I would recommend matching the label to the input in the select event
                    if autocomplete.selectedItem
                        autocomplete._trigger("select", event, {
                            item: autocomplete.selectedItem
                        })
                    #there was no match, clear the input
                    else
                        jQuery(this).val("")
                )
                $documentBody.off("keyup", "input#signup-location-city-state").on("keyup", "input#signup-location-city-state", (event) ->
                    keycode = event?.keyCode or event?.which
                    if keycode is ENTER_KEY
                        $neighborhood.focus()
                        event.preventDefault()
                )
            )
            #################################################################################
            # Setup signup form validation that hooks to the customs validation functions
            # below - validateUserName, validatePassword, validategn. Note:
            # can"t optimize the setup since the elements are recreated everytime the
            # colorbox is created.
            #################################################################################
            $documentBody.off("keyup", "input#signup-email").on("keyup", "input#signup-email", (event) ->
                keycode = event?.keyCode or event?.which
                if keycode is ENTER_KEY and validateEmail(jQuery(this).val())
                    $username.focus()
                    $emailError.text("")
                    event.preventDefault()
            )
            $documentBody.off("keyup", "input#signup-username").on("keyup", "input#signup-username", (event) ->
                console.log "in username text box key press " + event.keyCode
                keycode = event?.keyCode or event?.which
                if keycode is ENTER_KEY and validateUsername(jQuery(this).val())
                    $password.focus()
                    $usernameError.text("")
                    event.preventDefault()
            )
            $documentBody.off("keyup", "input#signup-password").on("keyup", "input#signup-password", (event) ->
                keycode = event?.key or event?.which
                if keycode is ENTER_KEY and validatePassword(jQuery(this).val())
                    $country.focus()
                    $passwordError.text("")
                    event.preventDefault()
            )
            $documentBody.off("keyup", "input#signup-location-country").on("keyup", "input#signup-location-country", (event) ->
                keycode = event?.keyCode or event?.which
                if keycode is ENTER_KEY and validateLocation(jQuery(this).val())
                    $city.focus()
                    $countryError.text("")
                    event.preventDefault()
            )
            $documentBody.off("keyup", "input#signup-location-city-state").on("keyup", "input#signup-location-city-state", (event) ->
                keycode = event?.keyCode or event?.which
                if keycode is ENTER_KEY and validateLocation(jQuery(this).val())
                    $neighborhood.focus()
                    event.preventDefault()
            )
            $documentBody.off("keyup", "input#signup-neighborhood").on("keyup", "input#signup-neighborhood", (event) ->
                keycode = event?.keyCode or event?.which
                if keycode is ENTER_KEY
                    $email.focus()
                    event.preventDefault()
            )
            ## Flags to minimize the checks with the server.
            oldusername = oldemail = ""
            $documentBody.off("blur", "input#signup-username").on("blur", "input#signup-username", (event) ->
                username = jQuery(this).val()
                if oldusername != username and validateUsername(username)
                    oldusername = username
                    rpc.request({
                        url: "../../../api/checkUsernameAvailability/",
                        method: "POST",
                        data: { "username": username }
                        },(response) ->
                            result = JSON.parse(response.data)
                            if result.response is "taken"
                                message = """<p>The username has been taken.  Please choose new username</p>"""
                                $usernameError.html(message).fadeIn(1500).delay(3500).fadeOut(1500)
                        , (error) ->
                            message = """<p>We can not verify username uniqueness with our server.  Sorry for the inconvenience.</p>"""
                            $usernameError.html(message).fadeIn(1500).delay(3500).fadeOut(1500)
                    )
                event.preventDefault()
            )
            $documentBody.off("blur", "input#signup-email").on("blur", "input#signup-email", (event) ->
                email = jQuery(this).val()
                if oldemail != email and validateEmail(email)
                    await jQuery.getJSON "/api/getAllValidEmailDomainNames/", defer domainNames
                    jQuery(this).mailcheck(domainNames, {
                        suggested: (element, suggestion) ->
                            message     = """<p>Suggested email: #{suggestion.full}</p>"""
                            $emailError.html(message).fadeIn(1500).delay(4500).fadeOut(1500)
                        empty: (element) ->
                            return
                    })
                    oldemail = email
                    rpc.request({
                        url: "../../../api/checkEmailDuplication/",
                        method: "POST",
                        data: { "email": email }
                        },(response) ->
                            result      = JSON.parse(response.data)
                            message     = """<p>The email provided is already in the system.  Please choose new email to proceed.</p>"""
                            if result.response is  "duplicate"
                                $emailError.html(message).fadeIn(1500).delay(3500).fadeOut(1500)
                        , (error) ->
                            message     = """<p>We can not check if the email has been registered with our server at the moment.
                                                Sorry for the inconvenience.</p>"""
                            $emailError.html(message).fadeIn(1500).delay(3500).fadeOut(1500)
                    )
                event.preventDefault()
            )
            $documentBody.off("submit", "form#signup-form").on("submit", "form#signup-form", (event) ->
                #TODO change the location info into the appropriate ones.
                console.log "latitude " + latitude + " " + longitude
                if validateForm()
                    rpc.request({
                        url: "../../../api/register/",
                        method: "POST",
                        data: { "email": $email.val(), "username": $username.val()
                        , "password": $password.val(), "city": $city.val()
                        , "country": $country.val(), "neighborhood"  : $neighborhood.val()
                        , "latitude": latitude, "longitude": longitude
                        }
                    }, (response) ->
                        result = JSON.parse(response.data)
                        console.log JSON.parse(response.data)
                        # 1. Show success status.
                        # 2. Slowly fade the colorbox and close it.
                        if result.response isnt "success"
                            message         = """<p>There is an error occurred while we try to register your account.
                                                Sorry for the inconvenience.  If the problem persists,
                                                please contact admin@melisting.com for further assistance.</p>"""
                            if result.message.contains("duplicate key error")
                                message     = "<p>The email/username chosen is already in the system.  Please choose new email/username to signup.</p>"
                            $formError.html(message).fadeIn(1500).delay(3500).fadeOut(1500)

                        else
                            jQuery("h1#popup-title").replaceWith("<h1>Success<br>Welcome to <span>listsil</span></h1>")
                            jQuery("form#signup-form").replaceWith("""<div id="signup-success">         
                                                                        <h5>  
                                                                            Thank you for setting up an account, now you can list items, rate listers, contact listers, and save lists of your farvorite stuff right as you browse.
                                                                        </h5>
                                                                        <p>
                                                                            Find what you're looking for:
                                                                            <img src="images/search-box.png" alt="Search box"/>
                                                                        </p>
                                                                        <p>
                                                                            Start listing your extra stuff
                                                                            <img src="images/list-something.png" alt="Listing button"/>
                                                                        </p>
                                                                        <p>
                                                                            Use the dynamic filters to focus your search and find exactly what you are looking for.
                                                                            <img src="images/filter-icons.png" alt="filter icons"/>
                                                                        </p>
                                                                        <h3>Happy Listing!</h3>
                                                                    </div>""")
                    , (error) ->
                        message         = """<p>There is an error occurred while we try to register your account.
                                                Sorry for the inconvenience.</p>
                                             <p>If the problem persists,
                                                please contact admin@melisting.com for further assistance.</p>"""
                        $formError.html(message).fadeIn(1500).delay(3500).fadeOut(1500)
                    )
                else
                    message         = """<p>We"re sorry, but the form contains errors.</p>
                                            <p>Please correct them below and resubmit. Thank you.</p>"""
                    $formError.html(message).fadeIn(1500).delay(3500).fadeOut(1500)
                event.preventDefault()
            )
            validateForm    = () ->
                console.log "validate form is called"
                result      = true
                if !validateEmail($email.val())
                    result  = false
                    $emailError.html("<p>Email has to be in the format: i.e. email@yourdomain.com.</p>")
                    $email.css("border", "3px solid #F00")
                else
                    $emailError.text("")
                    $email.css("border", "3px solid #CCC")
                if !validateUsername($username.val())
                    result  = false
                    $usernameError.html("<p>Username has to be of 6 to 8 characters.</p>")
                    $username.css("border","3px solid #F00")
                else
                    $usernameError.text("")
                    $username.css("border","3px solid #CCC")
                if !validatePassword($password.val())
                    result  = false
                    $passwordError.html("<p>Password has to be at least of 6 characters.  Recommended to have combination of letters and numbers.</P>")
                    $password.css("border","3px solid #F00")
                else
                    $passwordError.text("")
                    $password.css("border", "3px solid #CCC")
                if  !$terms.is(":checked")
                    result  = false
                    $termsError.html("<p>The terms of use has to be checked as in agreement to proceed.</p>")
                else
                    $termsError.text("")
                if !validateCountry($country.val())
                    result  = false
                    $countryError.html("<p>Country entered is not valid</p>")
                    $country.css("border","3px solid #F00")
                else
                    $countryError.text("")
                    $country.css("border","3px solid #CCC")
                if !validateCity($city.val())
                    result  = false
                    $cityError.html("<p>Cit and/or State entered is not valid</p>")
                    $city.css("border","3px solid #F00")
                else
                    $cityError.text("")
                    $city.css("border","3px solid #CCC")
                return result
            event.preventDefault()
        )
        $documentBody.off("click", "a#signup-form-close").on("click", "a#signup-form-close", () ->
            jQuery.colorbox.close()
            isotope.play() if isotope and isInitiallyPlaying
        )
        $documentBody.off("click", "label#term-of-use").on("click", "label#term-of-use", (event) ->
            console.log "term of use clicked"
        )

        #################################################################################
        # Setup the filters section.
        #################################################################################
        ##
        # @params exceptFilterID    - string representing the id of the excepted filter.
        #                             If the string is null or empty, all are hidden. 
        ##
        hideAllFiltersExcept                = (exceptFilterID) ->
            #Hide the signin box as well if it is open.
            jQuery("a#close-signin-form").click()
            jQuery.each([ "#category-filter-section", "#location-filter-section", "#wishlist-filter-section"], (index, value) ->
                if value isnt exceptFilterID
                    jQuery(value).hide('fast')
            )
        ##
        # @params $element          - the jQuery element of the filter section
        ##
        pauseIsotopePlayerForFilterSection  = ($filterSection) ->
            if $filterSection.is(":visible")
                $playButton.click() if isotope and not isotope.isPlaying()
            else
                $pauseButton.click() if isotope and isotope.isPlaying()

        $categoryFilterSection = jQuery("#category-filter-section")
        $documentBody.off("click", "#category-filter").on("click", "#category-filter", (event) ->
            hideAllFiltersExcept("#category-filter-section")
            pauseIsotopePlayerForFilterSection($categoryFilterSection)
            $categoryFilterSection.slideToggle('fast')
            event.preventDefault()
        )
                  ##
        # Set up the category filter.
        #
        # We color the background of the p element (name of the category) to help users recognize
        # categories we match by the predetermined from the calculation below.
        ##
        # We split categories string into an array.
        selectors           = []
        filters             = "" # filter string for isotope.
        assignColors        = (categories) ->
            result          = {}
            colorString     = "rgba({0}, {1}, {2}, 0.2)"
            for category, i in categories
                result[category] = colorString.format((0 + i * 71) % 255, (150 + i * 29) % 255, (50 + i * 17) % 255)
            return result
        categoryColorMap            = assignColors(categories)
        filterAndColorBackground    = (element, category) ->
            noColor                 = ""
            color                   = categoryColorMap[category] or noColor 
            category                = "." + category.split(" ").join('-')
            if element.is(':checked')
                element.next().css("background-color", color)
                selectors.push(category)
            else
                element.next().css("background-color", noColor)
                selectors           = _.without(selectors, category)
            if selectors
                filters             = selectors.join(",")
            else 
                filters             = "*"
            filterByCategory(filters) 
        ##        
        # some categories are multi words. 
        # so we need to replace space with - for class name 
        # to filter the display items by category name.
        # i.e. .Applicances and .Cars-&-Trucks
        ##
        filterByCategory    = (fitlers) ->
            $container.isotope({
                filter: filters
            });
        selected            = jQuery("input[name=category]:checked")
        jQuery(selected).each((element) ->
            element         = jQuery(this)
            category        = element.attr("value")
            filterAndColorBackground(element, category)            )
        $documentBody.off("click", "input.category").on("click", "input.category", (event) ->
            element         = jQuery(this)
            category        = element.attr("value")
            filterAndColorBackground(element, category)
        )
        ##
        # Setup the distance click event.
        ##
        $documentBody.off("click", "input.distance-range").on("click", "input.distance-range", (event) ->
            distance = jQuery("input[name=range]:checked").val()
            console.log distance + " was checked"
        )

        ##
        # Set up CloudMade map
        ##
        map = null
        displayCurrentMap   = () ->
            if map is null
                map = new L.Map('map')
                tiles = new L.StamenTileLayer('watercolor')
                #map.addLayer(tiles)
                L.tileLayer('http://{s}.tile.cloudmade.com/552ed20c2dcf46d49a048d782d8b37e6/997/256/{z}/{x}/{y}.png', {
                    attribution: 'Map data &copy; <a href="http://openstreetmap.org">OpenStreetMap</a> contributors, <a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>, Imagery © <a href="http://cloudmade.com">CloudMade</a>',
                    maxZoom: 18
                }).addTo(map)
                map.setView(new L.LatLng(latitude, longitude), 13)
                
                markers = new L.MarkerClusterGroup()
                ##
                # TODO setup the marker from the postiems queried.
                ##
                for i in [1..100]
                    marker = new L.Marker(new L.LatLng(latitude + i / 10000, longitude + i / 10000))
                    markers.addLayer(marker)
                
                map.addLayer(markers)
            else
                map.setView(new L.LatLng(latitude, longitude), 13)
        ##
        # Set up location change filter.
        ##
        $locationFilterSection = jQuery("#location-filter-section")
        $documentBody.off("click","#location-filter").on("click","#location-filter", (event) ->
            hideAllFiltersExcept("#location-filter-section")
            $city              = jQuery("input#location-city-state-change-text-input")
            $country           = jQuery("input#location-country-change-text-input")
            pauseIsotopePlayerForFilterSection($locationFilterSection)
            $locationFilterSection.slideToggle('fast')
            displayCurrentMap()
            #TODO take care of the case where city is equal to state.
            if currentLocation.city is currentLocation.state
                $city.attr("placeholder", currentLocation.city)
            else
                $city.attr("placeholder", currentLocation.city + ", " + currentLocation.state)
            $country.attr("placeholder", currentLocation.country)
            if $country.val() is ""
                    $city.val("")
                    $city.attr("disabled", true)
            #TODO set the new current city, state and country when the user changes the location.
            $documentBody.off("focus", "input#location-country-change-text-input").on("focus", "input#location-country-change-text-input", (event) ->
                $country.val("")
                $city.val("")
                $city.attr("disabled", true)
                #TODO we need to set the current location info after change.
                $country.autocomplete({
                    source       : ( request, response )->
                        #Check it is it is illegal number - http://www.w3schools.com/jsref/jsref_isnan.asp.
                        if isNumber(request.term)
                            jQuery.getJSON "/api/getCitiesByZipcode/",{term:request.term,maxRows:12},response
                        else
                            jQuery.getJSON "/api/getCountries/",{term:request.term,maxRows:12},response
                    ,minLength   :  1
                    ,select      :  ( event, ui )->
                        if ui.item.ISO2
                            ISO2 = ui.item.ISO2
                        else
                            #TODO set the input fields with appropriate values.
                            longitude   = ui.item.longitude
                            latitude    = ui.item.latitude
                            $city.val(ui.item.address)
                        $city.removeAttr("disabled")
                    , autoFocus   : true
                    , autoSelect  : true
                })
                $documentBody.off("blur", "input#location-country-change-text-input").on("blur", "input#location-country-change-text-input", (event) ->
                    autocomplete    = jQuery(this).data("autocomplete")
                    matcher         = new RegExp("^" + jQuery.ui.autocomplete.escapeRegex(jQuery(this).val()) + "$", "i");
                    myInput         = jQuery(this)
                    autocomplete.widget().children(".ui-menu-item").each(() ->
                        #Check if each autocomplete item is a case-insensitive match on the input
                        item = jQuery(this).data("item.autocomplete")
                        if matcher.test(item.label || item.value || item)
                            #There was a match, lets stop checking
                            autocomplete.selectedItem = item
                            return
                    )
                    #if there was a match trigger the select event on that match
                    #I would recommend matching the label to the input in the select event
                    if autocomplete.selectedItem
                        autocomplete._trigger("select", event, {
                            item: autocomplete.selectedItem
                        })
                    #there was no match, clear the input
                    else
                        jQuery(this).val("")
                )
                $documentBody.off("keyup", "input#location-country-change-text-input").on("keyup", "input#location-country-change-text-input", (event) ->
                    keycode = event?.keyCode or event?.which
                    if keycode is ENTER_KEY
                        $city.focus()
                        event.preventDefault()
                )
                $documentBody.off("focus", "input#location-city-state-change-text-input").on("focus", "input#location-city-state-change-text-input", (event) ->
                    $city.val("")
                    $city.autocomplete({
                        source: ( request, response )->
                            jQuery.getJSON "/api/getCities/",{term:request.term,ISO2:ISO2,maxRows:12},response
                        , minLength   :   1
                        , select      :   ( event, ui )->
                            #Assign new value for latlong, city, country displays
                            #and reset the map.
                            longitude               = ui.item.longitude
                            latitude                = ui.item.latitude
                            locationWatcher.country = ISO2
                            #TODO we have to parse the city and state to see if it is just city or city with state.
                            #then we update the ui appropriately.
                            locationWatcher.city    = ui.item.value
                            displayCurrentMap()
                            #TODO we have to take care of the city and state not the same.
                            $city.attr("placeholder", currentLocation.city)
                            $country.attr("placeholder", currentLocation.country)
                            $country.focus()
                        , autoFocus   : true
                        , autoSelect  : true
                    })
                )
                $documentBody.off("blur", "input#location-city-state-change-text-input").on("blur", "input#location-city-state-change-text-input", (event) ->
                    autocomplete    = jQuery(this).data("autocomplete");
                    matcher         = new RegExp("^" + jQuery.ui.autocomplete.escapeRegex(jQuery(this).val()) + "$", "i");
                    myInput         = jQuery(this);
                    autocomplete.widget().children(".ui-menu-item").each(() ->
                        #Check if each autocomplete item is a case-insensitive match on the input
                        item = jQuery(this).data("item.autocomplete")
                        if matcher.test(item.label || item.value || item)
                            #There was a match, lets stop checking
                            autocomplete.selectedItem = item
                            return
                    )
                    #if there was a match trigger the select event on that match
                    #I would recommend matching the label to the input in the select event
                    if autocomplete.selectedItem
                        autocomplete._trigger("select", event, {
                            item: autocomplete.selectedItem
                        })
                    #there was no match, clear the input
                    else
                        jQuery(this).val("")
                )

                event.preventDefault()
            )

        )

        ##
        # Set up the wishlist filter
        #
        # Transform returned value from wishlist query into an appropriate html fragment
        # for display within div#es-carousel.
        # We transform just one postitem at a time.
        ##
        transformWishListToHtml     = (json) ->
            result                  = '''
                                            <li id="xxxxxxxxx-wishlistID" class="wishlist-postitem">
                                              <a href="javascript:void(0);">
                                                <img src="http://farm1.static.flickr.com/163/399223609_db47d35b7c_t.jpg" />
                                              </a>
                                              <p class="wishlist-postitem-delete"><a href="javascript:void(0);">delete</a></p>
                                            </li>
                                      '''
            return result

        $wishlistFilterSection              = jQuery("#wishlist-filter-section")
        $wishlistCarousel                   = jQuery("div#es-carousel-wrapper-wishlist")
        $wishlistCarouselList               = $wishlistCarousel.find("#es-carousel ul") 
        isCarouselInitialized               = false
        wishlists                           = {}

        $documentBody.off("click", "#wishlist-filter").on("click", "#wishlist-filter", (event) ->
            #TODO check if the user is logged in if not inform user and block.
            if not loggedin
                console.log "log in before checking your wishlist."
                return

            hideAllFiltersExcept("#wishlist-filter-section")
            
            if not isCarouselInitialized
                $wishlistCarousel.elastislide({
                                    imageW      : 100,
                                    minItems    : 3,
                                    border      : 0,
                                    onClick     : ($item) ->
                                        console.log $item
                                })
                isCarouselInitialized       = true
            pauseIsotopePlayerForFilterSection($wishlistFilterSection)
            if $wishlistFilterSection.is(":visible")
                ## jQuery("#wishlist-filter-section").attr("style", "display:none;")
                ## There is a bug in jQuery that does not set the display:block but 
                ## display:inline when use toggle with this elelment.
                $wishlistFilterSection.slideToggle('fast')
            else
                # jQuery("#wishlist-filter-section").attr("style", "display:block;")
                # TODO dynamically add items and show the item detail when clicked.
                # var $items  = $('<li><a href="#"><img src="images/large/1.jpg" alt="image01" /></a></li><li><a href="#"><img src="images/large/2.jpg" alt="image01" /></a></li>');
                # $('#carousel').append($items).elastislide( 'add', $items ); 
                ##
                # We setup the wishlist by querying the server and display it
                # in the carousel.
                #
                ##
                rpc.request({
                        url: "../../../api/wishlist/{0}/".format(username),
                        method: "GET",
                        data: {}
                    },(response) ->
                        result          = JSON.parse(response.data)
                        if  result.response is "success"
                            wishlists   = result.context
                            if not wishlists
                                $wishlistCarouselList.html("<li>No item yet.  Add some!</li>")
                            else
                                $wishlistCarouselList.html("")
                                console.log "success"
                                for id, wishlist of wishlists
                                    console.log "iterate wishlists"
                                    # process the returned result and place it into the carosel.
                                    #$item        = jQuery(transformWishListToHtml(wishlist.postitem[0]))
                                    $items       = jQuery('<li><a href="#"><img src="http://farm1.static.flickr.com/163/399223609_db47d35b7c_t.jpg" alt="image01" /></a></li><li><a href="#"><img src="http://farm1.static.flickr.com/163/399223609_db47d35b7c_t.jpg" alt="image01" /></a></li>');
                                    $wishlistCarouselList.append($item)
                                    $wishlistCarousel.elastislide('add', $item)
                                ##TODO remove this test code.
                                $item        = jQuery(transformWishListToHtml("dummy"))
                                $wishlistCarouselList.append($item)
                                $wishlistCarousel.elastislide('add', $item)
                    , (error) ->
                        #TODO take care of the error.
                        console.log "error"
                        console.log error
                )
                $wishlistFilterSection.slideToggle('fast')
                event.preventDefault()
        )
        ##
        # TODO Bind this carousel with delete and hover function.
        ##
        $documentBody.off("hover", "li.wishlist-postitem").on("hover", "li.wishlist-postitem", (event) ->
            if event.type is "mouseenter"
                console.log "hover on wishlist item"
            else
                console.log "hover off wishlist item"
        )
        $documentBody.off("click", "li.wishlist-postitem").on("click", "li.wishlist-postitem", (event) ->
            console.log "click on wishlist item"
        )
        $documentBody.off("click", "p.wishlist-postitem-delete").on("click", "p.wishlist-postitem-delete", (event) ->
            console.log "delete wishlist item"
            wishlistID              = 0
            rpc.request({
                    url: "../../../api/wishlist/{0}/".format(wishlistID),
                    method: "DELETE",
                    data: {}
                },(response) ->
                    result          = JSON.parse(response.data)
                    if result.response is "success"
                        console.log "success"
                        $item       = $wishlistCarouselList.find("li#" + wishlistID)
                        $item.remove()
                        $wishlistCarousel.elastislide("remove", $item)
                        ##check if there is any item left in the list.
                        ##TODO ajust the display appropriately.
                        if $wishlistCarouselList.children().length <= 0
                            console.log "carousel list is empty" 
                , (error) ->
                    #TODO take care of the error.
                    console.log "error"
                    console.log error
            )
            ##TODO remove this test code.
            $item = $wishlistCarouselList.find("li#xxxxxxxxx-wishlistID")
            $item.remove()
            $wishlistCarousel.elastislide("remove", $item)
            if $wishlistCarouselList.children().length <= 0
                console.log "carousel list is empty"
            event.preventDefault() 
        )
        #################################################################################
        # Setup the posting form.
        #################################################################################
        $documentBody.off("click", "a#list-something").on("click", "a#list-something", (event) ->
            hideAllFiltersExcept("none")
            jQuery("a#close-signin-form").click()
            if !loggedin
                ##TODO warn the user that he/she has to log in before posting.
                console.log "log in before posting."
                event.preventDefault()
                return
            address             = null
            $listingForm        = $uploadbar            = $uploadbar            = null
            $title              = $description          = $city                 = null
            $email              = $showEmail            = $price                = null
            $country            = $priceError           = $countryError         = null
            $exchangeOptions    = $category             = $neighborhood         = null
            $titleError         = $descriptionError     = $emailError           = null
            $mediaError         = $exchangeOptionsError = $categoryError        = null
            $listingFormError   = $cancelUploadSection  = $cityError            = null
            jQuery.colorbox.remove()
            jQuery.colorbox({ href:"/pages/new-listing/", width: "100%", height: "100%", close:""
            , onClosed: () ->
                console.log "onclose newlisting colorbox"
            , onComplete: () ->
                console.log "completed newlisting colorbox"
                categories = {}
                #TODO substitute in the values country, state and city.
                await jQuery.getJSON "/api/getCategories/", defer categories
                $listingForm            = jQuery("form#listing-form")
                $uploadbar              = jQuery("div#uploadbar")
                $title                  = jQuery("input#listing-title")
                $description            = jQuery("textarea#listing-description")
                $email                  = jQuery("input#listing-email")
                $showEmail              = jQuery("input#listing-show-email")
                $price                  = jQuery("input#listing-price")
                $category               = jQuery("input#listing-category")
                $exchangeOptions        = jQuery("input[name='exchange-options']")
                $city                   = jQuery("input#listing-location-city-state")
                $country                = jQuery("input#listing-location-country")
                $neighborhood           = jQuery("input#listing-location-neighborhood")
                $titleError             = jQuery("div#listing-title-error")
                $descriptionError       = jQuery("div#listing-description-error")
                $mediaError             = jQuery("div#listing-media-error")
                $priceError             = jQuery("div#listing-price-error")
                $exchangeOptionsError   = jQuery("div#listing-exchange-options-error")
                $categoryError          = jQuery("div#listing-category-error")
                $emailError             = jQuery("div#listing-email-error")
                $countryError           = jQuery("div#listing-location-country-error")
                $cityError              = jQuery("div#listing-location-city-state-error")
                $listingFormError       = jQuery("div#listing-form-error")
                $cancelUploadSection    = jQuery("div#listing-form-cancel-upload")
                $photoFileUpload        = jQuery("input#media-input-listing-photo")
                $videoFileUpload        = jQuery("input#media-input-listing-video")
                $voiceFileUpload        = jQuery("input#media-input-listing-voice")
                $title.focus()
                $email.val(jQuery?.cookies?.get(key))
                if !currentLocation.state or currentLocation.city is currentLocation.state
                    $city.val(currentLocation.city)
                else
                    $city.val(currentLocation.city + ", " + currentLocation.state)
                $country.val(currentLocation.country)
                $neighborhood.val(currentLocation.neighborhood)
                if $country.val() is ""
                    $city.val("")
                    $city.attr("disabled", true)
                    $neighborhood.val("")
                $category.autocomplete({ source: categories })

                ##
                # We set up the file upload with Kendo UI upload widget.
                ##
                $photoFileUpload.kendoUpload({
                    localization: {select: "Photos"},
                    success: (event) -> onSuccess(event, "photos"),
                    error: (event) -> onError(event, "photos"),
                    upload: (event) -> onUpload(event, "photos"),
                    select: (event) -> onSelect(event, "photos"),
                    remove: (event) -> onRemove(event, "photos")
                })
                $videoFileUpload.kendoUpload({
                    localization: {select: "Video"},
                    success: (event) -> onSuccess(event, "video"),
                    error: (event) -> onError(event, "video"),
                    upload: (event) -> onUpload(event, "video"),
                    select: (event) -> onSelect(event, "video"),
                    remove: (event) -> onRemove(event, "video")
                })
                $voiceFileUpload.kendoUpload({
                    localization: {select: "Voice"},
                    success: (event) -> onSuccess(event, "voice"),
                    error: (event) -> onError(event, "voice"),
                    upload: (event) -> onUpload(event, "voice"),
                    select: (event) -> onSelect(event, "voice"),
                    remove: (event) -> onRemove(event, "voice")
                })

                if isotope
                    isInitiallyPlaying = isotope.isPlaying()
                    isotope.stop()

            })
            ##
            # TODO Setup the handlers for file upload widget.
            # 
            # TODO take care of the error.
            ##
            numberOfPhotosUploaded = numberOfVideoUploaded = numberOfVoiceUploaded = 0
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
                                    $mediaError.html("<p>Photo has to be in gif or png or jpeg or bmp format.</p>").fadeIn(1500).delay(3500).fadeOut(1500)
                                    numberOfPhotosUploaded = numberOfPhotosUploaded - len
                                    event.preventDefault()
                                if file.size > 2468000
                                    $mediaError.html("<p>Photo file is bigger than 2.5 mb limit.</p>").fadeIn(1500).delay(3500).fadeOut(1500)
                                    numberOfPhotosUploaded = numberOfPhotosUploaded - len
                                    event.preventDefault()
                            )
                            numberOfPhotosUploaded = numberOfPhotosUploaded + len
                        else
                            $mediaError.html("<p>Only 4 photos are allowed for the upload.</p>").fadeIn(1500).delay(3500).fadeOut(1500)
                            event.preventDefault()
                    when "video"
                        if numberOfVideoUploaded < 1
                            jQuery.each(files, (index, file) ->
                                if jQuery.inArray(file.extension.toLowerCase(), [".mp4", ".mpeg", ".mov", ".x-msvideo", ".avi", ".msvideo", ".x-msvideo", ".3gpp", ".mpeg", ".quicktime", ".MP2P", ".MP1S", ".x-flv"]) is -1
                                    $mediaError.html("<p>Video recording has to be in the acceptable video formats i.e. mp4, mpeg, etc.</p>").fadeIn(1500).delay(3500).fadeOut(1500)
                                    numberOfVideoUploaded = numberOfVideoUploaded - len
                                    event.preventDefault()
                                if file.size > 10240000
                                    $mediaError.html("<p>Video file is bigger than 10 mb limit.</p>").fadeIn(1500).delay(3500).fadeOut(1500)
                                    numberOfVideoUploaded = numberOfVideoUploaded - len
                                    event.preventDefault()
                            )
                            numberOfVideoUploaded = numberOfVideoUploaded + len
                        else
                            $mediaError.html("<p>Only 1 video is allowed for the upload.</p>").fadeIn(1500).delay(3500).fadeOut(1500)
                            event.preventDefault()
                    when "voice"
                        if numberOfVoiceUploaded  < 1
                            jQuery.each(files, (index, file) ->
                                console.log file
                                if jQuery.inArray(file.extension.toLowerCase(), [".mp3"]) is -1
                                    $mediaError.html("<p>Voice recording has to be in mp3 format.</p>").fadeIn(1500).delay(3500).fadeOut(1500)
                                    numberOfVoiceUploaded   = numberOfVoiceUploaded - len
                                    event.preventDefault()
                                if file.size > 10240000
                                    $mediaError.html("<p>Voice file is bigger than 10 mb limit.</p>").fadeIn(1500).delay(3500).fadeOut(1500)
                                    numberOfVoiceUploaded   = numberOfVoiceUploaded - len
                                    event.preventDefault()
                            )
                            numberOfVoiceUploaded = numberOfVoiceUploaded + len
                        else
                            $mediaError.html("<p>Only 1 voice recording is allowed for the upload.</p>").fadeIn(1500).delay(3500).fadeOut(1500)
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
            ##
            # Setup listing form validation that hooks to the customs validation functions
            # below - validateTitle, validateDescription, validatePrice,
            # validateEmail, validateLocation.
            ##
            $documentBody.off("focus", "input#listing-location-country").on("focus", "input#listing-location-country", (event) ->
                console.log "in focus country"
                $country.val("")
                $city.val("")
                $city.attr("disabled", true)
                $neighborhood.val("")
                #TODO we need to set the current location info after change.
                $country.autocomplete({
                    source        : (request, response)->
                        #Check it is it is illegal number - http://www.w3schools.com/jsref/jsref_isnan.asp.
                        if isNumber(request.term)
                            jQuery.getJSON "/api/getCitiesByZipcode/",{term:request.term,maxRows:12},response
                        else
                            jQuery.getJSON "/api/getCountries/",{term:request.term,maxRows:12},response
                    , minLength   :  1
                    , select      :  (event, ui) ->
                        if ui.item.ISO2
                            ISO2 = ui.item.ISO2
                            $city.removeAttr("disabled")
                        else
                            #TODO set the appropriate values for the fields.
                            longitude   = ui.item.longitude
                            latitude    = ui.item.latitude
                            this.value  = ui.item.country
                            ISO2        = ui.item.country
                            $city.val(ui.item.address)

                    , autoFocus  : true
                    , autoSelect : true
                })
                $documentBody.off("blur", "input#listing-location-country").on("blur", "input#listing-location-country", (event) ->
                    console.log "on blur country autocomplete"
                    autocomplete    = jQuery(this).data("autocomplete")
                    matcher         = new RegExp("^" + jQuery.ui.autocomplete.escapeRegex(jQuery(this).val()) + "$", "i");
                    myInput         = jQuery(this)
                    autocomplete.widget().children(".ui-menu-item").each(() ->
                        #Check if each autocomplete item is a case-insensitive match on the input
                        item = jQuery(this).data("item.autocomplete");
                        if matcher.test(item.label || item.value || item)
                            #There was a match, lets stop checking
                            autocomplete.selectedItem = item
                            return
                    )
                    #if there was a match trigger the select event on that match
                    #I would recommend matching the label to the input in the select event
                    if autocomplete.selectedItem
                        autocomplete._trigger("select", event,{
                            item: autocomplete.selectedItem
                        })
                    #there was no match, clear the input
                    else
                        jQuery(this).val("")
                )
                $documentBody.off("keyup", "input#listing-location-country").on("keyup", "input#listing-location-country", (event) ->
                    keycode = event?.keyCode or event?.which
                    if keycode is ENTER_KEY
                        $city.focus()
                        event.preventDefault()
                )
            )
            $documentBody.off("focus", "input#listing-location-city-state").on("focus", "input#listing-location-city-state", (event) ->
                console.log "focus input#listing-location-city-state"
                $city.val("")
                $neighborhood.val("")
                $city.autocomplete({
                    source: ( request, response )->
                        jQuery.getJSON "/api/getCities/",{term:request.term,ISO2:ISO2,maxRows:12},response
                    , minLength   :   1
                    , select      :   ( event, ui )->
                        #TODO set appropriate values for location fields.
                        longitude   = ui.item.longitude
                        latitude    = ui.item.latitude
                    , autoFocus   : true
                    , autoSelect  : true
                })
                $documentBody.off("blur", "input#listing-location-city-state").on("blur", "input#listing-location-city-state", (event) ->
                    console.log "on blur city autocomplete"
                    autocomplete    = jQuery(this).data("autocomplete")
                    matcher         = new RegExp("^" + jQuery.ui.autocomplete.escapeRegex(jQuery(this).val()) + "$", "i");
                    myInput         = jQuery(this)
                    autocomplete.widget().children(".ui-menu-item").each(() ->
                        #Check if each autocomplete item is a case-insensitive match on the input
                        item = jQuery(this).data("item.autocomplete");
                        if matcher.test(item.label || item.value || item)
                            #There was a match, lets stop checking
                            autocomplete.selectedItem = item
                            return
                    )
                    ##
                    # if there was a match trigger the select event on that match
                    # I would recommend matching the label to the input in the select event.
                    ##
                    if autocomplete.selectedItem
                        autocomplete._trigger("select", event, {
                            item: autocomplete.selectedItem
                        })    
                    #there was no match, clear the input
                    else
                        jQuery(this).val("")
                )
                $documentBody.off("keyup", "input#listing-location-city-state").on("keyup", "input#listing-location-city-state", (event) ->
                    keycode = event?.keyCode or event?.which
                    if keycode is ENTER_KEY
                        $neighborhood.focus()
                        event.preventDefault()
                )
            )
            $documentBody.off("keyup", "input#listing-title").on("keyup", "input#listing-title", (event) ->
                keycode = event?.keyCode or event?.which
                if keycode is ENTER_KEY and validateTitle(jQuery(this).val())
                    $description.focus()
                    $titleError.text("")
                    $title.css("border","3px solid #CCC")
                    event.preventDefault()
            )
            $documentBody.off("keyup", "textarea#listing-description").on("keyup", "textarea#listing-description", (event) ->
                keycode = event?.keyCode or event?.which
                if keycode is ENTER_KEY and validateDescription(jQuery(this).val())
                    $email.focus()
                    $descriptionError.text("")
                    $description.css("border","3px solid #CCC")
                    event.preventDefault()
            )
            $documentBody.off("keyup", "input#listing-email").on("keyup", "input#listing-email", (event) ->
                keycode = event?.key or event?.which
                if keycode is ENTER_KEY and validateEmail(jQuery(this).val())
                    $price.focus()
                    $emailError.text("")
                    $email.css("border","3px solid #CCC")
                    event.preventDefault()
            )
            $documentBody.on("keyup", "input#listing-price", (event) ->
                keycode = event?.keyCode or event?.which
                if keycode is ENTER_KEY and validatePrice(jQuery(this).val())
                    console.log keycode + " " + jQuery(this).val()
                    $category.focus()
                    $priceError.text("")
                    $price.css("border","3px solid #CCC")
                    event.preventDefault()
            )
            $documentBody.off("keyup", "input#listing-category").on("keyup", "input#listing-category", (event) ->
                keycode = event?.keyCode or event?.which
                if keycode is ENTER_KEY and validateCategory(jQuery(this).val())
                    $country.focus()
                    $categoryError.text("")
                    $category.css("border","3px solid #CCC")
                    event.preventDefault()
            )
            $documentBody.off("keyup", "input#listing-location-country").on("keyup", "input#listing-location-country", (event) ->
                keycode = event?.keyCode or event?.which
                if keycode is ENTER_KEY and validateLocation(jQuery(this).val())
                    $city.focus()
                    $countryError.text("")
                    event.preventDefault()
            )
            $documentBody.off("keyup", "input#listing-location-city-state").on("keyup", "input#listing-location-city-state", (event) ->
                keycode = event?.keyCode or event?.which
                if keycode is ENTER_KEY and validateLocation(jQuery(this).val())
                    $neighborhood.focus()
                    $cityError.text("")
                    event.preventDefault()
            )
            $documentBody.off("keyup", "input#listing-location-neighborhood").on("keyup", "input#listing-location-neighborhood", (event) ->
                keycode = event?.keyCode or event?.which
                if keycode is ENTER_KEY
                    $title.focus()
                    event.preventDefault()
            )
            $documentBody.off("click", "input[name='exchange-options']").on("click", "input[name='exchange-options']", (event) ->
                console.log "click, input[name='exchange-options'] is clicked"
                $exchangeOptionsError.text("")
                showOtherOption = false
                jQuery("input:checkbox[name='exchange-options']:checked").each(
                    () ->
                        if jQuery(this).val() is "Other"
                            showOtherOption = true
                )
                if showOtherOption
                    jQuery("input#listing-exchange-options-other-text").show()
                else
                    jQuery("input#listing-exchange-options-other-text").hide()
            )

            ## Flags to minimize the checks with the server.
            oldEmail = ""
            $documentBody.off("blur", "input#listing-email").on("blur", "input#listing-email", (event) ->
                email = jQuery(this).val()
                if oldEmail != email and validateEmail(email)
                    oldEmail = email
                    rpc.request({
                        url: "../../../api/checkEmailDuplication/",
                        clearForm: true,
                        method: "POST",
                        data: { "email": email }
                        },(response) ->
                            result      = JSON.parse(response.data)
                            message     = """<p>The email provided is not in the system.  Please make sure you use the email registered with us.</p>"""
                            if result.response isnt  "duplicate"
                                $emailError.html(message).fadeIn(1500).delay(3500).fadeOut(1500)
                            else
                                ##set the cookie here to prepopulate the email field, since the user has authenticated here
                                # 1. We set a random number as key to a cookie and store the email there.
                                # 2. When we come back, check if the random number generated when page load has a value
                                #    associated with it.  If it has, use it to populate the email.
                                # 3. If not then, as the user to authenticate by inputing the email.
                                console.log "authenticated by providing the correct email."
                        , (error) ->
                            message     = """<p>We can not check if the email has been registered with our server at the moment.
                                                Sorry for the inconvenience.</p>"""
                            $emailError.html(message).fadeIn(1500).delay(3500).fadeOut(1500)
                    )
                event.preventDefault()
            )
            processID = null
            $documentBody.off("submit", "form#listing-form").on("submit", "form#listing-form", (event)->
                if validateForm()
                    await jQuery.getJSON "/api/getProcessID/", defer processID
                    jQuery("#listing-location-city-state").attr('disabled','disabled')
                    processID = processID
                    $listingForm.ajaxSubmit({
                        url: "/api/postitem/" + processID + "/"
                        ,success: (responseText, statusText, xhr, element) ->
                            result = responseText
                            if result?.response is "oversize"
                                files           = result?.message or ""
                                message         = """<p>The file(s) uploaded are over the limit of 2.5 mgb for Photos and 10 mgb for Voice and Video.
                                                        Please make sure you stay within limit for the uploads.  Please check files - #{ files }
                                                    </p>"""
                                $listingFormError.html(message).fadeIn(1500).delay(4500).fadeOut(1500)
                                processID       = null
                            else if result?.response is "success"
                                #TODO show the confirmation page.
                                message         = """<p>success</p>"""
                                $listingFormError.html(message).fadeIn(1500).delay(4500).fadeOut(1500)
                                processID       = null
                            else if result?.response is "abort"
                                #TODO take care of the abort
                                message         = """<p>abort</p>"""
                                $listingFormError.html(message).fadeIn(1500).delay(4500).fadeOut(1500)
                                processID       = null
                            else
                                message         = """<p>There is an error occured while trying to upload your files.
                                                        Please try again. If the problem persists, please contact
                                                        admin@melisting.com for further assistance.
                                                    </p>"""
                                $listingFormError.html(message).fadeIn(1500).delay(4500).fadeOut(1500)
                                processID       = null
                        ,error: () ->
                            message         = """<p>The download has been aborted. If this is due to a
                                                    technical problem and if the problem persists, please contact
                                                    admin@melisting.com for further assistance.
                                                </p>"""
                            $listingFormError.html(message).fadeIn(1500).delay(4500).fadeOut(1500)
                            processID           = null
                        ,data: { longitude:longitude, latitude:latitude, processID: processID, city: jQuery("#listing-location-city-state").val() }
                    })
                    uploadStatus()
                    $uploadbar.progressbar()
                    $uploadbar.css("display","block")
                    #jQuery.blockUI({ message: jQuery("#uploadbar") })
                    # jQuery.colorbox.close()
                else
                    message         = """<p>Thre is a validation error.  Please correct the error(s) before resubmitting.</p>"""
                    $listingFormError.html(message).fadeIn(1500).delay(3500).fadeOut(1500)
                event.preventDefault()
            )
            $documentBody.off("click", "input[type=button]#listing-form-cancel-upload").on("click", "input[type=button]#listing-form-cancel-upload", (event) ->
                if processID
                    rpc.request({
                        url: "../../../api/abortPosting/",
                        method: "POST",
                        data: { "processID": processID }
                    },(response) ->
                        result = JSON.parse(response.data)
                        if result.response is "success"
                            $uploadbar.css("display","none")
                            $cancelUploadSection.hide()
                            uploadStatus()
                            jQuery.colorbox.close()
                            $listingForm.clearForm()
                    , (error) ->
                        message         = """<p>There is an error occurred while we try to abort your posting.
                                                Sorry for the inconvenience.  If the problem persists,
                                                please contact admin@melisting.com for further assistance.</p>"""
                        $listingFormError.html(message).fadeIn(1500).delay(3500).fadeOut(1500)
                    )
                processID  = null
                jQuery.colorbox.close()
                $listingForm.clearForm()
                event.preventDefault()
            )
            $documentBody.off("click", "input[type=button]#listing-form-continue-upload").on("click", "input[type=button]#listing-form-continue-upload", (event) ->
                $cancelUploadSection.hide()
                event.preventDefault()
            )
            $documentBody.off("click", "a#listing-form-close").on("click", "a#listing-form-close", (event) ->
                isotope.play() if isotope and isInitiallyPlaying
                $cancelUploadSection.show()
                event.preventDefault()
            )
            updateStatus = null
            uploadStatus = ()->
                #We get the processID when uploading and set it to null when cancled.
                if processID
                    uri = "/api/uploadStatus/" + processID + "/"
                    status = {}
                    await jQuery.getJSON uri, defer status
                    $uploadbar.progressbar("value", status)
                    if status < 100
                        updateStatus = setTimeout(()->
                            uploadStatus()
                        , 300)
                    else
                        $uploadbar.css("display","none")
                        #Show upload complete confirmation.
                else
                    clearTimeout(updateStatus) if updateStatus
                    $uploadbar.css("display","none")

            validateForm    = () ->
                result      = true
                if !validateTitle($title.val())
                    result  = false
                    $titleError.html("<p>Title can not be shorter than 5 characters.</p>")
                    $title.css("border","3px solid #F00")
                else
                    $titleError.text("")
                    $title.css("border","3px solid #CCC")
                if !validateDescription($description.val())
                    result  = false
                    $descriptionError.html("<p>Description has to be of at least 8 characters.</p>")
                    $description.css("border","3px solid #F00")
                else
                    $descriptionError.text("")
                    $description.css("border","3px solid #CCC")
                if !validateEmail($email.val())
                    result  = false
                    $emailError.html("<p>Email has to be in the format: i.e. email@yourdomain.com.</p>")
                    $email.css("border", "3px solid #F00")
                else
                    $emailError.text("")
                    $email.css("border", "3px solid #CCC")
                if !validatePrice($price.val())
                    result  = false
                    $priceError.html("<p>Price has to be numeric like 1-999999999.</p>")
                    $price.css("border","3px solid #F00")
                else
                    $priceError.text("")
                    $price.css("border", "3px solid #CCC")
                if  !$exchangeOptions.is(":checked")
                    result  = false
                    $exchangeOptionsError.html("<p>At least one exhange option has to be selected.</p>")
                else
                    $exchangeOptionsError.text("")
                if !validateCategory($category.val())
                    result  = false
                    $categoryError.html("<p>Category can not be empty or fewer than 3 characters.</p>")
                    $category.css("border","3px solid #F00")
                else
                    $categoryError.text("")
                    $category.css("border","3px solid #CCC")
                if !validateCountry($country.val())
                    result  = false
                    $countryError.html("<p>Country entered is not valid</p>")
                    $country.css("border","3px solid #F00")
                else
                    $countryError.text("")
                    $country.css("border","3px solid #CCC")
                if !validateCity($city.val())
                    result  = false
                    $cityError.html("<p>City and/or State entered is not valid</p>")
                    $city.css("border","3px solid #F00")
                else
                    $cityError.text("")
                    $city.css("border","3px solid #CCC")
                return result

            event.preventDefault()
        )
        #######################################################################################
        # We hide elments that look unwieldy when the browsers are resized to smaller viewport.
        #######################################################################################
        jQuery(window).smartresize(() ->
            console.log(jQuery(window).width())
            width       = jQuery(window).width()
            if width < 790
                jQuery("#main-nav").hide()
                if loggedin
                    jQuery("#loggedin-account-nav").hide()
                else
                    jQuery("#non-loggedin-account-nav").hide()
                jQuery("location-indicator").hide()
                jQuery("footer").hide() 
            else
                jQuery("#main-nav").show()
                if loggedin
                    jQuery("#loggedin-account-nav").show()
                else
                    jQuery("#non-loggedin-account-nav").show()
                jQuery("location-indicator").show()
                jQuery("footer").show()
            currentRows = Math.floor( ($container.height -10) / rowHeight);
            if currentRows isnt rows 
                # set new column count
                rows = currentRows;
                #apply height to container manually, then trigger relayout
                $container.height(rows  * rowHeight).isotope('reLayout') if isotope
        ).smartresize()

        return false
    ) 
