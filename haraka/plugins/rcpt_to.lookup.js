// rcpt_to.lookup

// documentation via: haraka -c /Volumes/space/Projects/Javascript/ShopMe/haraka -h plugins/rcpt_to.lookup

// Put your plugin code here
// type: `haraka -h Plugins` for documentation on how to create a plugin

var path   			= require('path');
var mongoose 		= require('mongoose');
var express			= require('express');
// The path starts from Haraka folder found in nodes_modules.
var models			= require('./../../models/models');
var db 				= null;
var PostItem 		= null;
var postitemEmail		= null;
/**
* Set up the persistence models.
**/
models.defineModels(mongoose, function () {
      PostItem       = mongoose.model('PostItem');
      db             = mongoose.connect('mongodb://localhost/db');
});

// exports.hook_data = function(next, connection) {
// 	// // enable mail body parsing
// 	// connection.transaction.parse_body = 1;
// 	next();
// }

exports.hook_data_post = function(next, connection) {
	// var to = connection.transaction.rcpt_to,
	// phone_number = to[0].user,
	// from = connection.transaction.mail_from.address(),
	// body = connection.transaction.body;

	// this.loginfo(body.header.get('to'));
	// body.header.remove('to');
	// body.header.add('to', 'test'); 
	// this.loginfo(body.header.get('to'));
	// connection.transaction.rcpt_to = "test";
	if (postitemEmail) {
		connection.transaction.remove_header('To');
		connection.transaction.add_header('To', postitemEmail);
	}
	
	next();
}

exports.hook_rcpt 	 = function (next, connection, params) {
	var recipient 	 = params[0]
	this.loginfo(params);
	this.loginfo('Got the recipient: ' + recipient);

	var match 		 = /^(.*)-([a-zA-Z1-9]*)$/.exec(recipient.user);
	if (!match) {
		return next(DENY, "Email does not seem to match the address allowed.");
	}
	connection.transaction.parse_body = 1;
	
	var shortKey	 = match[2];
	//var thatlog = this.loginfo;
	PostItem.findOne({shortkey: shortKey}, function(err, postitem) {
		if (!err && postitem) {
			//change the recipient to the one found in the db.
			var array = postitem.email.split('@');
		    recipient.user = array[0];
		    recipient.host = array[1];
		    //we have to set the postitemEmail here since the smtp spec does not include body text at this point.
		    postitemEmail  = postitem.email;
		    /**
		     *print(postitem);
		     *print(recipient.user);
		     *print(recipient.host);
		    **/
		    next();
		} else {
			return next(DENY, "The key passed in is not valid.  No matching account found.");
		} 
	});

	/**
	*var print = function(obj) {
	*	thatlog(obj);
	*}
	**/
}