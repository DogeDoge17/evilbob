const img = @import("../image.zig");
const draw = @import("../draw.zig");
const input = @import("../input.zig");

pub const Element = struct {
    texture: img.Image,
    hoverTexture: *img.Image = undefined,
    x: usize,
    y: usize,
    width: usize,
    height: usize,

    pub fn clicked(self: *const @This()) bool {
        return self.hovered() and input.getMouseDown(.Btn0);
    }

    pub inline fn hovered(self: *const @This()) bool {
        return self.aabb(input.getMouseXA(usize), input.getMouseYA(usize));
    }

    pub fn render(self: * const @This()) void {
        draw.blit(&self.texture, self.x, self.y, self.width, self.height);
    }

    fn aabb(self: *const @This(), x: usize, y: usize) bool {
        return x >= self.x 
            and x <= self.x + self.width
            and y >= self.y
            and y <= self.y + self.height;
    }
};
