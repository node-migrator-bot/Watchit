(function() {
  var EventEmitter, WatchitEmitter, defaults, extend, fs, notifyWhenExists, path, watchit;
  var __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; }, __slice = Array.prototype.slice;

  EventEmitter = require('events').EventEmitter;

  fs = require('fs');

  path = require('path');

  defaults = {
    retain: false,
    include: false,
    follow: false,
    recurse: false,
    persistent: true
  };

  watchit = function(target, options, callback) {
    var emitter, fswatcher, retainTarget, scanTargetDir, unwatchTarget, watchTarget, watchTargetDir, watchTargetFile, _ref, _ref2;
    if (typeof options === 'function') {
      callback = options;
      options = {};
    }
    options = extend({}, defaults, options != null ? options : {});
    emitter = options.emitter = (_ref = options.emitter) != null ? _ref : new WatchitEmitter(callback);
    if ((_ref2 = emitter.targets) == null) emitter.targets = {};
    if (emitter.targets[target]) return null;
    emitter.targets[target] = true;
    fswatcher = null;
    emitter.close = function() {
      return emitter.emit('close', target);
    };
    emitter.on('close', function() {
      return fswatcher != null ? fswatcher.close() : void 0;
    });
    (watchTarget = function() {
      return fs.stat(target, function(err, stats) {
        var fail;
        fail = function(err) {
          if (options.retain) {
            return notifyWhenExists(target, function() {
              emitter.emit('create', target);
              return watchTarget();
            });
          } else {
            return emitter.emit('failure', target, err);
          }
        };
        if (err) return fail(err);
        try {
          if (stats.isDirectory()) {
            fswatcher = watchTargetDir();
            if (options.include || options.recurse) scanTargetDir(true);
          } else {
            fswatcher = watchTargetFile();
          }
        } catch (e) {
          return fail(e);
        }
        emitter.emit('success', target);
        return fswatcher.on('error', function(err) {
          throw err;
        });
      });
    })();
    retainTarget = watchTarget;
    unwatchTarget = function() {
      fswatcher.close();
      if (!options.retain) return delete emitter.targets[target];
    };
    watchTargetFile = function() {
      return fs.watch(target, {
        persistent: options.persistent
      }, function(event) {
        if (event === 'rename') {
          console.log("fs.stat", target);
          return fs.stat(target, function(err) {
            if (err) {
              if (!options.follow) unwatchTarget();
              if (options.retain) retainTarget();
              console.log("Retaining " + target + ": " + options.retain);
              return emitter.emit('unlink', target);
            } else {
              return emitter.emit('change', target);
            }
          });
        } else if (event === 'change') {
          return emitter.emit('change', target);
        }
      });
    };
    watchTargetDir = function() {
      return fs.watch(target, {
        persistent: options.persistent
      }, function(event, filename) {
        if (event === 'rename') {
          return fs.stat(target, function(err) {
            if (err) {
              if (!options.follow) unwatchTarget();
              if (options.retain) retainTarget();
              return emitter.emit('unlink', target);
            } else {
              if (!options.include) emitter.emit('rename', target);
              if (options.include || options.recurse) return scanTargetDir();
            }
          });
        } else {
          throw new Error("Unexpected directory event: " + event);
        }
      });
    };
    scanTargetDir = function(initial) {
      return fs.readdir(target, function(err, items) {
        var item, _i, _len, _results;
        if (err) return;
        _results = [];
        for (_i = 0, _len = items.length; _i < _len; _i++) {
          item = items[_i];
          _results.push((function(item) {
            var itemPath;
            return fs.stat(itemPath = path.join(target, item), function(err, stats) {
              var isDir;
              if (err) return;
              isDir = stats.isDirectory();
              if ((isDir && options.recurse) || (!isDir && options.include)) {
                if (watchit(itemPath, extend({
                  emitter: emitter
                }, options))) {
                  if (!initial) return emitter.emit('create', itemPath);
                }
              }
            });
          })(item));
        }
        return _results;
      });
    };
    return emitter;
  };

  WatchitEmitter = (function() {

    __extends(WatchitEmitter, EventEmitter);

    function WatchitEmitter(callback) {
      this.callback = callback;
    }

    WatchitEmitter.prototype.emit = function() {
      var etc, event, filename;
      event = arguments[0], filename = arguments[1], etc = 3 <= arguments.length ? __slice.call(arguments, 2) : [];
      if (event === 'newListener') return;
      WatchitEmitter.__super__.emit.apply(this, [event, filename].concat(__slice.call(etc)));
      WatchitEmitter.__super__.emit.apply(this, ['all', event, filename].concat(__slice.call(etc)));
      return typeof this.callback === "function" ? this.callback.apply(this, [event, filename].concat(__slice.call(etc))) : void 0;
    };

    return WatchitEmitter;

  })();

  extend = function() {
    var obj, prop, source, sources, _i, _len;
    obj = arguments[0], sources = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    for (_i = 0, _len = sources.length; _i < _len; _i++) {
      source = sources[_i];
      for (prop in source) {
        if (prop in source) obj[prop] = source[prop];
      }
    }
    return obj;
  };

  notifyWhenExists = function(target, callback) {
    var levelUp, parentDir;
    if (!callback) throw new Error('notifyWhenExists requires a callback');
    parentDir = path.join(target, '..');
    levelUp = function() {
      return notifyWhenExists(parentDir, function() {
        return notifyWhenExists(target, callback);
      });
    };
    return path.exists(target, function(exists) {
      var fswatcher;
      if (exists) return callback();
      try {
        return fswatcher = fs.watch(parentDir, {
          persistent: options.persistent
        }, function() {
          fs.readdir(parentDir, function(err, items) {
            var item, _i, _len;
            if (err) {
              fswatcher.close();
              levelUp();
              return;
            }
            for (_i = 0, _len = items.length; _i < _len; _i++) {
              item = items[_i];
              if (path.join(parentDir, item) === target) {
                fswatcher.close();
                return callback();
              }
            }
          });
        });
      } catch (e) {
        return levelUp();
      }
    });
  };

  module.exports = watchit;

  module.exports.notifyWhenExists = notifyWhenExists;

}).call(this);
