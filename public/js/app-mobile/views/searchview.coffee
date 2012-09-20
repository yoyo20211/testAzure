define(['jquery', 'backbone', 'underscore', 'app-mobile/models/postitems'
    , 'app-mobile/routers/workspace', 'jade!app-mobile/templates/search-view'],
        (jQuery, Backbone, _, PostItems, Workspace, searchViewTemplate) ->
            "use strict"

            GetAppView = Backbone.View.extend(
                el: jQuery("#search")
                routers: new Workspace()
                events:
                    "click .back": "previousPage"
                initialize: (options) ->

                render: () ->
                    $el = jQuery(@el)
                    $el.html(searchViewTemplate({}))
                    @routers.search()
                    return @
                previousPage: () ->
                    @routers.root()
            )

            return GetAppView
)