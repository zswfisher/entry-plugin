var exec = require('cordova/exec');

var EntryPlugin = {
    hybridCallAction:function(hybridStr,successBlock,failBlock) {
        exec(successBlock, failBlock, "EntryPlugin", "jsCallNative", [hybridStr]);
    }
};
module.exports = EntryPlugin;
