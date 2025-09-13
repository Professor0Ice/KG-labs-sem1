const int KEY_LEFT  = 37;
const int KEY_RIGHT = 39;
const float velocity = 0.8; 
const float limit = 0.18;

vec2 handleKeyboard(vec2 offset) {

    // проверка клавишь 0,1 и ivec - инт век
    vec2 left = texelFetch(iChannel1, ivec2(KEY_LEFT, 0), 0).x * vec2(-1, -1);
    vec2 right = texelFetch(iChannel1, ivec2(KEY_RIGHT, 0), 0).x * vec2(1, 1);

    offset += (left + right) * velocity * iTimeDelta;

    return offset;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 offset = texelFetch( iChannel0, ivec2(0, 0), 0).xy; //Возвращает значение смещения от последнего кадра

    offset.y = 0.; // обнуляем аним поворота
    
    offset = handleKeyboard(offset);
    
    if(offset.x < 0.) {offset.x = 0.;}
    if(offset.x > 1.) {offset.x = 1.;}
    
    if(offset.y > 0.) {offset.y = 1.;}
    if(offset.y < 0.) {offset.y = -1.;}

    fragColor = vec4(offset, 0, 0);
}