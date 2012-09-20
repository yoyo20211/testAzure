define(['jquery', 'backbone', 'app-mobile/models/postitem'],
        (jQuery, Backbone, PostItem) ->
            # Using ECMAScript 5 strict mode during development. By default r.js will ignore that.
            "use strict"

            PostItems = Backbone.Collection.extend({
                model: PostItem,
                urlRoot     : "/api/postitems/"
	            url         : () ->
	                return @urlRoot + @username + "/"
	            initialize  : (options) ->
	                @deferred = new jQuery.Deferred()
                parse: (response) ->
                    return response
            })
            return PostItems
)