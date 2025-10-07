const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void
{
    // build options
    const do_strip = b.option(
        bool,
        "strip",
        "Strip the executabes"
    ) orelse false;
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    // libsvc
    const libdrvynvc = myAddStaticLibrary(b, "drvynvc", target, optimize, do_strip);
    libdrvynvc.root_module.root_source_file = b.path("src/libdrvynvc.zig");
    libdrvynvc.linkLibC();
    libdrvynvc.addIncludePath(b.path("../common"));
    libdrvynvc.addIncludePath(b.path("include"));
    libdrvynvc.root_module.addImport("parse", b.createModule(.{
        .root_source_file = b.path("../common/parse.zig"),
    }));
    libdrvynvc.root_module.addImport("hexdump", b.createModule(.{
        .root_source_file = b.path("../common/hexdump.zig"),
    }));
    libdrvynvc.root_module.addImport("strings", b.createModule(.{
        .root_source_file = b.path("../common/strings.zig"),
    }));
    b.installArtifact(libdrvynvc);
}

//*****************************************************************************
fn myAddStaticLibrary(b: *std.Build, name: []const u8,
        target: std.Build.ResolvedTarget,
        optimize: std.builtin.OptimizeMode,
        do_strip: bool) *std.Build.Step.Compile
{
    if ((builtin.zig_version.major == 0) and (builtin.zig_version.minor < 15))
    {
        return b.addStaticLibrary(.{
            .name = name,
            .target = target,
            .optimize = optimize,
            .strip = do_strip,
        });
    }
    return b.addLibrary(.{
        .name = name,
        .root_module = b.addModule(name, .{
            .target = target,
            .optimize = optimize,
            .strip = do_strip,
        }),
        .linkage = .static,
    });
}
