
jQuery.editable.addInputType("password", { element:function(settings,original) {
        var input=jQuery("<input type='password'>");
        if(settings.width!="none") {
            input.width(settings.width);
        }
        if(settings.height!="none") {
            input.height(settings.height);
        }
        input.attr("autocomplete","off");
        jQuery(this).append(input);
        return(input);
    }
});

ko.bindingHandlers.jeditable = {
     init: function(element, valueAccessor, allBindingsAccessor) {
        // get the options that were passed in
        var options = allBindingsAccessor().jeditableOptions || {};
          
        // "submit" should be the default onblur action like regular ko controls
        if (!options.onblur) {
          options.onblur = 'submit';
        }
          
        // set the value on submit and pass the editable the options
        jQuery(element).editable(function(value, params) {
            valueAccessor()(value);
            if (!value) {
                return "click to edit";
            } else {
                return value;
            }
        }, options);
 
         //handle disposal (if KO removes by the template binding)
        ko.utils.domNodeDisposal.addDisposeCallback(element, function() {
             $(element).editable("destroy");
        });
 
     },
      
     //update the control when the view model changes
     update: function(element, valueAccessor) {
        var value = ko.utils.unwrapObservable(valueAccessor());
        if (value === true) 
            value = "true";
        else if (value === false)
            value = "false";
        if (value instanceof Array)
            value = value.join(", ")
        $(element).editable().html(value);
     }
 };

 ko.bindingHandlers.date = {
    update: function(element, valueAccessor, allBindingsAccessor) {
        var value = valueAccessor(), allBindings = allBindingsAccessor();
        var valueUnwrapped = ko.utils.unwrapObservable(value);
        var d = "";
        if (valueUnwrapped) {
            var m = /Date\([\d+-]+\)/gi.exec(valueUnwrapped);
            if (m) {
                d = String.format("{0:/MM/dd/yyyy}", eval("new " + m[0]));
            }
        }       
        $(element).text(d);   
    }
};

ko.bindingHandlers.money = {
    update: function(element, valueAccessor, allBindingsAccessor) {
        var value = valueAccessor(), allBindings = allBindingsAccessor();
        var valueUnwrapped = ko.utils.unwrapObservable(value);
       
        var m = "";
        if (valueUnwrapped) {       
            m = parseInt(valueUnwrapped);
            if (m) {
                m = String.format("{0:n0}", m);
            }
        }       
        $(element).text(m);   
    }
}; 

/*  Knockout extender for dates that are round-tripped in ISO 8601 format
 *  Depends on knockout.js and date.format.js
 *  Includes extensions for the date object that:
 *      add Date.toISOString() for browsers that do not nativly implement it
 *      replaces Date.parse() with version to supports ISO 8601 (IE and Safari do not)
 *  Includes example of how to use the extended binding
 */

(function() {
    ko.extenders.isoDate = function(target, formatString) {
        target.formattedDate = ko.computed({
            read: function() {
                if (!target()) {
                    return;
                }
                var dt = new Date(Date.parse(target()));
                return dt.format(formatString, true);
            },
            write: function(value) {
                if (value) {
                    target(new Date(Date.parse(value)).toISOString());
                }
            }
        });

        //initialize with current value
        target.formattedDate(target());

        //return the computed observable
        return target;
    };
}());


/** from the mozilla documentation (before they implemented the function in the browser)
 * https://developer.mozilla.org/index.php?title=en/JavaScript/Reference/Global_Objects/Date&revision=65
 */
(function(Date) {
    if (!Date.prototype.toISOString) {
        Date.prototype.toISOString = function() {
            function pad(n) {
                return n < 10 ? '0' + n : n;
            }
            return this.getUTCFullYear() + '-' + pad(this.getUTCMonth() + 1) + '-' + pad(this.getUTCDate()) + 'T' + pad(this.getUTCHours()) + ':' + pad(this.getUTCMinutes()) + ':' + pad(this.getUTCSeconds()) + 'Z';
        };
    }
}(Date));

/**
 * Date.parse with progressive enhancement for ISO 8601 <https://github.com/csnover/js-iso8601>
 * © 2011 Colin Snover <http://zetafleet.com>
 * Released under MIT license.
 */
(function(Date) {
    var origParse = Date.parse,
        numericKeys = [1, 4, 5, 6, 7, 10, 11];
    Date.parse = function(date) {
        var timestamp, struct, minutesOffset = 0;

        // ES5 §15.9.4.2 states that the string should attempt to be parsed as a Date Time String Format string
        // before falling back to any implementation-specific date parsing, so that’s what we do, even if native
        // implementations could be faster
        //              1 YYYY                2 MM       3 DD           4 HH    5 mm       6 ss        7 msec        8 Z 9 ±    10 tzHH    11 tzmm
        if ((struct = /^(\d{4}|[+\-]\d{6})(?:-(\d{2})(?:-(\d{2}))?)?(?:T(\d{2}):(\d{2})(?::(\d{2})(?:\.(\d{3}))?)?(?:(Z)|([+\-])(\d{2})(?::(\d{2}))?)?)?$/.exec(date))) {
            // avoid NaN timestamps caused by “undefined” values being passed to Date.UTC
            for (var i = 0, k;
            (k = numericKeys[i]); ++i) {
                struct[k] = +struct[k] || 0;
            }

            // allow undefined days and months
            struct[2] = (+struct[2] || 1) - 1;
            struct[3] = +struct[3] || 1;

            if (struct[8] !== 'Z' && struct[9] !== 'undefined') {
                minutesOffset = struct[10] * 60 + struct[11];

                if (struct[9] === '+') {
                    minutesOffset = 0 - minutesOffset;
                }
            }

            timestamp = Date.UTC(struct[1], struct[2], struct[3], struct[4], struct[5] + minutesOffset, struct[6], struct[7]);
        }
        else {
            timestamp = origParse ? origParse(date) : NaN;
        }

        return timestamp;
    };
}(Date));