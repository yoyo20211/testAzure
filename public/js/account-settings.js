// Generated by IcedCoffeeScript 1.2.0t
(function() {
  var __slice = [].slice,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  window.iced = {
    Deferrals: (function() {

      function _Class(_arg) {
        this.continuation = _arg;
        this.count = 1;
        this.ret = null;
      }

      _Class.prototype._fulfill = function() {
        if (!--this.count) return this.continuation(this.ret);
      };

      _Class.prototype.defer = function(defer_params) {
        var _this = this;
        ++this.count;
        return function() {
          var inner_params, _ref;
          inner_params = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
          if (defer_params != null) {
            if ((_ref = defer_params.assign_fn) != null) {
              _ref.apply(null, inner_params);
            }
          }
          return _this._fulfill();
        };
      };

      return _Class;

    })(),
    findDeferral: function() {
      return null;
    }
  };
  window.__iced_k = window.__iced_k_noop = function() {};

  head.ready(function() {
    var client;
    _.templateSettings = {
      interpolate: /\{\{([\s\S]+?)\}\}/g
    };
    client = {
      templates: {},
      loadTemplates: function(names, callback) {
        var loadTemplate, that;
        that = this;
        loadTemplate = function(index) {
          var name;
          name = names[index];
          console.log('Loading template: ' + name);
          return jQuery.get('/pages/' + name + '.html', function(data) {
            that.templates[name] = data;
            index++;
            if (index < names.length) {
              return loadTemplate(index);
            } else {
              if (callback) return callback();
            }
          });
        };
        return loadTemplate(0);
      },
      get: function(name) {
        return this.templates[name];
      }
    };
    return jQuery(window).load(function() {
      return jQuery(function() {
        var $alert, $detailWindow, $documentBody, $mainContent, $notice, $postitemsMenu, $postitemsView, $profileMenu, $profileView, AppRouter, COMMUNICATION_PAYMENT_INDEX, Controller, MenuView, PERSONAL_INFO_INDEX, PostItemsView, ProfileView, WishListView, accountSettings, controller, cookie, dispatcher, info, loggedin, message, postitemArray, postitemMap, result, router, setUpGridEditPostItem, setUpGridShowComments, setupDispatcher, string, token, user, username, wishlist, wishlistArray, ___iced_passed_deferral, __iced_deferrals, __iced_k,
          _this = this;
        __iced_k = __iced_k_noop;
        ___iced_passed_deferral = iced.findDeferral(arguments);
        PERSONAL_INFO_INDEX = 0;
        COMMUNICATION_PAYMENT_INDEX = 1;
        loggedin = jQuery("input#loggedin").val() === "true";
        string = jQuery("input#token").val();
        if (string !== "" && string !== null) token = JSON.parse(string);
        if (!token) {
          cookie = jQuery.cookies.get('logintoken');
          if (cookie) token = JSON.parse(cookie);
        }
        username = token != null ? token.username : void 0;
        $alert = jQuery("div#alert");
        $notice = jQuery("div#notice");
        $documentBody = jQuery("body");
        $mainContent = jQuery("div.account-settings-main-content");
        $profileMenu = jQuery("div#account-settings-menu-profile");
        $postitemsMenu = jQuery("div#account-settings-menu-postitems");
        $profileView = jQuery("div#account-settings-main-content-profile");
        $postitemsView = jQuery("div#account-settings-main-content-postitems");
        postitemMap = {};
        user = {};
        wishlist = {};
        if (!jQuery.cookies.test()) {
          message = "<p>The browser does not allow the application to save cookies.\n    Please enable cookies in your browser to use full functinality of the site.\n</p>";
          $alert.html(message).fadeIn(1500).delay(4500).fadeOut(1500);
        }
        jQuery("#loggedin-account-nav").show();
        jQuery("li#username").text(token.username);
        $documentBody.off("click", "a#signout").on("click", "a#signout", function(event) {
          rpc.request({
            url: "../../../api/logout/",
            method: "POST",
            data: {
              "username": username
            }
          }, function(response) {
            var result;
            result = JSON.parse(response.data);
            if ((result != null ? result.response : void 0) === "success") {
              jQuery.cookies.del("logintoken");
              jQuery.cookies.del("username");
              jQuery("input#loggedin").val("false");
              jQuery("input#token").val("");
              return window.location = "/";
            } else {
              return $alert.html("<p>" + result.message + "</p>").fadeIn(1500).delay(3500).fadeOut(1500);
            }
          }, function(error) {
            message = "<p>There is an error occurred while we try to logout of your account.\nSorry for the inconvenience.  If the problem persists,\nplease contact admin@melisting.com for further assistance.</p>";
            return $alert.html("<p>" + message + "</p>").fadeIn(1500).delay(3500).fadeOut(1500);
          });
          return event.preventDefault();
        });
        (function(__iced_k) {
          __iced_deferrals = new iced.Deferrals(__iced_k, {
            parent: ___iced_passed_deferral,
            filename: "account-settings.coffee"
          });
          jQuery.getJSON("/api/alluserinfo/{0}/".format(username), __iced_deferrals.defer({
            assign_fn: (function() {
              return function() {
                return result = arguments[0];
              };
            })(),
            lineno: 132
          }));
          __iced_deferrals._fulfill();
        })(function() {
          if (result.response === "success") {
            info = result.context;
            user = info.user;
            postitemMap = info.postitemMap;
            wishlist = info.wishlist;
            console.log("++++++++++++++++++++++++ " + JSON.stringify(_.values(postitemMap)));
          } else {
            console.log("error ------------------------- " + result.response);
            return;
          }
          postitemArray = _.values(postitemMap);
          wishlistArray = _.values(wishlist);
          accountSettings = {
            user: user,
            currentView: ko.observable("profile"),
            postitems: postitemArray,
            wishlist: wishlistArray,
            numberOfPostItems: ko.observable(postitemArray.length),
            numberOfWishList: ko.observable(wishlistArray.length),
            items: ko.observableArray([]),
            username: ko.observableArray(),
            hashedPassword: ko.observable(),
            email: ko.observable(),
            address: ko.observable(),
            updateProfile: ko.observable(),
            cancelUpdateProfile: ko.observable()
          };
          ko.applyBindings(accountSettings);
          MenuView = (function(_super) {

            __extends(MenuView, _super);

            MenuView.name = 'MenuView';

            function MenuView() {
              _this.render = __bind(_this.render, this);
              return MenuView.__super__.constructor.apply(this, arguments);
            }

            MenuView.prototype.el = jQuery('account-settings-menu');

            MenuView.prototype.initialize = function(options) {
              this.options = options;
              this.dispatcher = this.options.event;
              return console.log("menu init");
            };

            MenuView.prototype.events = {
              "click div#account-settings-menu-profile a": "showProfile",
              "click div#account-settings-menu-postitems a": "showPostItems",
              "click div#account-settings-menu-wishlist a": "showWishList"
            };

            MenuView.prototype.render = function() {
              this.showProfile();
              return this;
            };

            MenuView.prototype.showProfile = function() {
              return this.dispatcher.trigger("menuView:showProfile");
            };

            MenuView.prototype.showPostItems = function() {
              return this.dispatcher.trigger("menuView:showPostItems");
            };

            MenuView.prototype.showWishList = function() {
              return this.dispatcher.trigger("menuView:showWishList");
            };

            return MenuView;

          })(Backbone.View);
          ProfileView = (function(_super) {

            __extends(ProfileView, _super);

            ProfileView.name = 'ProfileView';

            function ProfileView() {
              _this.setupMap = __bind(_this.setupMap, this);

              _this.initTabs = __bind(_this.initTabs, this);

              _this.render = __bind(_this.render, this);
              return ProfileView.__super__.constructor.apply(this, arguments);
            }

            ProfileView.prototype.el = jQuery('div#account-settings-main-content-profile');

            ProfileView.prototype.initialize = function(options) {
              var _this = this;
              this.options = options;
              console.log("ProfileView init");
              this.dispatcher = this.options.event;
              this.previousProfile = this.options.user;
              this.user = ko.mapping.fromJS(this.options.user);
              ko.validation.rules.pattern.message = 'Invalid.';
              ko.validation.configure({
                registerExtenders: true,
                messagesOnModified: true,
                insertMessages: true,
                parseInputAttributes: true,
                messageTemplate: null
              });
              this.user.username.extend({
                required: true,
                minLength: 5,
                notEqual: "click to edit"
              });
              this.user.hashedPassword.extend({
                required: true,
                minLength: 6,
                notEqual: "click to edit"
              });
              this.user.email.extend({
                email: true,
                required: true
              });
              this.user.address.neighborhood.extend({
                required: true,
                notEqual: "click to edit"
              });
              this.user.errors = ko.validation.group(this.user);
              this.user.updateProfile = function(user, event) {
                console.log("updateProfile");
                return user.username("ddd");
              };
              this.user.cancelUpdateProfile = function(user, event) {
                var profile;
                ko.cleanNode(jQuery("#personal-info")[0]);
                profile = ko.mapping.fromJS(_this.previousProfile, user);
                ko.applyBindings(profile, jQuery("#personal-info")[0]);
                if (_this.map && _this.marker) {
                  _this.map.setView(_this.previousProfile.location, 8);
                  _this.marker.setLatLng(_this.previousProfile.location);
                  return _this.marker.update();
                }
              };
              ko.applyBindings(this.user, jQuery("#personal-info")[0]);
              return this.hasInitializedTabs = false;
            };

            ProfileView.prototype.events = null;

            ProfileView.prototype.render = function() {
              if (!this.hasInitializedTabs) {
                this.initTabs();
                this.hasInitializedTabs = true;
              }
              return this;
            };

            ProfileView.prototype.initTabs = function() {
              var self;
              self = this;
              return this.profileViewTabs = jQuery("div#account-settings-main-content-profile-detail-tabs").tabs({
                create: function(event, ui) {
                  setTimeout(function() {
                    return self.setupMap();
                  }, 3000);
                  return event.preventDefault();
                },
                load: function(event, ui) {
                  return event.preventDefault();
                },
                cache: true,
                collapsible: false,
                select: function(event, ui) {
                  var index;
                  index = ui.index;
                  switch (index) {
                    case PERSONAL_INFO_INDEX:
                      console.log("PERSONAL_INFO_INDEX");
                      if (self.map) {
                        return L.Util.requestAnimFrame(self.map.invalidateSize, self.map, !1, self.map._container);
                      }
                      break;
                    case COMMUNICATION_PAYMENT_INDEX:
                      return console.log("COMMUNICATION_PAYMENT_INDEX");
                    default:
                      return console.log("INDEX ERROR");
                  }
                }
              });
            };

            ProfileView.prototype.setupMap = function() {
              var changeLocation, location, self, showLocation,
                _this = this;
              self = this;
              location = self.user.location();
              this.map = L.map("profile-info-map", {
                doubleClickZoom: false
              }).setView(location, 8);
              L.tileLayer("http://{s}.tile.cloudmade.com/552ed20c2dcf46d49a048d782d8b37e6/997/256/{z}/{x}/{y}.png", {
                attribution: 'Map data &copy; <a href="http://openstreetmap.org">OpenStreetMap</a> contributors, <a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>, Imagery © <a href="http://cloudmade.com">CloudMade</a>',
                maxZoom: 18
              }).addTo(this.map);
              this.marker = L.marker(location, {
                draggable: true,
                clickable: true
              }).addTo(this.map);
              this.popup = L.popup();
              showLocation = function(event) {
                var latitude, latlng, longitude, target;
                target = null;
                if (event.hasOwnProperty("target")) target = event.target;
                latlng = event.latlng || target.getLatLng();
                latitude = latlng.lat;
                longitude = latlng.lng;
                return jQuery.ajax({
                  url: "http://open.mapquestapi.com/geocoding/v1/reverse?lat={0}&lng={1}".format(latitude, longitude),
                  dataType: 'jsonp',
                  success: function(response) {
                    var city, country, neighborhood, state;
                    if (response.results[0]) {
                      location = response.results[0].locations[0];
                    }
                    if (location) {
                      neighborhood = location.street || "Not Available";
                      city = location.adminArea5 || "";
                      state = location.adminArea3 || "";
                      country = location.adminArea1 || "";
                      if (city && country) {
                        _this.map.closePopup();
                        _this.popup.setLatLng(latlng).setContent("The location clicked is {0}, {1}".format(city, country)).openOn(_this.map);
                        return setTimeout(function() {
                          return _this.map.closePopup();
                        }, 10000);
                      } else {
                        return console.log("error");
                      }
                    } else {
                      return console.log("error");
                    }
                  },
                  error: function(error) {
                    return alert("Error");
                  }
                });
              };
              changeLocation = function(event) {
                var latitude, latlng, longitude, target;
                target = null;
                if (event.hasOwnProperty("target")) target = event.target;
                latlng = event.latlng || target.getLatLng();
                latitude = latlng.lat;
                longitude = latlng.lng;
                return jQuery.ajax({
                  url: "http://open.mapquestapi.com/geocoding/v1/reverse?lat={0}&lng={1}".format(latitude, longitude),
                  dataType: 'jsonp',
                  success: function(response) {
                    var city, country, neighborhood, state;
                    if (response.results[0]) {
                      location = response.results[0].locations[0];
                    }
                    if (location) {
                      neighborhood = location.street || "Not Available";
                      city = location.adminArea5 || "";
                      state = location.adminArea3 || city;
                      country = location.adminArea1 || "";
                      if (city && country) {
                        _this.map.closePopup();
                        _this.popup.setLatLng(latlng).setContent("You have updated your location to {0}, {1}".format(city, country)).openOn(_this.map);
                        setTimeout(function() {
                          return _this.map.closePopup();
                        }, 10000);
                        _this.marker.setLatLng(latlng);
                        self.user.location([latitude, longitude]);
                        self.user.address.city(city);
                        self.user.address.state(state);
                        self.user.address.country(country);
                        return self.user.address.neighborhood(neighborhood);
                      } else {
                        return console.log("error");
                      }
                    } else {
                      return console.log("error");
                    }
                  },
                  error: function(error) {
                    return alert("Error");
                  }
                });
              };
              this.marker.on("dragend", changeLocation);
              this.marker.on("click", showLocation);
              this.map.on("click", showLocation);
              return this.map.on("dblclick", changeLocation);
            };

            return ProfileView;

          })(Backbone.View);
          PostItemsView = (function(_super) {

            __extends(PostItemsView, _super);

            PostItemsView.name = 'PostItemsView';

            function PostItemsView() {
              _this.render = __bind(_this.render, this);
              return PostItemsView.__super__.constructor.apply(this, arguments);
            }

            PostItemsView.prototype.el = jQuery('div#account-settings-main-content-postitems');

            PostItemsView.prototype.initialize = function(options) {
              this.options = options;
              console.log("PostItemsView init");
              this.dispatcher = this.options.event;
              this.postitems = this.options.postitems;
              return this.hasInitializedTabs = false;
            };

            PostItemsView.prototype.events = null;

            PostItemsView.prototype.render = function() {
              if (!this.hasInitializedTabs) {
                this.initTabs();
                this.initGrid();
                this.hasInitializedTabs = true;
              }
              return this;
            };

            PostItemsView.prototype.initTabs = function() {
              return this.profileViewTabs = jQuery("div#account-settings-main-content-postitems-detail-tabs").tabs({
                load: function(event, ui) {
                  return event.preventDefault();
                },
                cache: true,
                collapsible: false,
                select: function(event, ui) {
                  var index;
                  return index = ui.index;
                }
              });
            };

            PostItemsView.prototype.initGrid = function() {
              var selectedIds, self;
              self = this;
              selectedIds = {};
              self.grid = jQuery("div#grid");
              return self.grid.kendoGrid({
                dataSource: {
                  data: postitemArray,
                  schema: {
                    model: {
                      uid: "_id",
                      fields: {
                        select: {
                          type: "string",
                          editable: false
                        },
                        _id: {
                          type: "string"
                        },
                        title: {
                          type: "string"
                        },
                        itemDescription: {
                          type: "string"
                        },
                        price: {
                          type: "number"
                        },
                        category: {
                          type: "string"
                        },
                        username: {
                          type: "string"
                        },
                        userRating: {
                          type: "number"
                        },
                        createdDate: {
                          type: "date"
                        },
                        neighborhood: {
                          type: "string"
                        }
                      }
                    }
                  },
                  pageSize: 8
                },
                height: "90%",
                sortable: true,
                resizable: true,
                pageable: true,
                selectable: "multiple",
                toolbar: [
                  {
                    text: "Post New Item",
                    className: "k-grid-postitem-post",
                    imageClass: "k-add"
                  }, {
                    text: "Repost",
                    className: "k-grid-postitem-repost",
                    imageClass: "k-add"
                  }, {
                    text: "Delete",
                    className: "k-grid-postitem-delete",
                    imageClass: "k-delete"
                  }
                ],
                columns: [
                  {
                    field: "select",
                    title: "&nbsp;",
                    template: "<input id=#=_id# class='postitem-checkbox' type='checkbox' />",
                    sortable: false,
                    width: 66
                  }, {
                    field: "_id",
                    title: "ID",
                    hidden: true
                  }, {
                    field: "title",
                    title: "Title",
                    width: 150
                  }, {
                    field: "itemDescription",
                    title: "Description",
                    width: 450
                  }, {
                    field: "category",
                    title: "Category",
                    width: 100
                  }, {
                    field: "price",
                    title: "Price",
                    width: 60
                  }, {
                    field: "userRating",
                    title: "Lister Rating",
                    width: 126
                  }, {
                    field: "createdDate",
                    title: "Date",
                    template: "#= kendo.toString(createdDate,'MM/dd/yyyy') #",
                    width: 100
                  }, {
                    command: {
                      text: "Edit",
                      click: function(event) {
                        var postitem;
                        console.log("edit");
                        postitem = this.dataItem(jQuery(event.currentTarget).closest("tr"));
                        setUpGridEditPostItem(postitem);
                        return event.preventDefault();
                      }
                    },
                    title: "",
                    width: 98
                  }, {
                    command: {
                      text: "Comments",
                      click: function(event) {
                        var postitem;
                        postitem = this.dataItem(jQuery(event.currentTarget).closest("tr"));
                        setUpGridShowComments(postitem);
                        return event.preventDefault();
                      }
                    },
                    title: "",
                    width: 120
                  }
                ],
                dataBound: function() {
                  var $grid, grid, ids, idx, len, selected, _i;
                  grid = this;
                  grid.table.find("tr").find("td:first input").change(function(event) {
                    var checkbox, ids, selected;
                    checkbox = jQuery(this);
                    checkbox.attr("checked", checkbox.is(":checked"));
                    selected = grid.table.find("tr").find("td:first input:checked").closest("tr");
                    grid.clearSelection();
                    ids = selectedIds[grid.dataSource.page()] = [];
                    if (selected.length) {
                      grid.select(selected);
                      return selected.each(function(idx, item) {
                        return ids.push(jQuery(item).data("uid"));
                      });
                    }
                  }).end().mousedown(function(event) {
                    return event.stopPropagation();
                  });
                  selected = jQuery();
                  ids = selectedIds[grid.dataSource.page()] || [];
                  len = ids.length;
                  for (idx = _i = 0; 0 <= len ? _i <= len : _i >= len; idx = 0 <= len ? ++_i : --_i) {
                    selected = selected.add(grid.table.find("tr[data-uid=" + ids[idx] + "]"));
                  }
                  selected.find("td:first input").attr("checked", true).trigger("change");
                  $grid = self.grid.data("kendoGrid");
                  $grid.thead.find("th:first").append(jQuery('<input class="select-all" type="checkbox"/>')).delegate(".select-all", "click", function() {
                    var checkbox;
                    checkbox = jQuery(this);
                    return $grid.table.find("tr").find("td:first input").attr("checked", checkbox.is(":checked")).trigger("change");
                  });
                  $documentBody.off("click", ".k-grid-postitem-post").on("click", ".k-grid-postitem-post", function() {
                    console.log("post");
                    return grid = $grid;
                  });
                  $documentBody.off("click", ".k-grid-postitem-repost").on("click", ".k-grid-postitem-repost", function() {
                    console.log("repost");
                    grid = $grid;
                    grid.refresh();
                    return grid.select().each(function() {
                      var postitem;
                      postitem = grid.dataItem(jQuery(this));
                      return console.log(postitem);
                    });
                  });
                  return $documentBody.off("click", ".k-grid-postitem-delete").on("click", ".k-grid-postitem-delete", function() {
                    console.log("repost");
                    grid = $grid;
                    grid.refresh();
                    return grid.select().each(function() {
                      var postitem;
                      postitem = grid.dataItem(jQuery(this));
                      return console.log(postitem);
                    });
                  });
                }
              });
            };

            return PostItemsView;

          })(Backbone.View);
          $detailWindow = jQuery("div#account-settings-main-content-postitems-detail-window");
          setUpGridEditPostItem = function(postitem) {
            if (!$detailWindow.data("kendoWindow")) {
              jQuery("body").append("<div id='current-postitem' style='display:none;'>" + JSON.stringify(postitem) + "</div>");
              $detailWindow.kendoWindow({
                actions: ["Close", "Maximize"],
                draggable: false,
                height: "80%",
                modal: true,
                resizable: false,
                width: "80%",
                content: "/pages/edit-listing/",
                close: function(event) {
                  return jQuery("div#current-postitem").remove();
                }
              });
            } else {
              jQuery("body").append("<div id='current-postitem' style='display:none;'>" + JSON.stringify(postitem) + "</div>");
              $detailWindow.data("kendoWindow").content("Loading...").refresh("/pages/edit-listing/").open();
            }
            return jQuery("div#account-settings-main-content-postitems-detail-window").closest(".k-window").css({
              top: "10%",
              left: "10%"
            });
          };
          setUpGridShowComments = function(postitem) {
            return console.log("show comments");
          };
          WishListView = (function(_super) {

            __extends(WishListView, _super);

            WishListView.name = 'WishListView';

            function WishListView() {
              _this.render = __bind(_this.render, this);
              return WishListView.__super__.constructor.apply(this, arguments);
            }

            WishListView.prototype.el = jQuery('div#account-settings-main-content-wishlist');

            WishListView.prototype.initialize = function(options) {
              this.options = options;
              console.log("WishListView init");
              return this.dispatcher = this.options.event;
            };

            WishListView.prototype.events = null;

            WishListView.prototype.render = function() {
              return this;
            };

            return WishListView;

          })(Backbone.View);
          Controller = (function() {

            Controller.name = 'Controller';

            function Controller(options) {
              _this.showWishList = __bind(_this.showWishList, this);

              _this.showPostItems = __bind(_this.showPostItems, this);

              _this.showProfile = __bind(_this.showProfile, this);
              console.log("controller");
              this.dispatcher = options.event;
              setupDispatcher(this);
              this.accountSettings = options.accountSettings;
              this.menuView = new MenuView({
                event: this.dispatcher
              });
              this.profileView = new ProfileView({
                event: this.dispatcher,
                user: this.accountSettings.user
              });
              this.postitemsView = new PostItemsView({
                event: this.dispatcher,
                postitems: this.accountSettings.postitems
              });
              this.wishlistView = new WishListView({
                event: this.dispatcher,
                wishlist: this.accountSettings.wishlist
              });
              this.showProfile();
            }

            Controller.prototype.showProfile = function() {
              this.accountSettings.currentView("profile");
              this.profileView.render();
              return this;
            };

            Controller.prototype.showPostItems = function() {
              this.accountSettings.currentView("postitems");
              console.log("@accountSettings.postitems " + this.accountSettings.postitems.length);
              this.postitemsView.render();
              return this;
            };

            Controller.prototype.showWishList = function() {
              this.accountSettings.currentView("wishlist");
              this.wishlistView.render();
              return this;
            };

            return Controller;

          })();
          setupDispatcher = function(controller) {
            controller.dispatcher.off("menuView:showProfile").on("menuView:showProfile", function() {
              return controller.showProfile();
            });
            controller.dispatcher.off("menuView:showPostItems").on("menuView:showPostItems", function() {
              return controller.showPostItems();
            });
            return controller.dispatcher.off("menuView:showWishList").on("menuView:showWishList", function() {
              return controller.showWishList();
            });
          };
          AppRouter = (function(_super) {

            __extends(AppRouter, _super);

            AppRouter.name = 'AppRouter';

            function AppRouter() {
              return AppRouter.__super__.constructor.apply(this, arguments);
            }

            AppRouter.prototype.initialize = function(options) {
              return null;
            };

            AppRouter.prototype.routes = {
              "/profile/:username": "showProfile",
              "/postitems/username": "showPostItems",
              "/postitems/:id": "showPostItemDetail",
              "/wishlist/:username": "showWishList"
            };

            AppRouter.prototype.showProfile = function(username) {
              return console.log('showProfile');
            };

            AppRouter.prototype.showPostItems = function(username) {
              return console.log('showPostItemInfoList');
            };

            AppRouter.prototype.showPostItemDetail = function(id) {
              return console.log('showPostItemDetail');
            };

            AppRouter.prototype.showWishList = function(username) {
              return console.log('showWishList');
            };

            return AppRouter;

          })(Backbone.Router);
          dispatcher = _.extend({}, Backbone.Events);
          controller = new Controller({
            event: dispatcher,
            accountSettings: accountSettings
          });
          router = new AppRouter({
            controller: controller
          });
          return Backbone.history.start();
        });
      });
    });
  });

}).call(this);
