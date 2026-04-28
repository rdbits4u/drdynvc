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
    const libdrdynvc = myAddStaticLibrary(b, "drdynvc", target, optimize, do_strip);
    libdrdynvc.root_module.root_source_file = b.path("src/libdrdynvc.zig");
    myLinkLibC(libdrdynvc);
    myAddIncludePath(libdrdynvc, b.path("../common"));
    myAddIncludePath(libdrdynvc, b.path("include"));
    libdrdynvc.root_module.addImport("parse", b.createModule(.{
        .root_source_file = b.path("../common/parse.zig"),
    }));
    libdrdynvc.root_module.addImport("hexdump", b.createModule(.{
        .root_source_file = b.path("../common/hexdump.zig"),
    }));
    libdrdynvc.root_module.addImport("strings", b.createModule(.{
        .root_source_file = b.path("../common/strings.zig"),
    }));
    b.installArtifact(libdrdynvc);
}

//*****************************************************************************
fn myLinkLibC(compile: *std.Build.Step.Compile) void
{
    if ((builtin.zig_version.major == 0) and (builtin.zig_version.minor < 16))
    {
        compile.linkLibC();
    }
    else
    {
        compile.root_module.link_libc = true;
    }
}

//*****************************************************************************
fn myAddIncludePath(compile: *std.Build.Step.Compile, lazy_path: std.Build.LazyPath) void
{
    if ((builtin.zig_version.major == 0) and (builtin.zig_version.minor < 16))
    {
        compile.addIncludePath(lazy_path);
    }
    else
    {
        compile.root_module.addIncludePath(lazy_path);
    }
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
