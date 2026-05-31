# 定义依赖提供者

Angular 提供自动和手动两种方式向依赖注入（DI）系统提供依赖。

## 自动提供

提供服务的最常见方式是在 `@Injectable()` 上使用 `providedIn: 'root'`。

### InjectionToken

对于非类依赖（配置对象、函数、原始值），使用 `InjectionToken`。`InjectionToken` 也可以自动提供。

```ts
import {InjectionToken} from '@angular/core';

export interface AppConfig {
  apiUrl: string;
}

export const APP_CONFIG = new InjectionToken<AppConfig>('app.config', {
  providedIn: 'root',
  factory: () => ({apiUrl: 'https://api.example.com'}),
});
```

## 手动提供

当服务缺少 `providedIn`、当你想为特定组件创建新实例、或配置运行时值时，使用 `providers` 数组。

```ts
@Component({
  providers: [
    // 简写形式，等同于 { provide: LocalService, useClass: LocalService }
    LocalService,

    // useClass：替换实现
    {provide: Logger, useClass: BetterLogger},

    // useValue：提供静态值
    {provide: API_URL_TOKEN, useValue: 'https://api.example.com'},

    // useFactory：动态生成值
    {
      provide: ApiClient,
      useFactory: (http = inject(HttpClient)) => new ApiClient(http),
    },

    // useExisting：创建别名
    {provide: OldLogger, useExisting: NewLogger},

    // multi：为同一令牌提供多个值作为数组
    {provide: INTERCEPTOR_TOKEN, useClass: AuthInterceptor, multi: true},
  ],
})
export class Example {}
```

## 提供者作用域

- **应用引导**：全局单例。用于 HTTP 客户端、日志记录或应用级配置。
- **组件/指令**：隔离实例。用于组件特定状态或表单。组件销毁时服务也会被销毁。
- **路由**：仅在特定路由加载的功能特定服务。

## 库模式：`provide*` 函数

库作者应导出返回提供者数组的函数以封装配置：

```ts
export function provideAnalytics(config: AnalyticsConfig): Provider[] {
  return [{provide: ANALYTICS_CONFIG, useValue: config}, AnalyticsService];
}
```
