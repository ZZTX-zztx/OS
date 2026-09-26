# Nova-OS

Nova-OS is a tiny x86 BIOS operating-system starter written in NASM assembly.

## Build

From the repository root:

```bat
os\build.bat
```

The disk image is written to `os\build\nova-os.img`.

## Run in QEMU

```bat
os\run.bat
```

QEMU 使用标准显卡并开启窗口自适应缩放；调整 QEMU 窗口大小时，80×25 文本画面会保持比例显示。

在命令提示符输入 `exit` 会依次尝试 APM、常见的 ACPI PM1a/PM1b 端口
（如 `0x604`、`0xB004`、`0xB006`）以及 QEMU 的 `isa-debug-exit` 设备。
这能覆盖很多 BIOS/虚拟机，但它仍不能保证“所有真实 PC 都能在 USB/WinToGo
启动下真正断电”：如果固件不提供 APM/ACPI 电源管理，16 位代码无法强制关机，
最终只能停机等待 BIOS 处理。要覆盖所有真机，需要从 BIOS 的 FADT 中读取
真正的 PM1a_CNT 和 SLP_TYP，而不仅仅依赖固定端口。 

The first stage displays the `NOVA-OS` banner and provides a small keyboard echo prompt. This is the foundation for adding a protected-mode kernel, interrupt handlers, memory management, and filesystem support.
