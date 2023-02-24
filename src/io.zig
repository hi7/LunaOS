const std = @import("std");
const uefi = std.os.uefi;
const Status = uefi.Status;
const unicode = std.unicode;
const print = @import("print.zig");
const SimpleTextOutputProtocol = uefi.protocols.SimpleTextOutputProtocol;
const BlockIoProtocol = uefi.protocols.BlockIoProtocol;
const BootServices = uefi.tables.BootServices;

pub const minLba: u64 = 10;
var blockIo: *BlockIoProtocol = undefined;
var mediaId: u32 = undefined;
var blockSize: usize = undefined;
pub const IOError = error {
    NoBlockIoProtocolFound,
    ReadBlockFailed,
};
pub fn init(boot_services: *BootServices) !usize {
    var blockIoProtocol: ?*BlockIoProtocol = undefined;
    if(boot_services.locateProtocol(&BlockIoProtocol.guid, null, @ptrCast(*?*anyopaque, &blockIoProtocol)) == Status.Success) {
        blockSize = blockIoProtocol.?.media.block_size;
        mediaId = blockIoProtocol.?.media.media_id;

        var handleCount: usize = undefined;
        var handles: [*]uefi.Handle = undefined;
        const ByProtocol = uefi.tables.LocateSearchType.ByProtocol;
        const statusHandle = boot_services.locateHandleBuffer(ByProtocol, &BlockIoProtocol.guid, null, &handleCount, &handles);
        if(statusHandle == Status.Success) {
            if(handleCount > 0) {
                blockIo = try boot_services.openProtocolSt(BlockIoProtocol, handles[0]);
            } else {
                return IOError.NoBlockIoProtocolFound;
            }
        } else {
            return IOError.NoBlockIoProtocolFound;
        }
    } else {
        return IOError.NoBlockIoProtocolFound;
    }
    return blockSize;
}

pub fn readBlock(lba: u64, buffer_size: usize, buf: [*]u8) !void {
    var b = buf;
    if(blockIo.readBlocks(mediaId, lba, buffer_size, b) == Status.Success) {
    } else {
        return IOError.ReadBlockFailed;
    }
}
