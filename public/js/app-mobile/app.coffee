define(['collection.data', 'view.detail'],
    (Data, DetailView) ->
            "use-strict"
            
            init = () ->
                console.log "init"
                MeListing = window.MeListing || {};

                MeListing = {
                    Model : {}
                    View  : {}
                    Controller : {
                        renderDetail : (type, match, ui) ->
                            if !match
                                return
                            if !MeListing.View.detail
                                MeListing.View.detail = new DetailView(
                                    collection: MeListing.M.data, detailId : null, el : jQuery("#detail :jqmData(role='content')")
                                )
                            params = MeListing.Controller.router.getParams(match[1]);
                            if params
                                MeListing.View.detail.options.detailId = params.id;
                            
                            if MeListing.Model.data.isEmpty()
                                MeListing.Model.data.fetch()
                            else 
                                MeListing.View.detail.render()

                        pageInit : (type, match, ui, page) ->
                            console.log("This page ("+jQuery(page).jqmData("url")+") has been initialized")
                    }
                }
                MeListing.Controller.router = new jQuery.mobile.Router([
                    { "#localpage2(?:[?/](.*))?": {handler: "localpageA", events: "bc,c,i"} },
                    { "#localpage2(?:[?/](.*))?": {handler: "localpageB", events: "bs,s"} },
                    { "#localpage2(?:[?/](.*))?": {handler: "localpageC", events: "bh,h"} },
                    { "#index": { handler: (type) ->
                            console.log("Index has been ")
                    , events: "h,s" }
                    }
                ],{
                    localpageA: (type,match,ui) ->
                        params=router.getParams(match[1]);
                        console.log("localpage function A: "+type);
                        console.log(params);
                },{
                    localpageB: (type,match,ui) ->
                        params=router.getParams(match[1]);
                        console.log("localpage function B: "+type);
                        console.log(params);
                },{
                    localpageC: (type,match,ui) ->
                        params=router.getParams(match[1]);
                        console.log("localpage function C: "+type);
                        console.log(params);
                },{ 
                    defaultHandler: (type, ui, page) ->
                        console.log("Default handler called due to unknown route (" 
                            + type + ", " + ui + ", " + page + ")");
                    ,
                    defaultHandlerEvents: "s"
                })
            #To avoid flickering.    
            jQuery('body').show()

            return {"init" : init}
)