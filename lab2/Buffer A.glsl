const int KEY_RIGHT  = 65;
const int KEY_UP    = 87;
const int KEY_LEFT = 68;
const int KEY_DOWN  = 83;


struct TankState {
    vec2 pos;   
    float rot;  
};

TankState handleKeyboard(TankState state) {
    float moveSpeed = 4.4;
    float turnSpeed = 1.5;

    float left  = texelFetch(iChannel1, ivec2(KEY_LEFT, 0), 0).x;
    float right = texelFetch(iChannel1, ivec2(KEY_RIGHT,0), 0).x;
    float up    = texelFetch(iChannel1, ivec2(KEY_UP,   0), 0).x;
    float down  = texelFetch(iChannel1, ivec2(KEY_DOWN, 0), 0).x;

    state.rot += (right - left) * turnSpeed * iTimeDelta;

    vec2 forward = vec2(-sin(state.rot), -cos(state.rot));
    state.pos += forward * (up - down) * moveSpeed * iTimeDelta;

    return state;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 prev = texelFetch(iChannel0, ivec2(0, 0), 0);
    TankState state = TankState(prev.xy, prev.z);
    state = handleKeyboard(state);

    // z = поворот
    fragColor = vec4(state.pos, state.rot, 0.0);
}
