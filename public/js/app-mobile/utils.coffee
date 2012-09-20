define(['jquery'],
        (jQuery) ->
            #Using ECMAScript 5 strict mode during development. By default r.js will ignore that.
            #"use strict";
            utils = {}


            # summary:
            #            Manage passing search queries to the necessary handlers and the UI
            #            changes that are required based on query-type.
            # searchType: String
            #            The type of search to conduct. Supports 'search' for results or
            #            'photo' for individual photo entries
            # context: String
            #            The context (view) for which the requests are being made
            # query: String
            #            The query-string to lookup. For search this is a keyword or set of
            #            keywords in string form, for photos this refers to the photo ID
            # sort: String
            #            How the results returned should be sorted. All of the Flickr API sort
            #            modes are supported here
            # page: Integer
            #            The pagination index currently being queried. e.g 2 refers to page 2. 

            utils.dfdQuery = (searchType, context, query, sort, page) ->

                if !query==undefined || query == ""
                    entries = null
                    page = page or 1

                    utils.loadPrompt('Query category...')

                    jQuery.when(utils.fetchResults(searchType, query, sort, page))
                            .then(jQuery.proxy((response) ->
                                context.setView(searchType)

                                # The application can handle routes that come in
                                # through a bookmarked URL differently if needed
                                # simply check against workspace.bookmarkMode
                                # e.g if(!melisting.routers.workspace.bookmarkMode) etc.

                                if searchType == 'search' || searchType == undefined
                                    entries = response
                                    melisting.routers.workspace.q = query;
                                    melisting.routers.workspace.p = page;
                                    melisting.routers.workspace.s = sort;

                                    jQuery('.search-meta p').html('Page: ' + response.length + ' / ' + response.length);
                                    
                                    context.resultView.collection.reset(entries)

                                    #switch to search results view
                                    utils.changePage("#search", "slide", false, false )

                                    # update title
                                    utils.switchTitle(query + ' (Page ' + page + ' of ' + response.postitems.total + ')')
                                else
                                    entries = response.postitems
                                    context.collection.reset(entries)

                                    # switch to the individual photo viewer
                                    utils.changePage("#postitem", "slide", false, false)
                    , context))
                else
                    utils.loadPrompt('Please enter a valid search query.')
                
            # summary:
            #            A convenience method for accessing jQuerymobile.changePage(), included
            #            in case any other actions are required in the same step.
            # changeTo: String
            #            Absolute or relative URL. In this app references to '#index', '#search' etc.
            # effect: String
            #            One of the supported jQuery mobile transition effects
            # direction: Boolean
            #            Decides the direction the transition will run when showing the page
            # updateHash: Boolean
            #            Decides if the hash in the location bar should be updated

            utils.changePage = (viewID, effect, direction, updateHash) ->
                jQuery.mobile.changePage( viewID, {transition: effect, reverse:direction, changeHash: updateHash})


            # summary:
            #            Query for search results or individual photos from the Flickr API
            # searchType: String
            #            The type of search to conduct. Supports 'search' for results or
            #            'photo' for individual photo entries
            # query: String
            #            The query-string to lookup. For search this is a keyword or set of
            #            keywords in string form, for photos this refers to the photo ID
            # sort: String
            #            How the results returned should be sorted. All of the Flickr API sort
            #            modes are supported here
            # page: Integer
            #            The pagination index currently being queried. e.g 2 refers to page 2. 
            # returns:
            #            A promise for the ajax call to be completed

            utils.fetchResults = (searchType, query, sort, page) ->
                serviceUrl = "/api/postitems/:username/"


                if searchType == 'search' || searchType == undefined
                    quantity = jQuery('#slider').val() || melisting.defaults.resultsPerPage
                else if searchType == 'postitem'
                    serviceUrl = "/api/postitems/:username/"

                return jQuery.ajax(serviceUrl, { dataType: "json" })

            # summary:
            #            Manage the URL construction and navigation for pagination
            #            (e.g next/prev)
            #
            # state: String
            #            The direction in which to navigate (either 'next' or 'prev')

            utils.historySwitch = (state) ->
                sortQuery = hashQuery = ""
                pageQuery = increment = 0

                hashQuery = melisting.routers.workspace.q or ""
                pageQuery = melisting.routers.workspace.p or 1
                sortQuery = melisting.routers.workspace.s or "relevance"

                pageQuery = parseInt(pageQuery)
                if state == 'next' 
                	pageQuery += 1 
                else 
                	pageQuery -= 1

                if pageQuery > 1 
                	utils.changePage( "/", "slide" ) 
                else 
                	location.hash = utils.queryConstructor(hashQuery, sortQuery, pageQuery)

            # summary:
            #            Display a custom notification using the loader extracted from jQuery mobile.
            #            The only reason this is here is for further customization.
            #
            # message: String
            #            The message to display in the notification dialog

            utils.loadPrompt = (message) ->
                message = message or ""

                jQuery( "<div class='ui-loader ui-overlay-shadow ui-body-e ui-corner-all'><h1>" + message + "</h1></div>" )
                .css( { "display": "block", "opacity": 0.96, "top": jQuery( window ).scrollTop() + 100 } )
                .appendTo( jQuery.mobile.pageContainer )
                .delay( 800 )
                .fadeOut( 400, () ->
                    jQuery( this ).remove()
                )


            #summary:
            #            Adjust the title of the current view
            #
            # title: String
            #            The title to update the view with
            utils.switchTitle = (title) ->
                jQuery('.ui-title').text(title || "")


            # summary:
            #            Construct a search query for processing
            #
            # query: String
            #            The query-string to lookup. For search this is a keyword or set of
            #            keywords in string form, for photos this refers to the photo ID
            # sortType: String
            #            How the results returned should be sorted. All of the Flickr API sort
            #            modes are supported here
            # page: Integer
            #            The pagination index currently being queried. e.g 2 refers to page 2

            utils.queryConstructor = (query, sortType, page) ->
                return 'search/' + query + '/s' + sortType + '/p' + page


            # summary:
            #            Toggle whether the navigation is displayed or hidden
            #
            # toggleState: Boolean
            #            A boolean that decides whether the navigation should be toggled on or off.

            utils.toggleNavigation  = (toggleState) ->
                melisting.ui.nextOption.toggle(toggleState)
                melisting.ui.prevOption.toggle(toggleState)

            utils.activePage        = () ->
                    jQuery("ui-page-active")
            
            utils.reapplyStyles     = (el) ->
                  el.find('ul[data-role]').listview();
                  el.find('div[data-role="fieldcontain"]').fieldcontain();
                  el.find('button[data-role="button"]').button();
                  el.find('input,textarea').textinput();
                  el.page()
               
            utils.redirectTo        = (page) ->
                  jQuery.mobile.changePage page
             
            utils.goBack            = ()->
                  jQuery.historyBack()
            
            return utils
        )