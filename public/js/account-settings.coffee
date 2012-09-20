#################################################################################
# For edit-listing BackBone.js and Knockout.js, respectively, are use to 
# structure the page and bind those dom elements in the page to values in this file.
#
# i.e. BackBone.js views represent the pages and their interaction.
# MenuView -> menu
# while Knockout.js represent the state of the view and data with model variable.
# 
# @dispatcher.trigger("menuView:showProfile") calls the code in the event
# dispatcher:
# controller.dispatcher.off("menuView:showProfile").on("menuView:showProfile", () ->
#                controller.showProfile()
# ) 
# which calls:
#           @accountSettings.currentView("profile")
#                @profileView.render()
#                return @
# which, in turn, executes:
#           render: =>
#                if not @hasInitializedTabs
#                    @initTabs()
#                    @hasInitializedTabs         = true
#                return @
#            initTabs: () ->
#                @profileViewTabs    = jQuery("div#account-settings-main-content-profile-detail-tabs").tabs({
#                    load: (event, ui) ->
#                        event.preventDefault()
#                    cache: true,
#                    collapsible: false,
#                    select: (event, ui) ->
#                        index               = ui.index
#                })
#################################################################################

head.ready(() ->
    #jQuery.noConflict()
    #Set the {{ }} to be the template interpolate string.
    _.templateSettings = {
        interpolate : /\{\{([\s\S]+?)\}\}/g
    }
    client = {
        # Hash of preloaded templates for the app
        templates: {}
        # Recursively pre-load all the templates for the app.
        # This implementation should be changed in a production environment. All the template files should be
        # concatenated in a single file.
        loadTemplates: (names, callback) ->
            that = this
            loadTemplate = (index) ->
                name = names[index]
                console.log('Loading template: ' + name)
                jQuery.get('/pages/' + name + '.html', (data) ->
                    that.templates[name] = data
                    index++
                    if index < names.length
                        loadTemplate(index)
                    else
                        callback() if callback
                )
            loadTemplate(0)
        # Get template by name from hash of preloaded templates
        get: (name) ->
            return this.templates[name]
    }
    
    jQuery(window).load(() -> jQuery ->
        PERSONAL_INFO_INDEX = 0
        COMMUNICATION_PAYMENT_INDEX = 1 
        loggedin            = jQuery("input#loggedin").val() is "true"
        string              = jQuery("input#token").val()
        token               = JSON.parse(string) if string isnt "" and string isnt null
        if !token
            cookie          = jQuery.cookies.get('logintoken')
            token           = JSON.parse(cookie) if cookie
        username            = token?.username
        $alert              = jQuery("div#alert")
        $notice             = jQuery("div#notice") 
        $documentBody       = jQuery("body")
        $mainContent        = jQuery("div.account-settings-main-content")
        $profileMenu        = jQuery("div#account-settings-menu-profile")
        $postitemsMenu      = jQuery("div#account-settings-menu-postitems")
        $profileView        = jQuery("div#account-settings-main-content-profile")
        $postitemsView      = jQuery("div#account-settings-main-content-postitems")

        postitemMap         = {} # hashmap that keeps track of all the postitems passed from the server.
        user                = {} # user object.
        wishlist            = {}
        ################################################################################
        # Check if browser supports cookies.  If not, notify the user.
        ################################################################################
        if !jQuery.cookies.test()
            message         = """<p>The browser does not allow the application to save cookies.
                                    Please enable cookies in your browser to use full functinality of the site.
                                </p>"""
            $alert.html(message).fadeIn(1500).delay(4500).fadeOut(1500)
        ##
        # We setup the login strip.
        ##
        jQuery("#loggedin-account-nav").show()
        jQuery("li#username").text(token.username)
        $documentBody.off("click", "a#signout").on("click", "a#signout", (event) ->
                rpc.request({
                    url: "../../../api/logout/",
                    method: "POST",
                    data: { "username": username }
                },(response) ->
                    result = JSON.parse(response.data)
                    if (result?.response is "success")
                        jQuery.cookies.del("logintoken")
                        jQuery.cookies.del("username")
                        jQuery("input#loggedin").val("false")
                        jQuery("input#token").val("")
                        # Redirecting to the main page.
                        window.location = "/"
                    else
                        $alert.html("<p>" + result.message + "</p>").fadeIn(1500).delay(3500).fadeOut(1500)
                , (error) ->
                    message         = """<p>There is an error occurred while we try to logout of your account.
                                            Sorry for the inconvenience.  If the problem persists,
                                            please contact admin@melisting.com for further assistance.</p>"""
                    $alert.html("<p>" + message + "</p>").fadeIn(1500).delay(3500).fadeOut(1500)
                )
                event.preventDefault()
        )

        ################################################################################
        # Set up the user profile and postitems display
        # TODO There is a bug photos, location and  exchangeOptions info are lost
        # when alluserinfo query returns the result.
        ################################################################################
        await jQuery.getJSON "/api/alluserinfo/{0}/".format(username), defer result
        # TODO take care of the error
        if result.response is "success"
            info                = result.context
            user                = info.user
            postitemMap         = info.postitemMap
            wishlist            = info.wishlist

            console.log "++++++++++++++++++++++++ " + JSON.stringify(_.values(postitemMap))
        else
            console.log "error ------------------------- " + result.response
            return

        postitemArray           = _.values(postitemMap) 
        wishlistArray           = _.values(wishlist) 

        accountSettings         = {
            user: user
            currentView: ko.observable("profile")
            postitems: postitemArray
            wishlist: wishlistArray
            numberOfPostItems: ko.observable(postitemArray.length)
            numberOfWishList: ko.observable(wishlistArray.length)
            items: ko.observableArray([])
            username: ko.observableArray()
            hashedPassword: ko.observable()
            email: ko.observable()
            address: ko.observable()
            updateProfile: ko.observable()
            cancelUpdateProfile: ko.observable()
        }

        ko.applyBindings(accountSettings)

        #################################################################################
        # Models for backbone - client side.
        ################################################################################# 

        

        #################################################################################
        # Views - MenuView.
        ################################################################################# 

        class MenuView extends Backbone.View
            el          : jQuery('account-settings-menu')
            initialize  : (@options) ->
                @dispatcher         = @options.event
                console.log "menu init"
            events      :
                "click div#account-settings-menu-profile a": "showProfile"
                "click div#account-settings-menu-postitems a": "showPostItems"
                "click div#account-settings-menu-wishlist a": "showWishList"
            render: =>
                @showProfile()
                return @
            showProfile: () ->
                @dispatcher.trigger("menuView:showProfile")
            showPostItems: () ->
                @dispatcher.trigger("menuView:showPostItems")
            showWishList: () ->
                @dispatcher.trigger("menuView:showWishList")

        #################################################################################
        # Views - ProfileView.
        ################################################################################# 

        class ProfileView extends Backbone.View
            el          : jQuery('div#account-settings-main-content-profile')
            initialize  : (@options) ->
                console.log "ProfileView init"
                @dispatcher         = @options.event
                @previousProfile     = @options.user
                @user               = ko.mapping.fromJS(@options.user)
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

                @user.username.extend({required: true, minLength: 5, notEqual: "click to edit"})
                @user.hashedPassword.extend({required: true, minLength: 6, notEqual: "click to edit"})
                @user.email.extend({email: true, required: true})
                @user.address.neighborhood.extend({required: true, notEqual: "click to edit"})
                @user.errors          = ko.validation.group(@user)

                #################################################################################
                # Setup the user model functions.
                #################################################################################
                @user.updateProfile         = (user, event) =>
                    console.log "updateProfile" 
                    user.username("ddd")

                @user.cancelUpdateProfile   = (user, event) =>
                    ##
                    # Hack - No clue why we have to rebind here.
                    ##
                    ko.cleanNode(jQuery("#personal-info")[0])
                    profile                 = ko.mapping.fromJS(@previousProfile, user) 
                    ko.applyBindings(profile, jQuery("#personal-info")[0])
                    if @map and @marker
                        @map.setView(@previousProfile.location, 8)
                        @marker.setLatLng(@previousProfile.location)
                        @marker.update() 

                ko.applyBindings(@user, jQuery("#personal-info")[0])

                @hasInitializedTabs = false
            events      :
                null
            render: =>
                if not @hasInitializedTabs
                    @initTabs()
                    @hasInitializedTabs         = true
                return @
            initTabs: () =>
                self = @
                @profileViewTabs    = jQuery("div#account-settings-main-content-profile-detail-tabs").tabs({
                    create: (event, ui) ->
                        ##
                        # Setup the postiem detail tab section.
                        ##
                        setTimeout(() -> 
                                self.setupMap()
                            , 3000)
                        event.preventDefault()
                    load: (event, ui) ->
                        event.preventDefault()
                    cache: true,
                    collapsible: false,
                    select: (event, ui) ->
                        index       = ui.index
                        switch index
                            when PERSONAL_INFO_INDEX
                                console.log "PERSONAL_INFO_INDEX"
                                #$documentBody.trigger("refreshMap")
                                # A hack to refresh the leaflet map - 
                                # http://stackoverflow.com/questions/10762984/leaflet-map-not-displayed-properly-inside-tabbed-panel
                                L.Util.requestAnimFrame(self.map.invalidateSize,self.map,!1,self.map._container) if self.map
                            when COMMUNICATION_PAYMENT_INDEX
                                console.log "COMMUNICATION_PAYMENT_INDEX"
                            else 
                                console.log "INDEX ERROR"
                })
            #################################################################################
            # Setup the profile map.
            #################################################################################
            setupMap: () =>
                self        = @
                location    = self.user.location()
                @map         = L.map("profile-info-map", {doubleClickZoom: false}).setView(location, 8)
                L.tileLayer("http://{s}.tile.cloudmade.com/552ed20c2dcf46d49a048d782d8b37e6/997/256/{z}/{x}/{y}.png", {
                    attribution: 'Map data &copy; <a href="http://openstreetmap.org">OpenStreetMap</a> contributors, <a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>, Imagery © <a href="http://cloudmade.com">CloudMade</a>',
                    maxZoom: 18
                }).addTo(@map)
                @marker      = L.marker(location, {draggable: true, clickable: true}).addTo(@map)
                @popup       = L.popup()
                showLocation    = (event) =>
                    target      = null
                    if event.hasOwnProperty("target")
                        target  = event.target
                    latlng      = event.latlng or target.getLatLng()
                    latitude    = latlng.lat
                    longitude   = latlng.lng
                    jQuery.ajax({
                        url: "http://open.mapquestapi.com/geocoding/v1/reverse?lat={0}&lng={1}".format(latitude, longitude)
                        , dataType: 'jsonp'
                        , success:(response) =>
                            location        = response.results[0].locations[0] if response.results[0]
                            if location
                                neighborhood    = location.street or "Not Available"
                                city            = location.adminArea5 or ""
                                state           = location.adminArea3 or ""
                                country         = location.adminArea1 or ""
                                if city and country
                                    @map.closePopup()
                                    @popup
                                        .setLatLng(latlng)
                                        .setContent("The location clicked is {0}, {1}".format(city, country))
                                        .openOn(@map)
                                    setTimeout(() =>
                                        @map.closePopup()
                                    , 10000)
                                else
                                    console.log "error"
                            else
                                console.log "error"
                        , error:(error) ->
                            # TODO take care of the error.
                            alert("Error")
                    })
                changeLocation  = (event) =>
                    target      = null
                    if event.hasOwnProperty("target")
                        target  = event.target
                    latlng      = event.latlng or target.getLatLng()
                    latitude    = latlng.lat
                    longitude   = latlng.lng
                    jQuery.ajax({
                        url: "http://open.mapquestapi.com/geocoding/v1/reverse?lat={0}&lng={1}".format(latitude, longitude)
                        , dataType: 'jsonp'
                        , success:(response) =>
                            location            = response.results[0].locations[0] if response.results[0]
                            if location
                                neighborhood    = location.street or "Not Available"
                                city            = location.adminArea5 or ""
                                state           = location.adminArea3 or city
                                country         = location.adminArea1 or ""
                                if city and country
                                    @map.closePopup()
                                    @popup
                                        .setLatLng(latlng)
                                        .setContent("You have updated your location to {0}, {1}".format(city, country))
                                        .openOn(@map)
                                    setTimeout(() =>
                                        @map.closePopup()
                                    , 10000)
                                    @marker.setLatLng(latlng)
                                    self.user.location([latitude, longitude])
                                    self.user.address.city(city)
                                    self.user.address.state(state)
                                    self.user.address.country(country)
                                    self.user.address.neighborhood(neighborhood)
                                else
                                    console.log "error"
                            else
                                console.log "error"
                        , error:(error) ->
                            # TODO take care of the error.
                            alert("Error")
                    }) 
                @marker.on("dragend", changeLocation)
                @marker.on("click", showLocation)
                @map.on("click", showLocation)
                @map.on("dblclick", changeLocation)
        #################################################################################
        # Views - PostItemsView.
        # update the items through @model.items 
        # v = _.reject(a, function(obj){console.log(obj.test); return obj.test === ooo.test});
        ################################################################################# 

        class PostItemsView extends Backbone.View
            el          : jQuery('div#account-settings-main-content-postitems')
            initialize  : (@options) ->
                console.log "PostItemsView init"
                @dispatcher         = @options.event
                @postitems          = @options.postitems
                @hasInitializedTabs = false
            events      :
                null
            render: () =>
                if not @hasInitializedTabs
                    @initTabs()
                    @initGrid()
                    @hasInitializedTabs         = true
                return @
            initTabs: () ->
                @profileViewTabs    = jQuery("div#account-settings-main-content-postitems-detail-tabs").tabs({
                    load: (event, ui) ->
                        event.preventDefault()
                    cache: true,
                    collapsible: false,
                    select: (event, ui) ->
                        index               = ui.index
                })
            initGrid: () ->
                self            = @
                selectedIds     = {}
                self.grid       = jQuery("div#grid")
                self.grid.kendoGrid({
                    dataSource: {
                        data: postitemArray,
                        schema: {
                            model: {
                                uid: "_id",
                                fields: {
                                    select: {
                                        type: "string",
                                        editable: false
                                    },
                                    _id: {
                                        type: "string"
                                    }
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
                        },
                        pageSize: 8
                    },
                    height: "90%",
                    sortable: true,
                    resizable: true,
                    pageable: true,
                    selectable: "multiple",
                    toolbar: [
                        {
                            text: "Post New Item",
                            className: "k-grid-postitem-post",
                            imageClass: "k-add"
                        },
                        {   
                            text: "Repost",
                            className: "k-grid-postitem-repost",
                            imageClass: "k-add"
                        },
                        {
                            text: "Delete",
                            className: "k-grid-postitem-delete",
                            imageClass: "k-delete"
                        }
                    ],
                    columns: [
                        {
                            field: "select",
                            title: "&nbsp;",
                            template: "<input id=#=_id# class='postitem-checkbox' type='checkbox' />",
                            sortable: false,
                            width: 66
                        },
                        {
                            field: "_id",
                            title: "ID",
                            hidden: true
                        },
                        {
                            field: "title",
                            title: "Title"
                            width: 150
                        },
                        {
                            field: "itemDescription",
                            title: "Description",
                            width: 450
                        },
                        {
                            field: "category",
                            title: "Category"
                            width: 100
                        },
                        {
                            field: "price",
                            title: "Price"
                            width: 60
                        },
                        {
                            field: "userRating",
                            title: "Lister Rating",
                            width: 126
                        },
                        {
                            field: "createdDate",
                            title: "Date",
                            template: "#= kendo.toString(createdDate,'MM/dd/yyyy') #"
                            width: 100
                        },
                        {
                            command: {  
                                text: "Edit" 
                                , click: (event) ->
                                    console.log "edit"
                                    postitem = @dataItem(jQuery(event.currentTarget).closest("tr"))
                                    setUpGridEditPostItem(postitem)
                                    event.preventDefault() 
                            }
                            , title: ""
                            , width: 98
                        },
                        {
                            command: {  
                                text: "Comments" 
                                , click: (event) ->
                                        postitem = @dataItem(jQuery(event.currentTarget).closest("tr"))
                                        setUpGridShowComments(postitem)
                                        event.preventDefault() 
                            }
                            , title: ""
                            , width: 120
                        }
                    ],
                    dataBound: () ->
                        grid = @           
                        grid.table.find("tr").find("td:first input")        
                            .change((event) ->                  
                                checkbox = jQuery(this);
                                checkbox.attr("checked", checkbox.is(":checked"))    
                                selected = grid.table.find("tr").find("td:first input:checked").closest("tr");
                                
                                grid.clearSelection()

                                ids = selectedIds[grid.dataSource.page()] = []
                                #console.log grid.dataItem(grid.tbody.find(">tr:first"))
                                if selected.length
                                    grid.select(selected)
                                    selected.each((idx, item) ->
                                        ids.push(jQuery(item).data("uid"))
                                    )                  
                            )
                            .end()
                            .mousedown((event) ->
                                event.stopPropagation()
                            )
                            
                        selected = jQuery()
                        ids = selectedIds[grid.dataSource.page()] || [];
                        len = ids.length
                        for idx in [0..len]
                            selected = selected.add(grid.table.find("tr[data-uid=" + ids[idx] + "]"))
                    
                        selected
                            .find("td:first input")
                            .attr("checked", true)
                            .trigger("change")

                        $grid = self.grid.data("kendoGrid");
                        $grid.thead.find("th:first")
                            .append(jQuery('<input class="select-all" type="checkbox"/>'))
                            .delegate(".select-all", "click", () ->
                                checkbox = jQuery(this)         
                                $grid.table.find("tr")
                                    .find("td:first input")
                                    .attr("checked", checkbox.is(":checked"))
                                    .trigger("change")
                        )
                        
                        ## TODO complete and hook up the functions for add repost and delete with the ui updates.
                        $documentBody.off("click", ".k-grid-postitem-post").on("click", ".k-grid-postitem-post", () ->
                            console.log "post"
                            grid            = $grid
                        )
                        $documentBody.off("click", ".k-grid-postitem-repost").on("click", ".k-grid-postitem-repost", () ->
                            console.log "repost"
                            grid            = $grid
                            grid.refresh()
                            grid.select().each(() ->
                                postitem    = grid.dataItem(jQuery(this))
                                console.log postitem
                            )
                        )
                        $documentBody.off("click", ".k-grid-postitem-delete").on("click", ".k-grid-postitem-delete", () ->
                            console.log "repost"
                            grid            = $grid
                            grid.refresh()
                            grid.select().each(() ->
                                postitem    = grid.dataItem(jQuery(this))
                                console.log postitem
                            )
                        )
                })

        ##
        # Utility functions for PostItemView - showing detail edit view.
        # We append the postitem to the body for the popup page to extract.
        ##
        $detailWindow           = jQuery("div#account-settings-main-content-postitems-detail-window")
        setUpGridEditPostItem   = (postitem) ->
            if not $detailWindow.data("kendoWindow")
                jQuery("body").append("<div id='current-postitem' style='display:none;'>" + JSON.stringify(postitem) + "</div>") 
                $detailWindow.kendoWindow(
                    actions: ["Close", "Maximize"],
                    draggable: false,
                    height: "80%",
                    modal: true,
                    resizable: false,
                    width: "80%",
                    content: "/pages/edit-listing/"
                    close: (event) ->
                        jQuery("div#current-postitem").remove()
                )
            else
                jQuery("body").append("<div id='current-postitem' style='display:none;'>" + JSON.stringify(postitem) + "</div>")
                $detailWindow.data("kendoWindow")
                    .content("Loading...")
                    .refresh("/pages/edit-listing/")
                    .open()
            jQuery("div#account-settings-main-content-postitems-detail-window").closest(".k-window").css({
                top: "10%",
                left: "10%"
            })
        setUpGridShowComments = (postitem) ->
            console.log "show comments"

        #################################################################################
        # Views - WishListView.
        ################################################################################# 

        class WishListView extends Backbone.View
            el          : jQuery('div#account-settings-main-content-wishlist')
            initialize  : (@options) ->
                console.log "WishListView init"
                @dispatcher         = @options.event
            events      :
                null
            render: =>
                return @

        #################################################################################
        # Controller
        ################################################################################# 

        ##
        # The dispatcher has to be setup before the views are init.
        # Else the binding does not occur.
        ##
        class Controller
            constructor: (options) ->
                console.log "controller"
                @dispatcher         = options.event
                setupDispatcher(@)
                @accountSettings    = options.accountSettings
                @menuView           = new MenuView({event: @dispatcher})
                @profileView        = new ProfileView({event: @dispatcher, user: @accountSettings.user})
                @postitemsView      = new PostItemsView({event: @dispatcher, postitems: @accountSettings.postitems})
                @wishlistView       = new WishListView({event: @dispatcher, wishlist: @accountSettings.wishlist})
                @showProfile()
            showProfile: () =>
                @accountSettings.currentView("profile")
                @profileView.render()
                return @
            showPostItems: () =>
                @accountSettings.currentView("postitems")
                console.log "@accountSettings.postitems " + @accountSettings.postitems.length
                @postitemsView.render()
                return @
            showWishList: () =>
                @accountSettings.currentView("wishlist")
                @wishlistView.render()
                return @
        setupDispatcher = (controller) ->
            controller.dispatcher.off("menuView:showProfile").on("menuView:showProfile", () ->
                controller.showProfile()
            )
            controller.dispatcher.off("menuView:showPostItems").on("menuView:showPostItems", () ->
                controller.showPostItems()
            )
            controller.dispatcher.off("menuView:showWishList").on("menuView:showWishList", () ->
                controller.showWishList()
            )

        #################################################################################
        # Router.
        ################################################################################# 

        class AppRouter extends Backbone.Router
            initialize  : (options) ->
                null
            routes      : {
                "/profile/:username"    : "showProfile",
                "/postitems/username"   : "showPostItems",
                "/postitems/:id"        : "showPostItemDetail"
                "/wishlist/:username"   : "showWishList"
            }

            showProfile: (username) ->
                console.log 'showProfile'
            showPostItems: (username) ->
                console.log 'showPostItemInfoList'
            showPostItemDetail: (id) ->
                console.log 'showPostItemDetail'
            showWishList: (username) ->
                console.log 'showWishList'

        #################################################################################
        # Custom event aggregator reference - 
        # http://lostechies.com/derickbailey/2011/07/19/references-routing-and-the-event-aggregator-coordinating-views-in-backbone-js/
        ################################################################################# 
        dispatcher      = _.extend({}, Backbone.Events)    
        controller  = new Controller({event: dispatcher, accountSettings: accountSettings})
        router      = new AppRouter({controller: controller})  
          
        Backbone.history.start()
    )
)