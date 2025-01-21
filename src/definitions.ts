export interface StashMediaPlugin {
  savePhoto(options: { url: string }): Promise<void>;
  copyPhotoToClipboard(options: { url: string }): Promise<void>;
  shareImage(options: { url: string; title: string }): Promise<void>;
  saveVideo(options: { url: string }): Promise<void>;
}
