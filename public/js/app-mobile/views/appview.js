// Generated by IcedCoffeeScript 1.3.1b
(function() {
  var iced, __iced_k, __iced_k_noop;

  iced = require('iced-coffee-script').iced;
  __iced_k = __iced_k_noop = function() {};

  define(['jquery', 'backbone', 'app-mobile/utils', 'app-mobile/routers/workspace', 'app-mobile/views/setlocationdialogview', 'app-mobile/views/categorylistview', 'app-mobile/views/searchview', 'app-mobile/views/getappview'], function(jQuery, Backbone, utils, Workspace, SetLocationDialog, CategoryListView, SearchView, GetAppView) {
    "use strict";

    var AppView;
    AppView = Backbone.View.extend({
      el: jQuery("body"),
      city: "",
      state: "",
      country: "",
      latitude: 0.00,
      longitude: 0.00,
      $documentBody: jQuery("body"),
      routers: new Workspace(),
      initialize: function() {
        var error, geonames, position, ___iced_passed_deferral, __iced_deferrals, __iced_k,
          _this = this;
        __iced_k = __iced_k_noop;
        ___iced_passed_deferral = iced.findDeferral(arguments);
        console.log("initialize");
        position = null;
        if (navigator.geolocation) {
          (function(__iced_k) {
            __iced_deferrals = new iced.Deferrals(__iced_k, {
              parent: ___iced_passed_deferral,
              filename: "public/js/app-mobile/views/appview.coffee",
              funcname: "initialize"
            });
            navigator.geolocation.getCurrentPosition(__iced_deferrals.defer({
              assign_fn: (function() {
                return function() {
                  position = arguments[0];
                  return error = arguments[1];
                };
              })(),
              lineno: 21
            }));
            __iced_deferrals._fulfill();
          })(function() {
            if (error) console.log(error);
            geonames = {};
            geonames.baseURL = "http://api.geonames.org/";
            geonames.method = "neighbourhoodJSON";
            geonames.search = function(latitude, longitude) {
              return jQuery.getJSON(geonames.baseURL + geonames.method + "?lat=" + latitude + "&lng=" + longitude + "&username=wpoosanguansit", function(response) {
                var _ref, _ref1, _ref2;
                console.log(JSON.stringify(response));
                _this.city = response != null ? (_ref = response.neighbourhood) != null ? _ref.adminName1 : void 0 : void 0;
                _this.state = response != null ? (_ref1 = response.neighbourhood) != null ? _ref1.adminCode1 : void 0 : void 0;
                return _this.country = response != null ? (_ref2 = response.neighbourhood) != null ? _ref2.countryCode : void 0 : void 0;
              });
            };
            _this.latitude = position.coords.latitude;
            _this.longitude = position.coords.longitude;
            return __iced_k(geonames.search(_this.latitude, _this.longitude));
          });
        } else {
          return __iced_k(console.log("geolocation not supported"));
        }
      },
      events: {
        "click a.set-location": "setLocation",
        "click a.browse": "browse",
        "click a.search": "search",
        "click a.get-app": "getApp",
        "click a.dashboard-icon": "getCategory"
      },
      setLocation: function(event) {
        this.locationDialog = new SetLocationDialog({
          appView: this
        });
        return this.locationDialog.render();
      },
      browse: function(event) {
        return this.routers.root();
      },
      search: function(event) {
        this.searchView = new SearchView({});
        return this.searchView.render();
      },
      getApp: function(event) {
        this.getAppView = new GetAppView({});
        return this.getAppView.render();
      },
      getCategory: function(event) {
        var category;
        console.log("getCategory");
        category = jQuery(event.currentTarget).attr("id");
        this.categoryListView = new CategoryListView({
          category: category
        });
        return this.categoryListView.render();
      },
      keyLoadResults: function(event) {
        var endpoint, query, sort;
        query = jQuery('#searchbox').val();
        if (query) {
          sort = jQuery('#sortBy').val();
          endpoint = melisting.utils.queryConstructor(query, sort, 1);
          location.hash = endpoint;
        } else {
          melisting.utils.loadPrompt('Please enter a search query to continue');
        }
        return false;
      }
    });
    return AppView;
  });

}).call(this);
