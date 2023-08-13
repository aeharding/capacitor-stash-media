package dev.harding.capacitor.stashmedia;

import android.Manifest;
import android.content.Context;
import android.content.pm.PackageManager;
import android.os.Build;

import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

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
        Context context = getContext();
        String url = call.getString("url");

        if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.P) {
            // Check if permission is not granted
            if (ContextCompat.checkSelfPermission(context, Manifest.permission.WRITE_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED) {
                // Request permission
                ActivityCompat.requestPermissions(getActivity(), new String[]{Manifest.permission.WRITE_EXTERNAL_STORAGE}, 9002);

                call.reject("Permissions requested");

                return;
            }
        }

        stashMedia.copyPhotoToClipboard(context, url);
        call.resolve();
    }

    @PluginMethod
    public void savePhoto(PluginCall call) {
        String url = call.getString("url");
        Context context = getContext();

        if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.P) {
            // Check if permission is not granted
            if (ContextCompat.checkSelfPermission(context, Manifest.permission.WRITE_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED) {
                // Request permission
                ActivityCompat.requestPermissions(getActivity(), new String[]{Manifest.permission.WRITE_EXTERNAL_STORAGE}, 9001);

                call.reject("Permissions requested");

                return;
            }
        }

        stashMedia.savePhoto(context, url);
        call.resolve();
    }
}
