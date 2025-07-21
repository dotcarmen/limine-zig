const std = @import("std");

pub fn build(b: *std.Build) void {
    const api_revision = b.option(u32, "api_revision", "Limine API revision to use");
    const allow_deprecated = b.option(bool, "allow_deprecated", "Whether to allow deprecated features");

    const config = b.addOptions();
    config.addOption(u32, "api_revision", api_revision orelse 0);
    config.addOption(bool, "allow_deprecated", allow_deprecated orelse false);

    const module = b.addModule("limine", .{
        .root_source_file = b.path("src/root.zig"),
    });
    module.addImport("config", config.createModule());

    const dist = b.dependency("limine-dist", .{});
    inline for (.{
        "BOOTAA64.EFI",
        "BOOTIA32.EFI",
        "BOOTLOONGARCH64.EFI",
        "BOOTRISCV64.EFI",
        "BOOTX64.EFI",
        "limine-bios-cd.bin",
        "limine-bios-pxe.bin",
        "limine-bios.sys",
        "limine-uefi-cd.bin",
    }) |path| {
        b.addNamedLazyPath(path, dist.path(path));
    }

    const limine_cli = b.addModule("cli", .{
        .link_libc = true,
        .optimize = .ReleaseSafe,
        .target = b.resolveTargetQuery(.{}),
    });
    limine_cli.addCSourceFile(.{
        .file = dist.path("limine.c"),
    });
    limine_cli.addIncludePath(dist.path(""));

    const limine_cli_exe = b.addExecutable(.{
        .name = "limine",
        .root_module = limine_cli,
    });

    b.installArtifact(limine_cli_exe);
}
