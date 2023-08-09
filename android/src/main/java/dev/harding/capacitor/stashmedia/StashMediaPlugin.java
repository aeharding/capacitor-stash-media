package dev.harding.capacitor.stashmedia;

import android.content.Context;

import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;

@CapacitorPlugin(name = "StashMedia")
public class StashMediaPlugin extends Plugin {

    private StashMedia stashMedia = new StashMedia();

    @PluginMethod
    public void copyPhotoToClipboard(PluginCall call) {
        String url = call.getString("url");
        stashMedia.copyPhotoToClipboard(getContext(), url);
        call.resolve();
    }

    @PluginMethod
    public void savePhoto(PluginCall call) {
        String url = call.getString("url");
        Context context = getContext();
        stashMedia.savePhoto(context, url);
        call.resolve();
    }
}
