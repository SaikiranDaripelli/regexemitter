
EventEmitter = require '../index'
# EventEmitter = require('events').EventEmitter
should = require 'should'
events = require 'events'

describe 'EventEmitter', ->

  it 'should be a function', -> EventEmitter.should.be.instanceof Function

  it 'can be used to extend other functions', ->

    func = -> EventEmitter.call this
    Object.keys( new func ).should.eql Object.keys( new EventEmitter )

  describe 'constructor', ->

    it 'should not require any arguments', ->

      ( -> new EventEmitter() ).should.not.throw()

    describe 'default properties', ->

      it 'should have an empty array for storing events', ->

        emitter = new EventEmitter()
        emitter.should.have.property('_events').and.eql null

      it 'should have a reasonable default value for max listeners', ->

        emitter = new EventEmitter()
        emitter.should.have.property('_maxListeners').and.eql 10

      it 'should have a null domain property', ->

        emitter = new EventEmitter()
        emitter.should.have.property('domain').and.eql null

  describe 'public interface', ->

    # ---------------------------------------------------------------------------------------

    it 'should have a static method - listeners()', ->

      EventEmitter.should.have.property('listeners').and.be.instanceof Function

    describe 'EventEmitter.listeners( emitter, listener )', ->

      it 'should accept 2 arguments', ->

        EventEmitter.listeners.length.should.eql 2

      it 'should return -1 unless valid emitter is supplied', ->

        EventEmitter.listeners().should.eql -1

      it 'should return 0 for new emitters', ->

        EventEmitter.listeners( new EventEmitter() ).should.eql 0

      it 'should return the length of _events for a given emitter', ->

        emitter = new EventEmitter()
        emitter.on( 'test', -> null )

        emitter._events.length = 1
        EventEmitter.listeners( emitter ).should.eql 1

      it 'should return the length of matching events when listener is supplied', ->

        emitter = new EventEmitter()
        emitter.on( 'test1', -> null )
        emitter.on( 'test1', -> null )
        emitter.on( 'test2', -> null )

        EventEmitter.listeners( emitter ).should.eql 3
        EventEmitter.listeners( emitter, 'test1' ).should.eql 2
        EventEmitter.listeners( emitter, 'test2' ).should.eql 1
        EventEmitter.listeners( emitter, 'test3' ).should.eql 0

    # ---------------------------------------------------------------------------------------

    it 'should have a prototype method - on()', ->

      EventEmitter.prototype.should.have.property('on').and.be.instanceof Function

    describe 'EventEmitter.prototype.on( event, listener )', ->

      it 'should accept 2 arguments', ->

        emitter = new EventEmitter()
        emitter.on.length.should.eql 2
      
      it 'should validate the event name is string or regex', ->

        emitter = new EventEmitter()

        [ 'test', /test/, new RegExp( 'test' ) ].forEach ( eventName ) ->
          (-> emitter.on( eventName, -> null ) ).should.not.throw()

        [ null, undefined, 0, 1, 1.1, [], {}, -> null ].forEach ( eventName ) ->
          (-> emitter.on( eventName, -> null ) ).should.throw 'on only takes regex or string event names'

      it 'should require a valid listener', ->

        emitter = new EventEmitter()

        (-> emitter.on( 'test', -> null ) ).should.not.throw()
        emitter._events[0].should.have.property('regex').and.eql 'test'
        emitter._events[0].should.have.property('cb').and.be.instanceof Function

        [ null, undefined, 0, 1, 1.1, [], {} ].forEach ( listener ) ->
          (-> emitter.on( 'test', listener ) ).should.throw 'on only takes instances of Function'

      it 'should register a new listener for an event', ->

        emitter = new EventEmitter()
        emitter.on( 'test', -> null )
        emitter._events[0].should.have.property('regex').and.eql 'test'
        emitter._events[0].should.have.property('cb')
        emitter._events.length.should.eql 1

      it 'should not set the once flag for an event', ->

        emitter = new EventEmitter()
        emitter.on( 'test', -> null )
        emitter._events[0].should.not.have.property 'once'

      it 'should call listeners more than once', (done) ->

        callCount = 0
        emitter = new EventEmitter()
        emitter.on /hello (adam|ben)/, -> done() if ++callCount > 1

        emitter.emit( 'hello adam' )
        emitter.emit( 'hello ben' )
        emitter.emit( 'hello chris' )

      it 'should expose the original event key', (done) ->

        emitter = new EventEmitter()
        emitter.on /hello (adam|ben)/, ->
          this.should.have.property 'event'
          this.event.should.eql 'hello ben'
          done()

        emitter.emit( 'hello ben' )

      it 'should emit error when hitting max event listeners', (done) ->

        emitter = new EventEmitter()
        emitter.on 'error', (err) ->
          err.should.eql 'max event listeners'
          done()

        emitter.setMaxListeners 2 # 'error' counts for 1 listener
        emitter.on 'test1', -> null
        emitter.on /test2/, -> null

    # ---------------------------------------------------------------------------------------

    it 'should have a prototype method - once()', ->

      EventEmitter.prototype.should.have.property('once').and.be.instanceof Function

    describe 'EventEmitter.prototype.once( event, listener )', ->

      it 'should accept 2 arguments', ->

        emitter = new EventEmitter()
        emitter.once.length.should.eql 2
      
      it 'should validate the event name is string or regex', ->

        emitter = new EventEmitter()

        [ 'test', /test/, new RegExp( 'test' ) ].forEach ( eventName ) ->
          (-> emitter.once( eventName, -> null ) ).should.not.throw()

        [ null, undefined, 0, 1, 1.1, [], {}, -> null ].forEach ( eventName ) ->
          (-> emitter.once( eventName, -> null ) ).should.throw 'once only takes regex or string event names'

      it 'should require a valid listener', ->

        emitter = new EventEmitter()

        (-> emitter.once( 'test', -> null ) ).should.not.throw()
        emitter._events[0].should.have.property('regex').and.eql 'test'
        emitter._events[0].should.have.property('cb').and.be.instanceof Function

        [ null, undefined, 0, 1, 1.1, [], {} ].forEach ( listener ) ->
          (-> emitter.once( 'test', listener ) ).should.throw 'once only takes instances of Function'

      it 'should register a new listener for an event', ->

        emitter = new EventEmitter()
        emitter.once( 'test', -> null )
        emitter._events[0].should.have.property('regex').and.eql 'test'
        emitter._events[0].should.have.property('cb')
        emitter._events.length.should.eql 1

      it 'should set the once flag for an event', ->

        emitter = new EventEmitter()
        emitter.once( 'test', -> null )
        emitter._events[0].should.have.property 'once'

      it 'should only call listeners once', (done) ->

        # mocha will warn if done is called more than once
        emitter = new EventEmitter()
        emitter.once /hello (adam|ben)/, done

        emitter.emit( 'hello adam' )
        emitter.emit( 'hello ben' )
        emitter.emit( 'hello chris' )

      it 'should expose the original event key', (done) ->

        emitter = new EventEmitter()
        emitter.once /hello (adam|ben)/, ->
          this.should.have.property 'event'
          this.event.should.eql 'hello ben'
          done()

        emitter.emit( 'hello ben' )

      it 'should emit error when hitting max event listeners', (done) ->

        emitter = new EventEmitter()
        emitter.on 'error', (err) ->
          err.should.eql 'max event listeners'
          done()

        emitter.setMaxListeners 2 # 'error' counts for 1 listener
        emitter.once 'test1', -> null
        emitter.once /test2/, -> null

    # ---------------------------------------------------------------------------------------

    it 'should have a prototype method - addListener()', ->

      EventEmitter.prototype.should.have.property('addListener').and.be.instanceof Function

    describe 'EventEmitter.prototype.addListener( event, listener )', ->

      it 'should be an alias of on()', ->

        EventEmitter.prototype.addListener.should.equal EventEmitter.prototype.on

    # ---------------------------------------------------------------------------------------

    it 'should have a prototype method - removeListener()', ->

      EventEmitter.prototype.should.have.property('removeListener').and.be.instanceof Function

    describe 'EventEmitter.prototype.removeListener( event )', ->

      it 'should accept 2 arguments', ->

        emitter = new EventEmitter()
        emitter.removeListener.length.should.eql 2

      it 'should validate event name is string or regex', ->

        errors = []
        emitter = new EventEmitter()
        emitter.on( 'error', (err) -> errors.push(err) )

        valid = [ 'test', /test/, new RegExp( 'test' ) ]
        invalid = [ null, undefined, 0, 1, 1.1, [], {}, -> null ]
        
        valid.forEach ( eventName ) -> emitter.removeListener( eventName, -> null )
        errors.should.eql []

        invalid.forEach ( eventName ) -> emitter.removeListener( eventName, -> null )
        errors.length.should.eql invalid.length
        errors[0].should.eql 'invalid event name'

      it 'should remove all listeners matching event', ->

        emitter = new EventEmitter()
        emitter.on( 'test1', -> null )
        emitter.on( 'test1', -> null )
        emitter.on( 'test2', -> null )

        emitter.removeListener( 'test3' )
        emitter._events.length.should.eql 3
        emitter.removeListener( 'test1' )
        emitter._events.length.should.eql 1
        emitter.removeListener( 'test2' )
        emitter._events.length.should.eql 0

    # ---------------------------------------------------------------------------------------

    it 'should have a prototype method - removeAllListeners()', ->

      EventEmitter.prototype.should.have.property('removeAllListeners').and.be.instanceof Function

    describe 'EventEmitter.prototype.removeAllListeners( event )', ->

      it 'should accept 1 argument', ->

        emitter = new EventEmitter()
        emitter.removeAllListeners.length.should.eql 1

      it 'should remove all events when event name not supplied as first argument', ->

        emitter = new EventEmitter()
        emitter.on( 'test1', -> null )
        emitter.on( 'test2', -> null )
        emitter._events.length.should.eql 2

        emitter.removeAllListeners()
        emitter._events.length.should.eql 0

      it 'should validate event name is string or regex when supplied', ->

        errors = []
        emitter = new EventEmitter()
        emitter.on( 'error', (err) -> errors.push(err) )

        valid = [ 'test', /test/, new RegExp( 'test' ) ]
        invalid = [ null, undefined, 0, 1, 1.1, [], {}, -> null ]

        valid.forEach ( eventName ) -> emitter.removeAllListeners( eventName, -> null )
        errors.should.eql []

        invalid.forEach ( eventName ) -> emitter.removeAllListeners( eventName, -> null )
        errors.length.should.eql invalid.length
        errors[0].should.eql 'invalid event name'

    # ---------------------------------------------------------------------------------------

    it 'should have a prototype method - setMaxListeners()', ->

      EventEmitter.prototype.should.have.property('setMaxListeners').and.be.instanceof Function

    describe 'EventEmitter.prototype.setMaxListeners( max )', ->

      it 'should accept 1 argument', ->

        emitter = new EventEmitter()
        emitter.setMaxListeners.length.should.eql 1

      it 'should validate max is an number', ->

        errors = []
        emitter = new EventEmitter()
        emitter.on( 'error', (err) -> errors.push(err) )

        valid = [ 0, 1, 1.1 ]
        invalid = [ null, undefined, 'test', /test/, new RegExp( 'test' ), [], {}, -> null ]

        valid.forEach ( max ) -> emitter.setMaxListeners( max )
        errors.should.eql []

        invalid.forEach ( max ) -> emitter.setMaxListeners( max )
        errors.length.should.eql invalid.length
        errors[0].should.eql 'invalid max value'

      it 'should update the _maxListeners property', ->

        emitter = new EventEmitter()
        emitter.setMaxListeners( 999 )
        emitter._maxListeners.should.eql 999

    # ---------------------------------------------------------------------------------------

    it 'should have a prototype method - listeners()', ->

      EventEmitter.prototype.should.have.property('listeners').and.be.instanceof Function

    describe 'EventEmitter.prototype.listeners( event )', ->

      it 'should accept 1 argument', ->

        emitter = new EventEmitter()
        emitter.listeners.length.should.eql 1

      it 'should return empty _events object for new emitters', ->

        emitter = new EventEmitter()
        should.equal emitter.listeners(), emitter._events

      it 'should return the contents of _events', ->

        emitter = new EventEmitter()
        emitter.on( 'test', -> null )
        emitter.listeners().should.eql emitter._events

      it 'should return only the events equal to supplied listener', ->

        emitter = new EventEmitter()
        emitter.on( 'test1', -> null )
        emitter.on( 'test1', -> null )
        emitter.on( 'test2', -> null )

        emitter.listeners().should.eql emitter._events
        Object.keys( emitter.listeners( 'test1' ) ).length.should.eql 2
        Object.keys( emitter.listeners( 'test2' ) ).length.should.eql 1
        Object.keys( emitter.listeners( 'test3' ) ).length.should.eql 0
        emitter.listeners().should.eql emitter._events

    # ---------------------------------------------------------------------------------------

    it 'should have a prototype method - match()', ->

      EventEmitter.prototype.should.have.property('match').and.be.instanceof Function

    describe 'EventEmitter.prototype.match( key )', ->

      it 'should accept 1 argument', ->

        emitter = new EventEmitter()
        emitter.match.length.should.eql 1

      it 'should validate the match text is a string', ->

        emitter = new EventEmitter()

        (-> emitter.match( 'test', -> null ) ).should.not.throw()

        [ /test/, new RegExp( 'test' ), null, undefined, 0, 1, 1.1, [], {}, -> null ].forEach ( key ) ->
          (-> emitter.match( key, -> null ) ).should.throw 'invalid string'

      it 'should return boolean true/false if an event name matches supplied string', ->

        emitter = new EventEmitter()
        emitter.on( /bingo|bango/, -> null )
        emitter.once( 'foo', -> null )
        emitter.match( 'bingo' ).should.eql true
        emitter.match( 'foo' ).should.eql true
        emitter.match( 'baz' ).should.eql false

    # ---------------------------------------------------------------------------------------

    it 'should have a prototype method - emit()', ->

      EventEmitter.prototype.should.have.property('emit').and.be.instanceof Function

    describe 'EventEmitter.prototype.emit( key, args... )', ->

      it 'should validate the key is a string', ->

        emitter = new EventEmitter()

        (-> emitter.emit( 'test', 'arg1' ) ).should.not.throw()

        [ /test/, new RegExp( 'test' ), null, undefined, 0, 1, 1.1, [], {}, -> null ].forEach ( key ) ->
          (-> emitter.emit( key ) ).should.throw 'invalid string'

      it 'should not require arguments', ->

        emitter = new EventEmitter()
        (-> emitter.emit( 'test' ) ).should.not.throw()

      it 'should accept arguments', ->

        emitter = new EventEmitter()
        (-> emitter.emit( 'test', 'arg1', 'arg2' ) ).should.not.throw()

      it 'should pass arguments to matching listeners', (done) ->

        emitter = new EventEmitter()
        emitter.on 'test', ->
          arguments.length.should.eql 2
          arguments[0].should.eql 'arg1'
          arguments[1].should.eql 'arg2'
          done()

        emitter.emit( 'test', 'arg1', 'arg2' )

  # ---------------------------------------------------------------------------------------

  describe 'nodejs native EventEmitter compatibility', ->

    emitter = regex: new EventEmitter(), nodejs: new events.EventEmitter()

    it 'should have the same prototype methods', ->

      for method in Object.keys( events.EventEmitter.prototype )
        EventEmitter.prototype.should.have.property(method).and.be.instanceof Function
        EventEmitter.prototype[method].length.should.eql events.EventEmitter.prototype[method].length

    it.skip 'should have the same properties & default values', ->

      for prop in Object.keys( emitter.nodejs )
        emitter.regex.should.have.property(prop).and.eql emitter.nodejs[prop]

    describe.skip 'should store events in a compatible way', ->

      if process.version.match /0\.10\./

        it 'should default _events to {} for newer versions of node', ->

          emitter = new EventEmitter()
          emitter.should.have.property('_events').and.eql {}

      else

        it 'should default _events to null for older versions of node', ->

          emitter = new EventEmitter()
          emitter.should.have.property('_events').and.eql null

       it.skip 'should set _events to object on first insert', ->

        emitter = new EventEmitter()
        emitter.should.have.property('_events').and.eql null
        emitter.on( 'test', -> null )
        emitter.should.have.property('_events').and.eql { test: -> null }

       it.skip 'should set _events key to array on second insert', ->

        emitter = new EventEmitter()
        emitter.should.have.property('_events').and.eql null
        emitter.on( 'test', -> null )
        emitter.on( 'test', -> null )
        emitter.should.have.property('_events').and.eql { test: [ ( -> null ), ( -> null ) ] }

      it.skip 'should store once events in the same way (once wrapper)', ->

        should.exist null