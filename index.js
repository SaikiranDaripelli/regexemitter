/*global module, window, define */
'use strict';

function EventEmitter() {
  this.domain = null;
  this._events = null;
  this._maxListeners = 10;
}

EventEmitter.listeners = function (emitter, listener) {
  if (!emitter) { return -1; }
  if (!Array.isArray( emitter._events )) { return 0; }
  if (!listener) { return emitter._events.length; }
  return emitter._events.filter(function (event) {
    return (String(event.regex) === String(listener));
  }).length;
};

EventEmitter.prototype.on = function (name, listener) {
  if (this._events && this._events.length >= this._maxListeners) {
    return this.emit('error', 'max event listeners');
  }
  if (!( name instanceof RegExp || 'string' === typeof name )) {
    throw new Error( 'on only takes regex or string event names' );
  }
  if ( 'function' !== typeof listener ) {
    throw new Error( 'on only takes instances of Function' );
  }
  if( !Array.isArray( this._events ) ){ this._events = []; }
  this._events.push({
    regex: name,
    cb: listener
  });
};

EventEmitter.prototype.once = function (name, listener) {
  if (this._events && this._events.length >= this._maxListeners) {
    return this.emit('error', 'max event listeners');
  }
  if (!( name instanceof RegExp || 'string' === typeof name )) {
    throw new Error( 'once only takes regex or string event names' );
  }
  if ( 'function' !== typeof listener ) {
    throw new Error( 'once only takes instances of Function' );
  }
  if( !Array.isArray( this._events ) ){ this._events = []; }
  this._events.push({
    regex: name,
    cb: listener,
    once: true
  });
};

EventEmitter.prototype.addListener = EventEmitter.prototype.on;

// @todo, what is the required functionality when passing a listener?
EventEmitter.prototype.removeListener = function (name, listener) {
  if (!( name instanceof RegExp || 'string' === typeof name )) {
    return this.emit('error', 'invalid event name');
  }
  if( !Array.isArray( this._events ) ){ return; }
  this._events = this._events.filter(function (event) {
    return (String(event.regex) !== String(name));
  });
};

EventEmitter.prototype.removeAllListeners = function (regex) {
  if (arguments.length && !( regex instanceof RegExp || 'string' === typeof regex )) {
    return this.emit('error', 'invalid event name');
  }
  if( !Array.isArray( this._events ) ){ return; }
  this._events = this._events.filter(function (event) {
    if (!regex) { return false; }
    if (String(event.regex) === String(regex)) { return false; }
    return true;
  });
};

EventEmitter.prototype.setMaxListeners = function (max) {
  if ('number' !== typeof max) {
    return this.emit('error', 'invalid max value');
  }
  this._maxListeners = max;
};

EventEmitter.prototype.listeners = function (name) {
  if( !Array.isArray( this._events ) ){ return this._events; }
  return this._events.filter(function (event) {
    return (!name || String(event.regex) === String(name));
  });
};

EventEmitter.prototype.match = function (match) {
  var i = 0, len;
  if ('string' !== typeof match) { throw new Error('invalid string'); }
  if( !Array.isArray( this._events ) ){ return false; }
  for (len = this._events.length; i < len; i++) {
    if (match.match(this._events[i].regex)) {
      return true;
    }
  }
  return false;
};

EventEmitter.prototype.emit = function ( key ) {
  if ('string' !== typeof key) { throw new Error('invalid string'); }
  var args = Array.prototype.slice.call(arguments, 0);
  args.shift(); // shift key off args
  var _self = this, i = 0, len;
  if( !Array.isArray( this._events ) ){ return; }
  for (len = this._events.length; i < len; i++) {
    var event = _self._events[i];
    if (event && key.match(event.regex)) {
      if ('function' === typeof event.cb) {
        event.cb.apply({ event: key }, args);
        if (event.once) { delete _self._events[i]; }
      }
    }
  }
};

// Export for nodejs
if (module !== undefined && module.exports !== undefined) {
  module.exports = EventEmitter;
} else {
  // Export for AMD
  if (typeof define === 'function' && define.amd) {
    define([], function () { return EventEmitter; });
  // Export to browser
  } else {
    window.EventEmitter = EventEmitter;
  }
}