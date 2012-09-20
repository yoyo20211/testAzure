define(['jquery', 'backbone', 'underscore', 'app-mobile/models/postitems'
    , 'app-mobile/routers/workspace', 'jade!app-mobile/templates/get-app-view'],
        (jQuery, Backbone, _, PostItems, Workspace, getAppViewTemplate) ->
            "use strict"

            GetAppView = Backbone.View.extend(
                el: jQuery("#get-app")
                routers: new Workspace()
                events:
                    "click .back": "previousPage"
                initialize: (options) ->
                    console.log "init"
                render: () ->
                    console.log "get app view"
                    $el = jQuery(@el)
                    $el.html(getAppViewTemplate({}))
                    @routers.getApp()
                    return @
                previousPage: () ->
                    @routers.root()
            )

            return GetAppView
)