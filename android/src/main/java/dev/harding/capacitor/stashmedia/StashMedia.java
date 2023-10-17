package dev.harding.capacitor.stashmedia;

import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.ContentValues;
import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.os.Environment;
import android.provider.MediaStore;
import android.util.Base64;
import android.util.Log;
import android.webkit.MimeTypeMap;

import androidx.core.content.FileProvider;

import java.io.BufferedInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLConnection;
import java.text.SimpleDateFormat;
import java.util.Date;

public class StashMedia {
    public void copyPhotoToClipboard(Context context, String imageUrl) {
        try {
            // Fetch the image from the URL
            Bitmap bitmap = fetchImageFromURL(imageUrl);

            if (bitmap != null) {
                // Copy the image to the clipboard
                Uri imageUri = bitmapToUri(context, bitmap);
                copyImageToClipboard(context, imageUri);
                Log.d("StashMedia", "Image copied to clipboard");
            } else {
                Log.e("StashMedia", "Failed to fetch or decode image");
            }
        } catch (IOException e) {
            Log.e("StashMedia", "Failed to fetch image data: " + e.getMessage());
        }
    }

    private Bitmap fetchImageFromURL(String imageUrl) throws IOException {
        Bitmap bitmap = null;

        try (InputStream inputStream = new java.net.URL(imageUrl).openStream()) {
            bitmap = BitmapFactory.decodeStream(inputStream);
        } catch (IOException e) {
            Log.e("StashMedia", "Failed to fetch image: " + e.getMessage());
            throw e;
        }

        return bitmap;
    }

    private Uri bitmapToUri(Context context, Bitmap bitmap) {
        Uri imageUri = null;

        try (ByteArrayOutputStream bytes = new ByteArrayOutputStream()) {
            bitmap.compress(Bitmap.CompressFormat.JPEG, 100, bytes);

            SimpleDateFormat dateFormat = new SimpleDateFormat("yyyyMMdd_HHmmss");
            String dateTimeString = dateFormat.format(new Date());

            String path = MediaStore.Images.Media.insertImage(context.getContentResolver(), bitmap, "Image_" + dateTimeString, null);
            imageUri = Uri.parse(path);
        } catch (IOException e) {
            Log.e("StashMedia", "Failed to convert bitmap to URI: " + e.getMessage());
        }

        return imageUri;
    }

    private void copyImageToClipboard(Context context, Uri imageUri) {
        ClipboardManager clipboardManager = (ClipboardManager) context.getSystemService(Context.CLIPBOARD_SERVICE);
        if (clipboardManager != null) {
            ClipData clipData = ClipData.newUri(context.getContentResolver(), "", imageUri);
            clipboardManager.setPrimaryClip(clipData);
        }
    }

    public void savePhoto(Context context, String url) {
        try {
            URL imageUrl = new URL(url);
            URLConnection connection = imageUrl.openConnection();
            connection.connect();

            String mimeType = connection.getContentType();

            SimpleDateFormat dateFormat = new SimpleDateFormat("yyyyMMdd_HHmmss");
            String dateTimeString = dateFormat.format(new Date());

            ContentValues contentValues = new ContentValues();
            contentValues.put(MediaStore.Images.Media.DISPLAY_NAME, "Image_" + dateTimeString);
            contentValues.put(MediaStore.Images.Media.MIME_TYPE, mimeType);

            Uri imageUri = context.getContentResolver().insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, contentValues);

            if (imageUri != null) {
                try (OutputStream outputStream = context.getContentResolver().openOutputStream(imageUri);
                     InputStream inputStream = new BufferedInputStream(connection.getInputStream())) {
                    if (outputStream != null) {
                        byte[] buffer = new byte[4096];
                        int bytesRead;
                        while ((bytesRead = inputStream.read(buffer)) != -1) {
                            outputStream.write(buffer, 0, bytesRead);
                        }
                        outputStream.flush();
                        Log.d("StashMedia", "Image saved to gallery");
                    } else {
                        Log.e("StashMedia", "Output stream is null");
                    }
                } catch (IOException e) {
                    Log.e("StashMedia", "Failed to save image: " + e.getMessage());
                }
            } else {
                Log.e("StashMedia", "Failed to create image URI");
            }
        } catch (IOException e) {
            Log.e("StashMedia", "Failed to fetch image data: " + e.getMessage());
        }
    }

    public void downloadAndSaveImageForSharing(Context context, String imageUrl, String title, ImageDownloadListener listener) {
        try {
            URL url = new URL(imageUrl);
            URLConnection connection = url.openConnection();
            connection.connect();

            String mimeType = connection.getContentType();
            String fileExtension = MimeTypeMap.getSingleton().getExtensionFromMimeType(mimeType);

            if (fileExtension == null || fileExtension.isEmpty()) {
                fileExtension = "jpg"; // Default to JPEG if extension is unknown
            }

            File cacheDir = context.getCacheDir();
            File outputFile = new File(cacheDir, title + "." + fileExtension);

            FileOutputStream outputStream = new FileOutputStream(outputFile);
            InputStream inputStream = connection.getInputStream();
            byte[] buffer = new byte[4096];
            int bytesRead;
            while ((bytesRead = inputStream.read(buffer)) != -1) {
                outputStream.write(buffer, 0, bytesRead);
            }
            outputStream.close();
            inputStream.close();

            outputFile.deleteOnExit();
            Uri imageUri = FileProvider.getUriForFile(context, context.getPackageName() + ".fileprovider", outputFile);

            listener.onImageDownloaded(imageUri);
        } catch (IOException e) {
            listener.onImageDownloadFailed();
            e.printStackTrace();
        }
    }

    interface ImageDownloadListener {
        void onImageDownloaded(Uri imageUri);
        void onImageDownloadFailed();
    }
}
