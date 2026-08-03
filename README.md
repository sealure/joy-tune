# JoyTune

JoyTune悦听，一款极简音乐播放器

## 快速开始

```bash
# 获取依赖
flutter pub get

# 生成 Isar 模型代码
dart run build_runner build

# 启动
flutter run
```

## 技术栈

| 层 | 选型 |
|----|------|
| 框架 | Flutter (Dart 3) |
| 音频 | just_audio |
| 网络 | dio |
| 数据库 | isar |
| 状态管理 | riverpod |
| 路由 | go_router |

## 目录结构

```
apps/via-music/
├── lib/
│   ├── api/           # GD Music API 封装
│   ├── models/        # 数据模型
│   ├── db/            # 本地数据库
│   ├── repositories/  # Repository 抽象层
│   ├── services/      # 业务服务
│   ├── screens/       # 页面
│   ├── widgets/       # 组件
│   └── theme/         # 主题
├── android/
├── ios/
├── macos/
├── windows/
├── linux/
└── pubspec.yaml
```

## 设计文档

- [播放器设计文档](docs/AlgerMusicPlayer/simple-player-design.md)
- [GD Music API 接口参考](docs/AlgerMusicPlayer/gdmusic-api-reference.md)
