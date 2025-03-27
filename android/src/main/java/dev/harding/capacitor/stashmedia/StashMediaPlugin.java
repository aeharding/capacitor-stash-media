package dev.harding.capacitor.stashmedia;

import android.Manifest;
import android.content.ClipData;
import android.content.ContentValues;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Build;
import android.provider.MediaStore;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.URL;
import java.net.URLConnection;

@CapacitorPlugin(name = "StashMedia")
public class StashMediaPlugin extends Plugin {

    private StashMedia stashMedia;

    @Override
    public void load() {
        String userAgent = getBridge().getConfig().getAppendedUserAgentString();
        stashMedia = new StashMedia(userAgent);
    }

    @PluginMethod
    public void copyPhotoToClipboard(PluginCall call) {
        Context context = getContext();
        String url = call.getString("url");

        if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.P) {
            // Check if permission is not granted
            if (
                ContextCompat.checkSelfPermission(context, Manifest.permission.WRITE_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED
            ) {
                // Request permission
                ActivityCompat.requestPermissions(getActivity(), new String[] { Manifest.permission.WRITE_EXTERNAL_STORAGE }, 9002);

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
            if (
                ContextCompat.checkSelfPermission(context, Manifest.permission.WRITE_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED
            ) {
                // Request permission
                ActivityCompat.requestPermissions(getActivity(), new String[] { Manifest.permission.WRITE_EXTERNAL_STORAGE }, 9001);

                call.reject("Permissions requested");

                return;
            }
        }

        stashMedia.savePhoto(
            context,
            url,
            new StashMedia.StashMediaCallback() {
                @Override
                public void onSuccess() {
                    call.resolve();
                }

                @Override
                public void onError(String errorMessage) {
                    call.reject(errorMessage);
                }
            }
        );
    }

    @PluginMethod
    public void saveVideo(PluginCall call) {
        String url = call.getString("url");
        Context context = getContext();

        if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.P) {
            // Check if permission is not granted
            if (
                ContextCompat.checkSelfPermission(context, Manifest.permission.WRITE_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED
            ) {
                // Request permission
                ActivityCompat.requestPermissions(getActivity(), new String[] { Manifest.permission.WRITE_EXTERNAL_STORAGE }, 9003);

                call.reject("Permissions requested");

                return;
            }
        }

        stashMedia.saveVideo(
            context,
            url,
            new StashMedia.StashMediaCallback() {
                @Override
                public void onSuccess() {
                    call.resolve();
                }

                @Override
                public void onError(String errorMessage) {
                    call.reject(errorMessage);
                }
            }
        );
    }

    @PluginMethod
    public void shareImage(PluginCall call) {
        String imageUrl = call.getString("url");
        String title = call.getString("title");

        if (imageUrl != null && title != null) {
            stashMedia.downloadAndSaveImageForSharing(
                getContext(),
                imageUrl,
                title,
                new StashMedia.ImageDownloadListener() {
                    @Override
                    public void onImageDownloaded(Uri imageUri) {
                        Intent shareIntent = new Intent(Intent.ACTION_SEND);
                        shareIntent.setType("image/*");
                        shareIntent.putExtra(Intent.EXTRA_STREAM, imageUri);
                        shareIntent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
                        shareIntent.setClipData(ClipData.newRawUri("", imageUri));

                        Intent chooserIntent = Intent.createChooser(shareIntent, "Share Image");
                        getActivity().startActivity(chooserIntent);

                        call.resolve();
                    }

                    @Override
                    public void onImageDownloadFailed() {
                        call.reject("DOWNLOAD_FAILED", "Failed to download and save the image");
                    }
                }
            );
        } else {
            call.reject("INVALID_PARAMETERS", "URL or title parameter is missing");
        }
    }
}
