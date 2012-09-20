 define(['jquery', 'backbone', 'app-mobile/views/categorylistview', 'app-mobile/views/appview'],
        (jQuery, Backbone, CategoryListView, AppView) ->
            "use strict"

            Router = Backbone.Router.extend(
                initialize  : (options) ->
                    console.log "init router"
                routes:
                    "category-list/:category": "categoryList" 	                              
                categoryList: (category) ->
                    console.log "categoryList"
                    @initNewView(new CategoryListView({"category": category}))
                initNewView: (page) ->
                    console.log "initView"
                    jQuery(page.el).attr('data-role', 'page')
                    page.render()
                    jQuery('body').append(jQuery(page.el))
                    @changePage(jQuery(page.el), "slide", false, true)
                changePage: (viewId, effect, direction, updateHash) ->
                    jQuery.mobile.changePage(viewId, { transition: effect, reverse:direction, changeHash: updateHash})
            )

            return Router
        )