mat3 rotateX(float theta) {
    float c = cos(theta), s = sin(theta);
    return mat3(
        vec3(1,0,0),
        vec3(0,c,-s),
        vec3(0,s,c)
    );
}
mat3 rotateY(float theta) {
    float c = cos(theta), s = sin(theta);
    return mat3(
        vec3(c,0,s),
        vec3(0,1,0),
        vec3(-s,0,c)
    );
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    ivec2 uv = ivec2(fragCoord);

    vec4 prevBullet    = texelFetch(iChannel3, ivec2(0,0), 0); // active
    vec4 prevBulletDir = texelFetch(iChannel3, ivec2(1,0), 0); // speed
    vec4 prevExplosion = texelFetch(iChannel3, ivec2(3,0), 0); // power
    vec4 prevSpaceFlag = texelFetch(iChannel3, ivec2(4,0), 0); // di
    vec4 prevEnemy     = texelFetch(iChannel3, ivec2(2,0), 0); // alive
    vec4 prevEnemy2     = texelFetch(iChannel3, ivec2(5,0), 0); // alive

    vec4 player = texelFetch(iChannel0, ivec2(0,0), 0); 
    vec4 ch1 = texelFetch(iChannel1, ivec2(0,0), 0);    
    vec4 ch2 = texelFetch(iChannel2, ivec2(0,0), 0);   
    vec4 ch0 = vec4(player.xy, 0.0, 0.0);          

    vec2 aim = vec2(0.0);
    if (length(ch1.xy) > 1e-5) {
        aim = ch1.xy;
    } else if (length(ch2.xy) > 1e-5) {
        aim = ch2.xy;
    } else {
        aim = ch0.xy;
    }

    bool nowSpace = (ch1.z > 0.5) || (ch2.z > 0.5) || (ch0.z > 0.5);

    vec4 bullet = prevBullet;
    vec4 bulletDir = prevBulletDir;
    vec4 enemy = prevEnemy;
    vec4 enemy2 = prevEnemy2;
    vec4 explosion = prevExplosion;

    if (iFrame < 3 && enemy.w < 0.5) {
        enemy = vec4(8.0, 0.0, -40.0, 1.0); 
        enemy2 = vec4(16.0, 0.0, -20.0, 1.0); 
    }

    vec3 tankCenter = vec3(player.x, 0.0, player.y - 6.0);
    float playerRot = player.z;
    mat3 rotTank = rotateY(-playerRot);

    vec3 duloBaseLocal = vec3(0.0, 1.55, 1.25);      
    vec3 duloDirLocal  = vec3(0.0, 0.25, -2.9);    

    duloDirLocal *= rotateX(-aim.y);
    duloDirLocal *= rotateY(-aim.x);

    vec3 duloTipLocal = duloBaseLocal + duloDirLocal;

    vec3 duloTipWorld = tankCenter + rotTank * duloTipLocal;
    vec3 duloDirWorld = normalize(rotTank * duloDirLocal); // направление в мире

    if (bullet.w < 0.5 && nowSpace) {
        bullet = vec4(duloTipWorld + duloDirWorld * 0.25, 1.0); // чуть вперед от кончика
        bulletDir = vec4(duloDirWorld, 80.0); // скорость = 80 (подбери)
    }

    if (bullet.w > 0.5) {
        bullet.xyz += bulletDir.xyz * (bulletDir.w * iTimeDelta);
        if (length(bullet.xyz - tankCenter) > 100.0) bullet.w = 0.0;
    }
    
    if (bullet.w > 0.5 && bullet.y <= 0.){
        bullet.w = 0.0;
        explosion = vec4(bullet.xyz, 1.0);
    }

    if (bullet.w > 0.5 && enemy.w > 0.5) {
        float dist = length(bullet.xyz - enemy.xyz);
        if (dist < 1.8) { 
            bullet.w = 0.0;
            enemy.w = 0.0; 
            explosion = vec4(enemy.xyz, 1.0);
        }
    }
    
    if (bullet.w > 0.5 && enemy2.w > 0.5) {
        float dist = length(bullet.xyz - enemy2.xyz);
        if (dist < 1.8) { 
            bullet.w = 0.0;
            enemy2.w = 0.0; 
            explosion = vec4(enemy2.xyz, 1.0);
        }
    }

    if (explosion.w > 0.0) {
        explosion.w *= pow(0.92, iTimeDelta * 60.0);
        if (explosion.w < 0.0005) explosion.w = 0.0;
    }

    prevSpaceFlag.x = nowSpace ? 1.0 : 0.0;

    vec4 outc = texelFetch(iChannel3, uv, 0); 
    if (uv == ivec2(0,0)) outc = bullet;
    else if (uv == ivec2(1,0)) outc = bulletDir;
    else if (uv == ivec2(2,0)) outc = enemy;
    else if (uv == ivec2(3,0)) outc = explosion;
    else if (uv == ivec2(4,0)) outc = prevSpaceFlag;
    else if (uv == ivec2(5,0)) outc = enemy2;

    fragColor = outc;
}
