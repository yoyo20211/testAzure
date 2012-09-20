require.config( {
    paths: {
        'backbone':         'AMDbackbone-0.5.3',
        'underscore':       'AMDunderscore-1.2.2',
        'text':             'require/text',
        'jade':             'require/jade',
        'jquery':           'jquery-1.7.1',
        'json2':            'json2',
        'jquerymobile':     'jquery.mobile-1.0.1.min',
        'jquerymobilepagination':  'jquery.mobile.pagination',
        'order':                'order-1.0.0',
        'jquerymobilerouter' :  'jquery.mobile.router',
        'jquery-ui':        'jquery-ui-1.8.17.custom.min',
        'collection.data':  'app-mobile/collection/data',
        'view.detail':      'app-mobile/views/Detail',
        'app':              'app-mobile/app'
    },
    baseUrl: '/js'
} );

require(
    /* No AMD support in jQuery 1.6.4, underscore 1.3 and backbone 0.5.3 :(
    Using this shim instead to ensure proper load sequence*/

    ['require', 'jquery', 'underscore', 'order!backbone' ],
    function (require, $, _, Backbone) {

        // Exposing globals just in case that we are switching to AMD version of the lib later
        var global = this;

        global.$ = global.$ || $;
        global.jQuery = global.jQuery || jQuery;
        global._ = global._ || _;
        global.Backbone = global.Backbone || Backbone;

        console.log('core libs loaded');

        require(
            ['require', 'order!jquerymobile', 'jquerymobilerouter', 'jquerymobilepagination', 'order!app'],
            function (require, jQueryMobile, jquerymobilerouter, jQueryMobilePagination,  app) {
                console.log('jquery.mobile.router loaded');
                require('app').init();
        });
});

