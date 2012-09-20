// //From http://webreflection.blogspot.com/2009/01/internet-explorer-object-watch.html.

(function(watch, unwatch){
createWatcher = watch && unwatch ?
    // Andrea Giammarchi - Mit Style License
    function(Object){
        var handlers = [];
        return {
            destroy:function(){
                handlers.forEach(function(prop){
                    unwatch.call(this, prop);
                }, this);
                delete handlers;
            },
            watch:function(prop, handler){
                if(-1 === handlers.indexOf(prop))
                    handlers.push(prop);
                watch.call(this, prop, function(prop, prevValue, newValue){
                    return Object[prop] = handler.call(Object, prop, prevValue, newValue);
                });
            },
            unwatch:function(prop){
                var i = handlers.indexOf(prop);
                if(-1 !== i){
                    unwatch.call(this, prop);
                    handlers.splice(i, 1);
                };
            }
        }
    }:(Object.prototype.__defineSetter__?
    function(Object){
        console.log("init object watch.");
        var handlers = [];
        return {
            destroy:function(){
                handlers.forEach(function(prop){
                    delete this[prop];
                }, this);
                delete handlers;
            },
            watch:function(prop, handler){
                console.log("watch is called.");
                if(-1 === handlers.indexOf(prop))
                    handlers.push(prop);
                if(!this.__lookupGetter__(prop))
                    this.__defineGetter__(prop, function(){return Object[prop]});
                this.__defineSetter__(prop, function(newValue){
                    Object[prop] = handler.call(Object, prop, Object[prop], newValue);
                });
            },
            unwatch:function(prop){
                var i = handlers.indexOf(prop);
                if(-1 !== i){
                    delete this[prop];
                    handlers.splice(i, 1);
                };
            }
        };
    }:
    function(Object){
        function onpropertychange(){
            var prop = event.propertyName,
                newValue = empty[prop]
                prevValue = Object[prop],
                handler = handlers[prop];
            if(handler)
                attachEvent(detachEvent()[prop] = Object[prop] = handler.call(Object, prop, prevValue, newValue));
        };
        function attachEvent(){empty.attachEvent("onpropertychange", onpropertychange)};
        function detachEvent(){empty.detachEvent("onpropertychange", onpropertychange);return empty};
        var empty = document.createElement("empty"), handlers = {};
        empty.destroy = function(){
            detachEvent();
            empty.parentNode.removeChild(empty);
            empty = handlers = null;
        };
        empty.watch = function(prop, handler){handlers[prop] = handler};
        empty.unwatch = function(prop){delete handlers[prop]};
        attachEvent();
        return (document.getElementsByTagName("head")[0] || document.documentElement).appendChild(empty);
    }
    )
;
})(Object.prototype.watch, Object.prototype.unwatch);

// Cross-browser object.watch and object.unwatch from https://gist.github.com/384583.

// object.watch
// if (!Object.prototype.watch) {
//     Object.prototype.watch = function (prop, handler) {
//         var oldval = this[prop], newval = oldval,
//         getter = function () {
//             return newval;
//         },
//         setter = function (val) {
//             oldval = newval;
//             return newval = handler.call(this, prop, oldval, val);
//         };
//         if (delete this[prop]) { // can't watch constants
//             if (Object.defineProperty) { // ECMAScript 5
//                 Object.defineProperty(this, prop, {
//                     get: getter,
//                     set: setter,
//                     enumerable: false,
//                     configurable: true
//                 });
//             } else if (Object.prototype.__defineGetter__ && Object.prototype.__defineSetter__) { // legacy
//                 Object.prototype.__defineGetter__.call(this, prop, getter);
//                 Object.prototype.__defineSetter__.call(this, prop, setter);
//             }
//         }
//     };
// }

// // object.unwatch
// if (!Object.prototype.unwatch) {
//     Object.prototype.unwatch = function (prop) {
//         var val = this[prop];
//         delete this[prop]; // remove accessors
//         this[prop] = val;
//     };
// }