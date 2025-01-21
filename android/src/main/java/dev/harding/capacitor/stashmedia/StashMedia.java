package dev.harding.capacitor.stashmedia;

import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.ContentValues;
import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.provider.MediaStore;
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
import java.text.SimpleDateFormat;
import java.util.Date;
import okhttp3.Call;
import okhttp3.Callback;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;

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
        OkHttpClient client = new OkHttpClient();

        Request request = new Request.Builder().url(imageUrl).build();

        try (Response response = client.newCall(request).execute()) {
            if (!response.isSuccessful()) {
                Log.e("StashMedia", "Failed to fetch image: " + response.message());
                throw new IOException("Failed to fetch image: " + response.message());
            }

            return BitmapFactory.decodeStream(response.body().byteStream());
        } catch (IOException e) {
            Log.e("StashMedia", "Failed to fetch image: " + e.getMessage());
            throw e;
        }
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

    interface StashMediaCallback {
        void onSuccess();
        void onError(String errorMessage);
    }

    public void savePhoto(Context context, String url, StashMediaCallback stashMediaCallback) {
        OkHttpClient client = new OkHttpClient();

        Request request = new Request.Builder().url(url).build();

        client
            .newCall(request)
            .enqueue(
                new Callback() {
                    @Override
                    public void onFailure(Call call, IOException e) {
                        Log.e("StashMedia", "Failed to fetch image data: " + e.getMessage());
                        stashMediaCallback.onError("Failed to fetch image data: " + e.getMessage());
                    }

                    @Override
                    public void onResponse(Call call, Response response) {
                        try {
                            if (!response.isSuccessful()) {
                                Log.e("StashMedia", "Failed to download image: " + response.message());
                                stashMediaCallback.onError("Failed to download image: " + response.message());
                                return;
                            }

                            String mimeType = response.header("Content-Type");

                            SimpleDateFormat dateFormat = new SimpleDateFormat("yyyyMMdd_HHmmss");
                            String dateTimeString = dateFormat.format(new Date());

                            ContentValues contentValues = new ContentValues();
                            contentValues.put(MediaStore.Images.Media.DISPLAY_NAME, "Image_" + dateTimeString);
                            contentValues.put(MediaStore.Images.Media.MIME_TYPE, mimeType);

                            Uri imageUri = context.getContentResolver().insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, contentValues);

                            if (imageUri == null) {
                                Log.e("StashMedia", "Failed to create image URI");
                                stashMediaCallback.onError("Failed to create image URI");
                                return;
                            }

                            try (
                                OutputStream outputStream = context.getContentResolver().openOutputStream(imageUri);
                                BufferedInputStream inputStream = new BufferedInputStream(response.body().byteStream())
                            ) {
                                if (outputStream == null) {
                                    Log.e("StashMedia", "Output stream is null");
                                    stashMediaCallback.onError("Failed to download image: Output stream is null");
                                    return;
                                }

                                byte[] buffer = new byte[4096];
                                int bytesRead;
                                while ((bytesRead = inputStream.read(buffer)) != -1) {
                                    outputStream.write(buffer, 0, bytesRead);
                                }
                                outputStream.flush();
                                Log.d("StashMedia", "Image saved to gallery");
                                stashMediaCallback.onSuccess();
                            } catch (IOException e) {
                                Log.e("StashMedia", "Failed to save image: " + e.getMessage());
                                stashMediaCallback.onError("Failed to save image: " + e.getMessage());
                            }
                        } finally {
                            response.close();
                        }
                    }
                }
            );
    }

    public void saveVideo(Context context, String url, StashMediaCallback stashMediaCallback) {
        OkHttpClient client = new OkHttpClient();

        Request request = new Request.Builder().url(url).build();

        client
            .newCall(request)
            .enqueue(
                new Callback() {
                    @Override
                    public void onFailure(Call call, IOException e) {
                        Log.e("StashMedia", "Failed to fetch video data: " + e.getMessage());
                        stashMediaCallback.onError("Failed to fetch video data: " + e.getMessage());
                    }

                    @Override
                    public void onResponse(Call call, Response response) {
                        try {
                            if (!response.isSuccessful()) {
                                Log.e("StashMedia", "Failed to download video: " + response.message());
                                stashMediaCallback.onError("Failed to download video: " + response.message());
                                return;
                            }

                            String mimeType = response.header("Content-Type");

                            SimpleDateFormat dateFormat = new SimpleDateFormat("yyyyMMdd_HHmmss");
                            String dateTimeString = dateFormat.format(new Date());

                            ContentValues contentValues = new ContentValues();
                            contentValues.put(MediaStore.Video.Media.DISPLAY_NAME, "Video_" + dateTimeString);
                            contentValues.put(MediaStore.Video.Media.MIME_TYPE, mimeType);

                            Uri videoUri = context.getContentResolver().insert(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, contentValues);

                            if (videoUri == null) {
                                Log.e("StashMedia", "Failed to create video URI");
                                stashMediaCallback.onError("Failed to create video URI");
                                return;
                            }

                            try (
                                OutputStream outputStream = context.getContentResolver().openOutputStream(videoUri);
                                BufferedInputStream inputStream = new BufferedInputStream(response.body().byteStream())
                            ) {
                                if (outputStream == null) {
                                    Log.e("StashMedia", "Output stream is null");
                                    stashMediaCallback.onError("Failed to download video: Output stream is null");
                                    return;
                                }

                                byte[] buffer = new byte[4096];
                                int bytesRead;
                                while ((bytesRead = inputStream.read(buffer)) != -1) {
                                    outputStream.write(buffer, 0, bytesRead);
                                }
                                outputStream.flush();
                                Log.d("StashMedia", "Video saved to gallery");
                                stashMediaCallback.onSuccess();
                            } catch (IOException e) {
                                Log.e("StashMedia", "Failed to save video: " + e.getMessage());
                                stashMediaCallback.onError("Failed to save video: " + e.getMessage());
                            }
                        } finally {
                            response.close();
                        }
                    }
                }
            );
    }

    public void downloadAndSaveImageForSharing(Context context, String imageUrl, String title, ImageDownloadListener listener) {
        OkHttpClient client = new OkHttpClient();

        Request request = new Request.Builder().url(imageUrl).build();

        client
            .newCall(request)
            .enqueue(
                new Callback() {
                    @Override
                    public void onFailure(Call call, IOException e) {
                        listener.onImageDownloadFailed();
                        e.printStackTrace();
                    }

                    @Override
                    public void onResponse(Call call, Response response) {
                        try {
                            if (!response.isSuccessful()) {
                                listener.onImageDownloadFailed();
                                return;
                            }

                            String mimeType = response.header("Content-Type");
                            String fileExtension = MimeTypeMap.getSingleton().getExtensionFromMimeType(mimeType);

                            File cacheDir = context.getCacheDir();
                            File outputFile = new File(cacheDir, title + "." + fileExtension);

                            try (
                                FileOutputStream outputStream = new FileOutputStream(outputFile);
                                InputStream inputStream = response.body().byteStream()
                            ) {
                                byte[] buffer = new byte[4096];
                                int bytesRead;
                                while ((bytesRead = inputStream.read(buffer)) != -1) {
                                    outputStream.write(buffer, 0, bytesRead);
                                }
                            }

                            outputFile.deleteOnExit();
                            Uri imageUri = FileProvider.getUriForFile(context, context.getPackageName() + ".fileprovider", outputFile);

                            listener.onImageDownloaded(imageUri);
                        } catch (IOException e) {
                            listener.onImageDownloadFailed();
                            e.printStackTrace();
                        } finally {
                            response.close();
                        }
                    }
                }
            );
    }

    interface ImageDownloadListener {
        void onImageDownloaded(Uri imageUri);
        void onImageDownloadFailed();
    }
}
