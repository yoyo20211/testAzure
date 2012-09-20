define(['jquery', 'backbone', 'underscore', 'app-mobile/routers/workspace'
    , 'jade!app-mobile/templates/map-it-view'],
        (jQuery, Backbone, _, Workspace, mapItViewTemplate) ->
            "use strict"

            MapItView = Backbone.View.extend(
                el: jQuery("#map-it")
                routers: new Workspace()
                events:
                    "click .back": "previousPage"
                initialize: (options) ->
                    console.log "init"
                render: () ->
                    console.log "get map it"
                    $el = jQuery(@el)
                    alert(mapItViewTemplate({}))
                    $el.html(mapItViewTemplate({})).page()
                    @routers.mapIt()
                    return @
                previousPage: () ->
                    @routers.category()
            )

            return MapItView
)