const render = @import("../render.zig");
const input = @import("../input.zig");
const time = @import("../time.zig");
pub var cam: *render.Camera = undefined;


pub fn move() void {
    const moveSpeed = time.deltaTime * 5;
    const rotationSpeed = time.deltaTime * 3;

    if (input.getKey(.S)) {
        if (render.getMapTileSafe(cam.position.x - cam.dir.x * moveSpeed, cam.position.y) orelse 0 == 0)
            cam.position.x -= cam.dir.x * moveSpeed;
        if (render.getMapTileSafe(cam.position.x, cam.position.y - cam.dir.y * moveSpeed) orelse 0 == 0)
            cam.position.y -= cam.dir.y * moveSpeed;
    } else if(input.getKey(.W)) {
        if (render.getMapTileSafe(cam.position.x + cam.dir.x * moveSpeed, cam.position.y) orelse 0 == 0)
            cam.position.x += cam.dir.x * moveSpeed;
        if (render.getMapTileSafe(cam.position.x, cam.position.y + cam.dir.y * moveSpeed) orelse 0 == 0)
            cam.position.y += cam.dir.y * moveSpeed;
    }
    if (input.getKey(.D)) {
        const oldDirX = cam.dir.x;
        cam.dir.x = cam.dir.x * @cos(-rotationSpeed) - cam.dir.y * @sin(-rotationSpeed);
        cam.dir.y = oldDirX * @sin(-rotationSpeed) + cam.dir.y * @cos(-rotationSpeed);
        const oldPlaneX = cam.plane.x;
        cam.plane.x = cam.plane.x * @cos(-rotationSpeed) - cam.plane.y * @sin(-rotationSpeed);
        cam.plane.y = oldPlaneX * @sin(-rotationSpeed) + cam.plane.y * @cos(-rotationSpeed);
    } else if(input.getKey(.A)) {
        const oldDirX = cam.dir.x;
        cam.dir.x = cam.dir.x * @cos(rotationSpeed) - cam.dir.y * @sin(rotationSpeed);
        cam.dir.y = oldDirX * @sin(rotationSpeed) + cam.dir.y * @cos(rotationSpeed);

        const oldPlaneX = cam.plane.x;
        cam.plane.x = cam.plane.x * @cos(rotationSpeed) - cam.plane.y * @sin(rotationSpeed);
        cam.plane.y = oldPlaneX * @sin(rotationSpeed) + cam.plane.y * @cos(rotationSpeed);
    }
}

pub fn update() void {
    move();

}
