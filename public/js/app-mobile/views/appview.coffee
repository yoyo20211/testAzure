define(['jquery', 'backbone', 'app-mobile/utils', 'app-mobile/routers/workspace', 'app-mobile/views/setlocationdialogview'
    , 'app-mobile/views/categorylistview', 'app-mobile/views/searchview', 'app-mobile/views/getappview'],
        (jQuery, Backbone, utils, Workspace, SetLocationDialog, CategoryListView, SearchView, GetAppView) ->
            # Using ECMAScript 5 strict mode during development. By default r.js will ignore that.
            "use strict"

            AppView = Backbone.View.extend(
                el                              : jQuery("body")
                city                            : ""
                state                           : ""
                country                         : ""
                latitude                        : 0.00 #should try to make it a meaningful default.
                longitude                       : 0.00
                $documentBody                   : jQuery("body")
                routers                         : new Workspace()
                initialize                      : () ->
                    console.log "initialize"
                    position = null
                    if navigator.geolocation
                        await navigator.geolocation.getCurrentPosition defer position, error
                        #TODO take care of the error.
                        console.log error if error
                        geonames                = {} 
                        geonames.baseURL        = "http://api.geonames.org/";
                        geonames.method         = "neighbourhoodJSON"
                        geonames.search         = (latitude, longitude) =>
                             jQuery.getJSON(geonames.baseURL + geonames.method + "?lat=" + latitude + "&lng=" + longitude + "&username=wpoosanguansit"
                                (response) =>
                                    console.log JSON.stringify(response)
                                    @city       = response?.neighbourhood?.adminName1    
                                    @state      = response?.neighbourhood?.adminCode1
                                    @country    = response?.neighbourhood?.countryCode
                             )
                        @latitude               = position.coords.latitude
                        @longitude              = position.coords.longitude
                        geonames.search(@latitude, @longitude)
                    else
                        #TODO take care of the location query not supported.
                        console.log "geolocation not supported"
                events:
                    "click a.set-location"      : "setLocation"
                    "click a.browse"            : "browse"
                    "click a.search"            : "search"
                    "click a.get-app"           : "getApp"
                    "click a.dashboard-icon"    : "getCategory"

                setLocation                     : (event) ->
                    @locationDialog             = new SetLocationDialog({appView: @})
                    @locationDialog.render()
                browse                          : (event) ->
                    @routers.root()
                search                          : (event) ->
                    @searchView           = new SearchView({})
                    @searchView.render()
                getApp                          : (event) ->
                    @getAppView           = new GetAppView({})
                    @getAppView.render()
                getCategory                     : (event) ->
                    console.log "getCategory"
                    category                    = jQuery(event.currentTarget).attr("id")
                    @categoryListView           = new CategoryListView({category: category})
                    @categoryListView.render()
                keyLoadResults                  : (event) ->
                    query                       = jQuery('#searchbox').val()

                    if query
                        sort                    = jQuery('#sortBy').val()
                        endpoint                = melisting.utils.queryConstructor(query, sort, 1)
                        location.hash           = endpoint
                    else
                        melisting.utils.loadPrompt('Please enter a search query to continue')

                    return false
            )

            return AppView
)