export interface BlufiPlugin {
  echo(options: { value: string }): Promise<{ value: string }>;
}
