# 创建和使用服务

Angular 中的服务是可复用的代码片段，处理多个组件或其他服务需要访问的数据获取、业务逻辑或状态管理。

## 创建服务

你可以使用 Angular CLI 生成服务：

```bash
ng generate service my-data
```

或者手动创建一个 TypeScript 类并使用 `@Injectable()` 装饰器。

```ts
import {Injectable} from '@angular/core';

@Injectable({
  providedIn: 'root',
})
export class BasicDataStore {
  private data: string[] = [];

  addData(item: string): void {
    this.data.push(item);
  }

  getData(): string[] {
    return [...this.data];
  }
}
```

### `providedIn: 'root'` 选项

使用 `providedIn: 'root'` 是大多数服务的推荐方式。它告诉 Angular：

- **创建单个实例（单例）**供整个应用使用。
- **使其自动到处可用**，无需在任何 `providers` 数组中列出。
- **启用摇树优化**，即服务仅在实际被注入某处时才会包含在最终的 JavaScript 包中。

## 注入服务

服务创建后，你可以使用 `inject()` 函数将其注入到组件、指令或其他服务中。

### 注入到组件中

```ts
import {Component, inject} from '@angular/core';
import {BasicDataStore} from './basic-data-store.service';

@Component({
  selector: 'app-example',
  template: `
    <div>
      <p>Data items: {{ dataStore.getData().length }}</p>
      <button (click)="dataStore.addData('New Item')">Add Item</button>
    </div>
  `,
})
export class Example {
  // 将服务注入为类字段
  dataStore = inject(BasicDataStore);
}
```

### 注入到另一个服务中

服务可以以完全相同的方式注入其他服务。

```ts
import {Injectable, inject} from '@angular/core';
import {AdvancedDataStore} from './advanced-data-store.service';

@Injectable({
  providedIn: 'root',
})
export class BasicDataStore {
  // 注入另一个服务
  private advancedDataStore = inject(AdvancedDataStore);

  private data: string[] = [];

  getData(): string[] {
    // 合并此服务和注入服务的数据
    return [...this.data, ...this.advancedDataStore.getData()];
  }
}
```

## 高级服务模式

虽然 `providedIn: 'root'` 覆盖了大多数场景，但有时你可能需要：

- **组件特定实例**：如果组件需要自己独立的服务实例，直接在组件的 `@Component({ providers: [MyService] })` 数组中提供。
- **工厂提供者**：用于动态创建。
- **值提供者**：用于注入配置对象。
