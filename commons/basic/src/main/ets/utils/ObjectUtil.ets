export declare interface ObjectOption<T> extends Record<string, T | undefined> {}

export class ObjectUtil<T> {
  private options: ObjectOption<T>;

  constructor(option: ObjectOption<T>) {
    this.options = option;
  }

  getValue(currentPoint: string): T {
    return this.options[currentPoint] as T;
  }

  setValue(currentPoint: string, value: T): void {
    this.options[currentPoint] = value
  }
}