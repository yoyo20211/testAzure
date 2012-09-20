define(['jquery', 'backbone', 'underscore', 'app-mobile/utils', 'app-mobile/routers/workspace'],
        (jQuery, Backbone, _, utils, Workspace) ->
            "use strict"
            #################################################################################
            # State Abbreviation utility for use in form sign up address and posting.
            ################################################################################# 
            abbreviatedStateName = { "alabama": "AL", "alaska": "AK" , "arizona": "AZ"
                , "arkansas": "AR"      , "california": "CA"            , "colorado": "CO"
                , "connecticut": "CT"   , "delaware": "DE"              , "district of columbia": "DC"  
                , "florida": "FL"       , "georgia": "GA"               , "hawaii": "HI"        
                , "idaho": "ID"         , "illinois": "IL"              , "indiana": "IN"
                , "iowa": "IA"          , "kansas": "KS"                , "kentucky": "KY"              
                , "louisiana": "LA"     , "maine": "ME"                 , "maryland": "MD"      
                , "massachusetts": "MA" , "michigan": "MI"              , "minnesota": "MN"
                , "mississippi": "MS"   , "missouri": "MO"              , "montana": "MT"
                , "nebraska": "NE"      , "nevada": "NV"                , "new hamspire": "NH"     
                , "new jersey": "NJ"    , "new mexico": "NM"            , "new york": "NY"      
                , "north carolina": "NC", "north dakota": "ND"          , "ohio": "OH"
                , "oklahoma": "OK"      , "oregon": "OR"                , "pennsylvania": "PA"
                , "rhode island": "RI"  , "south carolina": "SC"        , "south dakota": "SD"  
                , "tennessee": "TN"     , "texas": "TX"                 , "utah": "UT"          
                , "vermont": "VT"       , "virginia": "VA"              , "washington": "WA"
                , "west virginia": "WV" , "wisconsin": "WI"             , "wyoming": "WY"
            }
            SetLocationDialog = Backbone.View.extend(
                initialize: (options) ->
                	appView 			= options.appView
                	isNumber        	= (value) ->
                        if undefined is value || null is value 
                            return false
                        if typeof value is "number" 
                            return true
                        return !isNaN(value - 0)
                    @routers 			= new Workspace()
                    $documentBody       = jQuery("body")
                    ISO2                = appView.country
                    $city               = jQuery("input#location-city-state-change-text-input") 
                    $country            = jQuery("input#location-country-change-text-input")
                    $saveButton         = jQuery("a#save-location")
                    $country.val("")
                    $city.val("")
                    $city.attr("disabled", true)
                    state 				= abbreviatedStateName[appView.state] or appView.state
                    if appView.city is appView.state
                    	$city.attr("placeholder", appView.city)
                    else
                    	$city.attr("placeholder", appView.city + ", " + state)
                    $country.attr("placeholder", appView.country)
                    $country.focus()
                    #TODO set the new current city, state and country when the user changes the location.
                    $documentBody.off("focus", "input#location-country-change-text-input").on("focus", "input#location-country-change-text-input", (event) =>
                        console.log "country focus city " + appView.city
                        $country.val("")
                        $city.val("")
                        $city.attr("disabled", true)
                        #TODO we need to set the current location info after change.
                        $country.autocomplete({
                            source       : (request, response) ->
                                #Check it is it is illegal number - http://www.w3schools.com/jsref/jsref_isnan.asp.
                                if isNumber(request.term)
                                    jQuery.getJSON "/api/getCitiesByZipcode/", {term:request.term,maxRows:12}, response
                                else
                                    jQuery.getJSON "/api/getCountries/",{term:request.term,maxRows:12},response 
                            , minLength   :  1
                            , select      :  (event, ui) ->
                                if ui.item.ISO2
                                    ISO2 = ui.item.ISO2
                                else
                                    #TODO set the input fields with appropriate values.
                                    longitude   = ui.item.longitude
                                    latitude    = ui.item.latitude
                                    $city.val(ui.item.address)
                                $city.removeAttr("disabled")
                            , autoFocus   : true
                            , autoSelect  : true 
                        })
                        $documentBody.off("blur", "input#location-country-change-text-input").on("blur", "input#location-country-change-text-input", (event) ->
                            autocomplete    = jQuery(this).data("autocomplete")
                            matcher         = new RegExp("^" + jQuery.ui.autocomplete.escapeRegex(jQuery(this).val()) + "$", "i");
                            myInput         = jQuery(this)
                            autocomplete.widget().children(".ui-menu-item").each(() ->
                                #Check if each autocomplete item is a case-insensitive match on the input
                                item = jQuery(this).data("item.autocomplete")
                                if matcher.test(item.label || item.value || item) 
                                    #There was a match, lets stop checking
                                    autocomplete.selectedItem = item
                                    return
                            )
                            #if there was a match trigger the select event on that match
                            #I would recommend matching the label to the input in the select event
                            if autocomplete.selectedItem
                                autocomplete._trigger("select", event, {
                                    item: autocomplete.selectedItem
                                })
                            #there was no match, clear the input
                            else
                                jQuery(this).val("")
                        )
                        $documentBody.off("keyup", "input#location-country-change-text-input").on("keyup", "input#location-country-change-text-input", (event) ->
                            keycode = event?.keyCode or event?.which
                            if keycode is 13
                                $city.focus()
                                event.preventDefault()
                        )
                        $documentBody.off("focus", "input#location-city-state-change-text-input").on("focus", "input#location-city-state-change-text-input", (event) =>
                            console.log "city inner first " + @appView.city
                            $city.val("")
                            $city.autocomplete({
                                source: (request, response)->
                                    jQuery.getJSON "/api/getCities/",{term:request.term,ISO2:ISO2,maxRows:12},response                            
                                , minLength   :   1
                                , select      :   (event, ui) =>
                                    #Assign new value for latlong, city, country displays 
                                    #and reset the map.
                                    @longitude               = ui.item.longitude
                                    @latitude                = ui.item.latitude
                                    #TODO we have to take care of the city and state not the same.
                                , autoFocus   : true
                                , autoSelect  : true                            
                            })
                        )
                        $documentBody.off("blur", "input#location-city-state-change-text-input").on("blur", "input#location-city-state-change-text-input", (event) ->
                            autocomplete    = jQuery(this).data("autocomplete");
                            matcher         = new RegExp("^" + jQuery.ui.autocomplete.escapeRegex(jQuery(this).val()) + "$", "i");
                            myInput         = jQuery(this)
                            autocomplete.widget().children(".ui-menu-item").each(() ->
                                #Check if each autocomplete item is a case-insensitive match on the input
                                item = jQuery(this).data("item.autocomplete")
                                if matcher.test(item.label || item.value || item) 
                                    #There was a match, lets stop checking
                                    autocomplete.selectedItem = item
                                    return
                            )
                            #if there was a match trigger the select event on that match
                            #I would recommend matching the label to the input in the select event
                            if autocomplete.selectedItem
                                autocomplete._trigger("select", event, {
                                    item: autocomplete.selectedItem
                                })
                            #there was no match, clear the input
                            else
                                jQuery(this).val("")
                        )
                        $documentBody.off("keyup", "input#location-city-state-change-text-input").on("keyup", "input#location-city-state-change-text-input", (event) ->
                            keycode = event?.keyCode or event?.which
                            if keycode is 13
                                #TODO investigate why focus does not work.
                                jQuery(this).blur()
                                $saveButton.focus()
                                event.preventDefault()
                        )
                        event.preventDefault()
                    )
                    $documentBody.off("click", "a#save-location-button").on("click", "a#save-location-button", (event) =>
                        console.log "click save"
                        window.history.back()
                    ) 
                    $documentBody.off("click", "a#cancel-location-button").on("click", "a#cancel-location-button", (event) =>
                        console.log "click close"
                        utils.historySwitch("prev")
                    )
                #BUG? Event binding is not working.    
                events:
                    "click a#save-location-button"  : "saveLocation"
                    "click #cancel-location-button": "closeLocation"
                render                              : () ->
                    console.log "render"
                    @routers.showLocationDialog()
                saveLocation                        : (event) ->
                	console.log "save location"
                	#utils.historySwitch("prev")
                closeLocation                       : (event) ->
                	console.log "close location"
                	utils.historySwitch("prev")
            )

            return SetLocationDialog
)