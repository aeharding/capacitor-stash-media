package dev.harding.capacitor.stashmedia;

import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.ContentValues;
import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.provider.MediaStore;
import android.util.Base64;
import android.util.Log;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

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
            String path = MediaStore.Images.Media.insertImage(context.getContentResolver(), bitmap, "Image", null);
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
            InputStream inputStream = new java.net.URL(url).openStream();
            Bitmap bitmap = BitmapFactory.decodeStream(inputStream);

            ContentValues contentValues = new ContentValues();
            contentValues.put(MediaStore.Images.Media.DISPLAY_NAME, "Image");
            contentValues.put(MediaStore.Images.Media.MIME_TYPE, "image/jpeg");

            Uri imageUri = context.getContentResolver().insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, contentValues);

            if (imageUri != null) {
                try (OutputStream outputStream = context.getContentResolver().openOutputStream(imageUri)) {
                    bitmap.compress(Bitmap.CompressFormat.JPEG, 100, outputStream);
                    Log.d("StashMedia", "Image saved to gallery");
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
}
