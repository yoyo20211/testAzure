/**
 * Library of control flow utilities.  There are lots of promise libraries on node
 * and to disambiguate what I am using for my personal style from those, I chose the
 * (near) synonym "future".  I actually enjoy most of the callback style of node
 * and don't want to hide it too much, so this library attempts to do very little
 * magic, relying instead on explicit intent.
 */
function sliceArray(ary, begin, end) {
	return Array.prototype.slice.call(ary, begin, end);
}

/**
 * Block class is used for routing errors to higher level logic.
 */
function Block(errback) {
	this._parent=Block.current;
	this._errback=errback;
}
Block.current=null;

/**
 * Wrap a function such that any exceptions it generates
 * are sent to the error callback of the Block that is active
 * at the time of the call to guard().  If no Block
 * is active, just returns the function.
 *
 * Example: stream.on('end', Block.guard(function() { ... }));
 */
Block.guard=function(f) {
	if (this.current) return this.current.guard(f);
	else return f;
};

/**
 * Begins a new Block with two callback functions.  The first
 * is the main part of the block (think 'try body'), the
 * second is the rescue function/error callback (think 'catch').
 * The terminology follows Ruby for no other reason than that
 * Block, begin and rescue describe an exception handling
 * paradigm and are not reserved words in JavaScript.
 */
Block.begin=function(block, rescue) {
	var ec=new Block(rescue);
	return ec.trap(block);
};

/**
 * Returns a function(err) that can be invoked at any time to raise
 * an exception against the now current block (or the current context
 * if no current).  Errors are only raised if the err argument is true
 * so this can be used in both error callbacks and error events.
 *
 * Example: request.on('error', Block.errorHandler())
 */
Block.errorHandler=function() {
	// Capture the now current Block for later
	var current=this.current;
	
	return function(err) {
		if (!err) return;
		if (current) return current.raise(err);
		else throw err;
	};
};

/**
 * Raises an exception on the Block.  If the block has an
 * error callback, it is given the exception.  Otherwise,
 * raise(...) is called on the parent block.  If there is
 * no parent, the exception is simply raised.
 * Any nested exceptions from error callbacks will be raised
 * on the block's parent.
 */
Block.prototype.raise=function(err) {
	if (this._errback) {
		try {
			this._errback(err);
		} catch (nestedE) {
			if (this._parent) this._parent.raise(nestedE);
			else throw nestedE;
		}
	} else {
		if (this._parent) this._parent.raise(err);
		else throw(err);
	}
};

/**
 * Executes a callback in the context of this block.  Any
 * errors will be passed to this Block's raise() method.
 * Returns the value of the callback or undefined on error.
 */
Block.prototype.trap=function(callback) {
	var origCurrent=Block.current;
	Block.current=this;
	try {
		var ret=callback();
		Block.current=origCurrent;
		return ret;
	} catch (e) {
		Block.current=origCurrent;
		this.raise(e);
	}
};

/**
 * Wraps a function and returns a function that routes
 * errors to this block.  This is similar to trap but
 * returns a new function instead of invoking the callback
 * immediately.
 */
Block.prototype.guard=function(f) {
	if (f.__guarded__) return f;
	var self=this;
	var wrapped=function() {
		var origCurrent=Block.current;
		Block.current=self;
		try {
			var ret=f.apply(this, arguments);
			Block.current=origCurrent;
			return ret;
		} catch (e) {
			Block.current=origCurrent;
			self.raise(e);
		}
	};
	wrapped.__guarded__=true;
	return wrapped;
};

/**
 * A Future class as per the literature on the topic.
 * The two main operations are force() and resolve().
 */
function Future(resolution) {
	this._resolved=false;
	this._errored=false;
	this._resolution=null;
	this._pending=null;
	if (arguments.length>0) {
		// Create a resolved future
		this.resolve(resolution);
	}
}
/**
 * Cast an arbitrary value to a Future.  If already a Future,
 * just return it.  Otherwise, return a new Future resolved
 * with the value.
 */
Future.cast=function(futureOrLiteral) {
	if (futureOrLiteral instanceof Future) return futureOrLiteral;
	else return new Future(futureOrLiteral);
};
Future.prototype={};

/**
 * Invokes the callback(result) upon resolution of the future.
 * Return true if force executed immediately, false if pended.
 *
 * If the callback is pended, it is wrapped with Block.guard
 * so that any exceptions it throws are routed to the Block
 * in effect at the time of the call to force().
 */
Future.prototype.force=function(callback) {
	if (this._resolved) {
		if (callback) callback(this._resolution);
		return true;
	} else if (callback) {
		// Pend it.
		var pended=Block.guard(callback);
		if (!this._pending) this._pending=[pended];
		else this._pending.push(pended);
		return false;
	} else {
		return false;
	}
};

/**
 * Resolves the future.  Any pended force callbacks are
 * executed immediately.  Any future calls to force() will
 * invoke their callbacks immediately.
 */
Future.prototype.resolve=function(resolution) {
	if (this._resolved) {
		throw new Error('Logic error.  Future resolved multiple times.');
	}
	this._resolved=true;
	this._resolution=resolution;
	
	if (this._pending) {
		this._pending.forEach(function(pended) {
			pended(resolution);
		});
	}
};

/**
 * Return a new Future whose resolution is dependent on
 * the resolution of this future.  When this future is
 * resolved, the transformer callback will be invoked with
 * its resolution and the callback result will become the
 * resolution of the new Future returned by this method.
 */
Future.prototype.chain=function(transformer) {
	var chained=new Future();
	this.force(function(resolution) {
		chained.resolve(transformer(resolution));
	});
	return chained;
};
/**
 * Forward the resolution from this future to another future.
 * This future is forced and the resolution is resolved on
 * the passed future.
 */
Future.prototype.forward=function(otherFuture) {
	this.force(function(resolution) {
		otherFuture.resolve(resolution);
	});
};

// -- exports
exports.Block=Block;
exports.Future=Future;
