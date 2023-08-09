export interface StashMediaPlugin {
  echo(options: { value: string }): Promise<{ value: string }>;
}
