define(['jquery', 'backbone', 'underscore', 'app-mobile/models/postitems'
    , 'app-mobile/routers/workspace', 'jade!app-mobile/templates/postitem-detail-view'],
        (jQuery, Backbone, _, PostItems, Workspace, postItemDetailViewTemplate) ->
            "use strict"

            PostItemDetailView = Backbone.View.extend(
                el: jQuery("#postitem-detail")
                routers: new Workspace()
                events:
                    "click .back": "previousPage"
                initialize: (options) ->
                    @postItem   = options.postitem;
                    return @ 
                render: () ->
                    melisting.utils.loadPrompt("Loading item...")
                    $el = jQuery(@el)
                    $el.html(postItemDetailViewTemplate({postitem: @postItem}))
                    @routers.postItemDetail()
                    return @
                previousPage: () ->
                    @routers.category()
            )

            return PostItemDetailView
)