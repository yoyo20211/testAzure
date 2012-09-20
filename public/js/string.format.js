String.prototype.format = function(){
    var args = arguments;
    return this.replace(/\{(\d)\}/g, function(a,b){
        return typeof args[b] != 'undefined' ? args[b] : a;
    });
}