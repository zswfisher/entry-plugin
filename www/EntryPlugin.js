cordova.define("entry-plugin.EntryPlugin", function(require, exports, module) {
var exec = require('cordova/exec');

var EntryPlugin = {
    hybridCallAction:function(hybridStr,successBlock,failBlock) {
        exec(successBlock, failBlock, "EntryPlugin", "jsCallNative", [hybridStr]);
    }
};
module.exports = EntryPlugin;
});
