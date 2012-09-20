#jade!../../../../category-list-view
define(['jquery', 'backbone', 'underscore', 'app-mobile/models/postitems'
    , 'app-mobile/routers/workspace', 'jade!app-mobile/templates/category-list-view'
    , 'app-mobile/views/postitemdetailview', 'app-mobile/views/mapitview'],
        (jQuery, Backbone, _, PostItems, Workspace, categoryListViewTemplate, PostItemDetailView, MapItView) ->
            "use strict"

            CategoryListView = Backbone.View.extend(
                el: jQuery("#category-list")
                routers: new Workspace()
                events:
                    "click .back": "previousPage"
                    "click .listview-postitem-detail": "postItemDetail"
                    "click .map-it": "mapIt"
                initialize: (options) ->
                    @category   = options.category;
                    @postitems  = new PostItems();
                    return @ 
                render: () ->
                    melisting.utils.loadPrompt("Loading items...")
                    @postitems.fetch({
                        success: (collection, response) ->
                            collection.deferred.resolve()
                        error: (collection, response) ->
                            console.log 'error fetch'
                            #TODO take care of the error.
                            throw new Error("PostItems fetch did not get the collection from API")
                    })
                    @postitems.deferred.done(() =>
                        console.log 'success fetch ' + @postitems.length
                        $el = jQuery(@el)
                        $el.empty()
                        $el.html(categoryListViewTemplate({postitems: @postitems}))
                        @routers.category()
                        $el.trigger("enhance")
                        $el.listview().trigger("create")
                    )
                    return @
                previousPage: () ->
                    @routers.root()
                postItemDetail: (event) ->
                    postItemId                    = jQuery(event.currentTarget).attr("id")
                    console.log postItemId
                    @postItemDetailView           = new PostItemDetailView({postitem: null})
                    @postItemDetailView.render()
                mapIt: (event) ->
                    console.log "map it"
                    @mapItView                    = new MapItView({})
                    @mapItView.render()

            )

            return CategoryListView
)