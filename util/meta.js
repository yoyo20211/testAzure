// Generated by IcedCoffeeScript 1.2.0j
var defun,
  __slice = [].slice;

dict2func = function(dictionary) {
  return function() {
    var indices;
    indices = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    return indices.reduce(function(a, i) {
      return a[i];
    }, dictionary);
  };
};
