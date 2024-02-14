const std = @import("std");
const config = @import("config");
const memory = @import("../memory.zig");
const isa = @import("../isa/riscv32.zig");
const sdb = @import("sdb.zig");
const util = @import("../util.zig");

var img_file: ?[]const u8 = null;

pub fn init_monitor() void {
    // Parse arguments.
    parse_args();

    // Initialize memory.
    memory.init_mem();

    // Perform ISA dependent initialization.
    isa.init_isa();

    // Load the image to memory. This will overwrite the built-in image.
    const img_size = load_img();
    _ = img_size;

    // Initialize the simple debugger.
    sdb.init_sdb();

    // Display welcome message.
    welcome();
}

pub fn deinit_monitor() void {
    sdb.deinit_sdb();
}

fn parse_args() void {
    if (std.os.argv.len >= 2) {
        img_file = std.mem.span(std.os.argv[1]);
    }
}

fn load_img() usize {
    if (img_file == null) {
        util.log(@src(), "No image is given. Use the default build-in image.\n", .{});
        return 4096; // built-in image size
    }

    const file = std.fs.cwd().openFile(img_file.?, .{ .mode = .read_only }) catch {
        util.panic("Can not open {s}\n", .{img_file.?});
    };
    defer file.close();

    const size = file.getEndPos() catch {
        util.panic("Can not get size of {s}\n", .{img_file.?});
    };
    util.log(@src(), "The image is {s}, size = {d}\n", .{ img_file.?, size });

    _ = file.readAll(memory.pmem[memory.reset_offset..]) catch {
        util.panic("Can not read {s}\n", .{img_file.?});
    };

    return size;
}

fn welcome() void {
    std.debug.print("Welcome to {s}-NEMU in Zig!\n", .{util.ansi_fmt(config.ISA, util.AnsiColor.fg_yellow, util.AnsiColor.bg_red)});
    std.debug.print("For help, type \"help\".\n", .{});
}
