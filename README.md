# AOSP on apple silicon (red_byte edition)

Скрипты к статье “Сборка AOSP на MacBook, или Приключения Android-разработчика” на [Хабре](https://habr.com/ru/articles/1107948/):

Сборка AOSP (Android 17) на Mac с Apple Silicon и запуск собственного образа в эмуляторе Android Studio. Бесплатно, без облака и отдельного Linux-компьютера.

## Схема

- AOSP официально собирается только на x86-64 Linux.
- OrbStack поднимает на маке amd64-машину с Ubuntu, x86-код в ней исполняет Rosetta.
- Исходники и сборка находятся внутри машины.
- Готовый arm64-образ эмулятора запускается на маке нативно.

## Проверено

- Ветка `android-latest-release` = `android17-release`, BUILD_ID `CP2A.260605.016`, ноябрь 2026.
- MacBook M5 Max, 18 ядер, 48 ГБ RAM, macOS 26.
- OrbStack, Ubuntu 24.04 (noble) amd64.
- Эмулятор Android Studio 36.5.11.

На других версиях обходы могут не понадобиться или понадобиться другие.

## Требования

| Ресурс | Закладывать | Факт |
|---|---|---|
| Память машины OrbStack | 36 ГБ (столько выделено в проверке) | пик одного процесса 35 ГБ, swap не использовался |
| Диск | 400 ГБ с запасом | занято 240 ГБ: 109 ГБ исходники, 39 ГБ `.repo`, 90 ГБ `out` |
| Сеть | стабильная | `repo sync` скачивает около 125 ГБ |
| Время | ночь | sync 1 ч 06 мин, сборка около 7,5 ч |

Также нужны [OrbStack](https://orbstack.dev) (бесплатен для личного использования) и Android Studio с эмулятором. VirtualBox на Apple Silicon не подходит: он не эмулирует x86.

## Порядок запуска

| № | Где | Скрипт | Что делает |
|---|---|---|---|
| 1 | мак | `scripts/mac-orbstack.sh` | ставит OrbStack, выделяет 36 ГБ, создаёт amd64-машину `aosp`, включает `caffeinate` |
| 2 | машина | `scripts/vm-deps.sh` | ставит пакеты сборки и `repo` |
| 3 | машина | `scripts/vm-sync.sh` | `repo init`, `repo sync`, повтор для упавших репозиториев |
| 4 | машина | `scripts/vm-clang.sh` | клонирует clang отдельно, без истории |
| 5 | машина | `scripts/vm-build-loop.sh` | запускает `vm-build.sh`, перезапускает при коде 133 |
| 6 | мак | `scripts/mac-install-image.sh` | ставит образ в SDK, пишет `package.xml`, создаёт AVD, запускает эмулятор |
| 7 | мак и машина | `scripts/incremental.sh` | пересобирает один модуль и заливает его без перепрошивки |
| 8 | мак | `scripts/art-runtime.sh` | меняет параметры ART для всей системы без пересборки |
| 9 | мак | `scripts/bootanim-gen.main.kts` | рисует кадры и `desc.txt` для своей анимации загрузки (нужны JDK и `kotlin`) |

- Скрипты для машины запускаются внутри неё: `orb -m aosp`.
- Шаги 3, 4 и 5 запускать в `tmux`, команды запуска есть в шапке скриптов.
- Перед запуском прочитайте `mac-orbstack.sh`: он ставит программы и меняет настройки OrbStack.

## Известные проблемы

1. **clang и partial clone.** Checkout `prebuilts/clang/host/linux-x86` падает с “Cannot initialize work tree”. Решение: `scripts/vm-clang.sh`. `prebuilts/tools` и `system/extras` падают с той же ошибкой и проходят при повторном `repo sync`.
2. **nsjail в Android 17.** Переименовывать `nsjail` нельзя: Soong использует файл как исходник тестового модуля. Сборка сама отключает песочницу (“Build sandboxing disabled due to nsjail error”).
3. **siso, код 133.** Под Rosetta siso может упасть с SIGTRAP посреди сборки. Повторный `m` продолжает с того же места. `scripts/vm-build-loop.sh` перезапускает сборку автоматически.
4. **“Missing system image”.** В `sdk-repo-linux-system-images.zip` нет `package.xml`, без него Android Studio и `avdmanager` образ не видят (“Package path is not valid”). `scripts/mac-install-image.sh` создаёт этот файл.
5. **Docker-контекст.** OrbStack при установке делает свой контекст активным. Вернуть прежний: `docker context use colima` (или другой), запретить переключение: `orb config set docker.set_context false`.

## Патчи

| Файл | Куда | Применение |
|---|---|---|
| `patches/service-list-demo.patch` | `frameworks/native` | `git -C frameworks/native apply /путь/к/patches/service-list-demo.patch` |
| `patches/art-heap-defaults.patch` | `device/generic/goldfish` | `git -C device/generic/goldfish apply /путь/к/patches/art-heap-defaults.patch`, затем `m out/target/product/emu64a/vendor/build.prop` |

- `service-list-demo.patch` меняет одну строку вывода `service list`, пример инкрементальной сборки.
- `art-heap-defaults.patch` задаёт значения кучи ART по умолчанию через `PRODUCT_VENDOR_PROPERTIES`.

## tools/ArtInfo.java

Печатает `Runtime.maxMemory()` и `totalMemory()`. Запускается на устройстве через `app_process` и показывает, с какими параметрами кучи стартует ART.

```bash
javac --release 8 ArtInfo.java
d8 --min-api 30 --output . ArtInfo.class      # d8 из build-tools Android SDK
adb push classes.dex /data/local/tmp/artinfo.dex
adb shell CLASSPATH=/data/local/tmp/artinfo.dex app_process / ArtInfo
```

## Удаление

```bash
orb delete aosp                                   # машина вместе с исходниками и out
rm -rf ~/Library/Android/sdk/system-images/aosp-local-17
rm -rf ~/.android/avd/AOSP17_local.avd ~/.android/avd/AOSP17_local.ini
brew uninstall --cask orbstack                    # если OrbStack больше не нужен
```

## Лицензия

MIT, см. [LICENSE](LICENSE).
