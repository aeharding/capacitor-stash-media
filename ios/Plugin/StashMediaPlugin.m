#import <Foundation/Foundation.h>
#import <Capacitor/Capacitor.h>

CAP_PLUGIN(StashMediaPlugin, "StashMedia",
           CAP_PLUGIN_METHOD(copyPhotoToClipboard, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(savePhoto, CAPPluginReturnPromise);
)
