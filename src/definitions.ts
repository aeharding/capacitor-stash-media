export interface StashMediaPlugin {
  savePhoto(options: { url: string }): Promise<void>;
  copyPhotoToClipboard(options: { url: string }): Promise<void>;
}
