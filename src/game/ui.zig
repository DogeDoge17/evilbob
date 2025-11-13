const img = @import("../image.zig");
const draw = @import("../draw.zig");
const input = @import("../input.zig");
const math = @import("../math.zig");

pub const Element = struct {
    texture: img.Assets,
    hoverTexture: img.Assets = undefined,
    pos: math.Vector2(usize),
    width: usize,
    height: usize,

    pub fn clicked(self: *const @This()) bool {
        return self.hovered() and input.getMouseDown(.Btn1);
    }

    pub inline fn hovered(self: *const @This()) bool {
        return self.aabb(input.getMouseXA(usize), input.getMouseYA(usize));
    }

    pub fn render(self: * const @This()) void {
        draw.blit(img.getImage(self.texture).?, 0xFFFFFFFF, self.pos.x, self.pos.y, self.width, self.height);
    }

    fn aabb(self: *const @This(), x: usize, y: usize) bool {
        return x >= self.pos.x 
            and x <= self.pos.x + self.width
            and y >= self.pos.y
            and y <= self.pos.y + self.height;
    }
};
