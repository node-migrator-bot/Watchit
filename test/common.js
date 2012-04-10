var path, watchit,
  __slice = Array.prototype.slice;

path = require('path');

global.expect = require('expect.js');

global.delay = function(time, func) {
  if (func == null) {
    func = time;
    time = 50;
  }
  return setTimeout(func, time);
};

global.fixture = function() {
  var pathes;
  pathes = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
  return path.join.apply(path, [__dirname, 'fixtures'].concat(__slice.call(pathes)));
};

global.watchit = watchit = require('../lib/watchit');

global.conditionalTimeout = watchit.conditionalTimeout;

global.notifyWhenExists = watchit.notifyWhenExists;