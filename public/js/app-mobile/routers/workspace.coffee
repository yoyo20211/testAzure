define(['jquery', 'backbone'],
        (jquery, Backbone) ->
            "use strict"

            Workspace = new jQuery.mobile.Router(
                "#index" : () ->
                    console.log("INDEX!")
                "#detail([?].*)?" : {
                    handler : null, events : "bs"
                },
                ".": {
                    handler : (type, match, ui, page) ->
                        console.log("This page has been initialized")
                    events: "i"
                }
            )
            return Workspace
)