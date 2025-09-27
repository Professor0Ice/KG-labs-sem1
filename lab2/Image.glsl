const int MAX_MARCHING_STEPS = 255; //шаг луча
const float MIN_DIST = 0.01; //мин. дистанция прорисовки
const float MAX_DIST = 100.0; //макс. дистанция прор. - после неё задний фон
const float PRECISION = 0.0001; //точность самого луча (до объекта)

struct Surface {
  float dist;
  vec3 color;
};

// Rotation matrix around the X axis.
mat3 rotateX(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3(
        vec3(1, 0, 0),
        vec3(0, c, -s),
        vec3(0, s, c)
    );
}

// Rotation matrix around the Y axis.
mat3 rotateY(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3(
        vec3(c, 0, s),
        vec3(0, 1, 0),
        vec3(-s, 0, c)
    );
}

// Rotation matrix around the Z axis.
mat3 rotateZ(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3(
        vec3(c, -s, 0),
        vec3(s, c, 0),
        vec3(0, 0, 1)
    );
}

// Identity matrix.
mat3 identity() {
    return mat3(
        vec3(1, 0, 0),
        vec3(0, 1, 0),
        vec3(0, 0, 1)
    );
}

Surface opU( Surface d1, Surface d2 )
{
    if (d1.dist <= d2.dist){
        return d1;
    }
    return d2;
}

float sdLink( vec3 p, float le, float r1, float r2 )
{
  vec3 q = vec3( p.x, max(abs(p.y)-le,0.0), p.z );
  return length(vec2(length(q.xy)-r1,q.z)) - r2;
}

float sdRoundedCylinder( vec3 p, float ra, float rb, float h )
{
  vec2 d = vec2( length(p.xz)-2.0*ra+rb, abs(p.y) - h );
  return min(max(d.x,d.y),0.0) + length(max(d,0.0)) - rb;
}

Surface sdBox( vec3 p, vec3 b, vec3 col )
{
  vec3 q = abs(p) - b;
  float d = length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
  return Surface(d,col);
}

float sdRectangle( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  float d = length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
  return d;
}

float sdCylinder(vec3 p, vec3 a, vec3 b, float r)
{
    vec3  ba = b - a;
    vec3  pa = p - a;
    float baba = dot(ba,ba);
    float paba = dot(pa,ba);
    float x = length(pa*baba-ba*paba) - r*baba;
    float y = abs(paba-baba*0.5)-baba*0.5;
    float x2 = x*x;
    float y2 = y*y*baba;
    
    float d = (max(x,y)<0.0)?-min(x2,y2):(((x>0.0)?x2:0.0)+((y>0.0)?y2:0.0));
    
    return sign(d)*sqrt(abs(d))/baba;
}

Surface sdPlayer(vec3 p)
{
  Surface s;
  
  vec3 tankCenter = vec3(0.,0.,-6.);
  
  vec3 state = texelFetch(iChannel0, ivec2(0,0),0).xyz;
  
  tankCenter += vec3(state.x, 0.0, state.y);
  float angle = state.z;

  vec3 localPos = p - tankCenter;

  localPos = rotateY(angle) * localPos;
  vec3 offset = localPos;
  
  vec3 tankColor = vec3(0.6,0.7,0.);
  
  // Колёся и гусиницы
  vec3 wheelColor = vec3(1. + 0.5*mod(floor(p.x*40.) + floor(p.z*40.), 2.)) * vec3(0.42,0.42,0.42);
  vec3 gooseColor = vec3(1. + 0.4*mod(floor(p.x*7.) + floor(p.z*7.), 2.)) * vec3(0.2,0.2,0.2);
  
  Surface goose;
  goose.dist = sdLink(offset*rotateZ(radians(90.))*rotateX(radians(90.))+vec3(0.56,0.,-1.3),2., 0.42, 0.1);
  goose.color = gooseColor;
  s = goose;
  
  goose.dist = sdLink(offset*rotateZ(radians(90.))*rotateX(radians(90.))+vec3(0.56,0.,1.3),2., 0.42, 0.1);
  goose.color = gooseColor;
  s = opU(s, goose);
  
  Surface wheel;
  wheel.dist = sdRoundedCylinder(offset*rotateX(radians(90.))*rotateZ(radians(90.))+vec3(0.,-1.3,-0.55),0.2, 0.2, 0.01);
  wheel.color = wheelColor;
  s = opU(s, wheel);
  wheel.dist = sdRoundedCylinder(offset*rotateX(radians(90.))*rotateZ(radians(90.))+vec3(0.95,-1.3,-0.55),0.2, 0.2, 0.01);
  wheel.color = wheelColor;
  s = opU(s, wheel);
  wheel.dist = sdRoundedCylinder(offset*rotateX(radians(90.))*rotateZ(radians(90.))+vec3(1.9,-1.3,-0.55),0.2, 0.2, 0.01);
  wheel.color = wheelColor;
  s = opU(s, wheel);
  wheel.dist = sdRoundedCylinder(offset*rotateX(radians(90.))*rotateZ(radians(90.))+vec3(-0.95,-1.3,-0.55),0.2, 0.2, 0.01);
  wheel.color = wheelColor;
  s = opU(s, wheel);
  wheel.dist = sdRoundedCylinder(offset*rotateX(radians(90.))*rotateZ(radians(90.))+vec3(-1.9,-1.3,-0.55),0.2, 0.2, 0.01);
  wheel.color = wheelColor;
  s = opU(s, wheel);
  
  wheel.dist = sdRoundedCylinder(offset*rotateX(radians(90.))*rotateZ(radians(90.))+vec3(0.,1.3,-0.55),0.2, 0.2, 0.01);
  wheel.color = wheelColor;
  s = opU(s, wheel);
  wheel.dist = sdRoundedCylinder(offset*rotateX(radians(90.))*rotateZ(radians(90.))+vec3(0.95,1.3,-0.55),0.2, 0.2, 0.01);
  wheel.color = wheelColor;
  s = opU(s, wheel);
  wheel.dist = sdRoundedCylinder(offset*rotateX(radians(90.))*rotateZ(radians(90.))+vec3(1.9,1.3,-0.55),0.2, 0.2, 0.01);
  wheel.color = wheelColor;
  s = opU(s, wheel);
  wheel.dist = sdRoundedCylinder(offset*rotateX(radians(90.))*rotateZ(radians(90.))+vec3(-0.95,1.3,-0.55),0.2, 0.2, 0.01);
  wheel.color = wheelColor;
  s = opU(s, wheel);
  wheel.dist = sdRoundedCylinder(offset*rotateX(radians(90.))*rotateZ(radians(90.))+vec3(-1.9,1.3,-0.55),0.2, 0.2, 0.01);
  wheel.color = wheelColor;
  s = opU(s, wheel);
  
  //Корпус такнка
  
  Surface tank;
  tank.dist = sdRectangle(offset - vec3(0.,0.63,0.0), vec3(1.3,0.37,2.53));
  tank.color = tankColor;
  s = opU(s, tank);
  tank.dist = sdRectangle(offset - vec3(0.,1.0,0.0), vec3(1.3,0.2,2.4));
  tank.color = tankColor;
  s = opU(s, tank);
  tank.dist = sdRectangle(offset - vec3(0.,1.1,0.0), vec3(1.15,0.17,2.2));
  tank.color = tankColor;
  s = opU(s, tank);
  
  tank.dist = sdRectangle(offset - vec3(0.,1.33,1.), vec3(0.93,0.17,0.95));
  tank.color = tankColor;
  s = opU(s, tank);
  tank.dist = sdRectangle(offset - vec3(0.,1.15,-1.), vec3(0.98,0.17,1.));
  tank.color = tankColor;
  s = opU(s, tank);
  
  tank.dist = sdRectangle(offset - vec3(0.,2.27,1.), vec3(0.6,.15,0.6));
  tank.color = tankColor;
  s = opU(s, tank);
  
  tank.dist = sdRoundedCylinder(offset-vec3(0.,1.5,1.),.45, .45, .4);
  tank.color = tankColor;
  s = opU(s, tank);
  
  //дуло
  Surface dulo;
  vec3 keyboard = texelFetch(iChannel1, ivec2(0,0),0).xyz;
  vec3 directionDulo = vec3(0.,0.25,-2.9);
  directionDulo *= rotateX(-keyboard.y);
  directionDulo *= rotateY(-keyboard.x);
  dulo.dist = sdCylinder(offset-vec3(0.,1.55,1.25), vec3(0.,0.25,-0.3), directionDulo, 0.15);
  dulo.color = tankColor;
  s = opU(s, dulo);
    
  return s;
}

Surface sdEnemy(vec3 p, vec3 tankCenter, float angle)
{
  Surface s;

  vec3 localPos = p - tankCenter;
  localPos = rotateY(angle) * localPos;
  vec3 offset = localPos;

  vec3 tankColor = vec3(0.8,0.0,0.);
  vec3 wheelColor = vec3(1. + 0.5*mod(floor(p.x*40.) + floor(p.z*40.), 2.)) * vec3(0.42,0.42,0.42);
  vec3 gooseColor = vec3(1. + 0.4*mod(floor(p.x*7.) + floor(p.z*7.), 2.)) * vec3(0.2,0.2,0.2);

  Surface goose;
  goose.dist = sdLink(offset*rotateZ(radians(90.))*rotateX(radians(90.))+vec3(0.56,0.,-1.3),2., 0.42, 0.1);
  goose.color = gooseColor;
  s = goose;

  goose.dist = sdLink(offset*rotateZ(radians(90.))*rotateX(radians(90.))+vec3(0.56,0.,1.3),2., 0.42, 0.1);
  goose.color = gooseColor;
  s = opU(s, goose);

  Surface wheel;
  wheel.dist = sdRoundedCylinder(offset*rotateX(radians(90.))*rotateZ(radians(90.))+vec3(0.,-1.3,-0.55),0.2, 0.2, 0.01);
  wheel.color = wheelColor;
  s = opU(s, wheel);
  wheel.dist = sdRoundedCylinder(offset*rotateX(radians(90.))*rotateZ(radians(90.))+vec3(0.95,-1.3,-0.55),0.2, 0.2, 0.01);
  wheel.color = wheelColor;
  s = opU(s, wheel);
  wheel.dist = sdRoundedCylinder(offset*rotateX(radians(90.))*rotateZ(radians(90.))+vec3(1.9,-1.3,-0.55),0.2, 0.2, 0.01);
  wheel.color = wheelColor;
  s = opU(s, wheel);
  wheel.dist = sdRoundedCylinder(offset*rotateX(radians(90.))*rotateZ(radians(90.))+vec3(-0.95,-1.3,-0.55),0.2, 0.2, 0.01);
  wheel.color = wheelColor;
  s = opU(s, wheel);
  wheel.dist = sdRoundedCylinder(offset*rotateX(radians(90.))*rotateZ(radians(90.))+vec3(-1.9,-1.3,-0.55),0.2, 0.2, 0.01);
  wheel.color = wheelColor;
  s = opU(s, wheel);

  wheel.dist = sdRoundedCylinder(offset*rotateX(radians(90.))*rotateZ(radians(90.))+vec3(0.,1.3,-0.55),0.2, 0.2, 0.01);
  wheel.color = wheelColor;
  s = opU(s, wheel);
  wheel.dist = sdRoundedCylinder(offset*rotateX(radians(90.))*rotateZ(radians(90.))+vec3(0.95,1.3,-0.55),0.2, 0.2, 0.01);
  wheel.color = wheelColor;
  s = opU(s, wheel);
  wheel.dist = sdRoundedCylinder(offset*rotateX(radians(90.))*rotateZ(radians(90.))+vec3(1.9,1.3,-0.55),0.2, 0.2, 0.01);
  wheel.color = wheelColor;
  s = opU(s, wheel);
  wheel.dist = sdRoundedCylinder(offset*rotateX(radians(90.))*rotateZ(radians(90.))+vec3(-0.95,1.3,-0.55),0.2, 0.2, 0.01);
  wheel.color = wheelColor;
  s = opU(s, wheel);
  wheel.dist = sdRoundedCylinder(offset*rotateX(radians(90.))*rotateZ(radians(90.))+vec3(-1.9,1.3,-0.55),0.2, 0.2, 0.01);
  wheel.color = wheelColor;
  s = opU(s, wheel);

  // Корпус
  Surface tank;
  tank.dist = sdRectangle(offset - vec3(0.,0.63,0.0), vec3(1.3,0.37,2.53));
  tank.color = tankColor;
  s = opU(s, tank);
  tank.dist = sdRectangle(offset - vec3(0.,1.0,0.0), vec3(1.3,0.2,2.4));
  tank.color = tankColor;
  s = opU(s, tank);
  tank.dist = sdRectangle(offset - vec3(0.,1.1,0.0), vec3(1.15,0.17,2.2));
  tank.color = tankColor;
  s = opU(s, tank);

  tank.dist = sdRectangle(offset - vec3(0.,1.33,1.), vec3(0.93,0.17,0.95));
  tank.color = tankColor;
  s = opU(s, tank);
  tank.dist = sdRectangle(offset - vec3(0.,1.15,-1.), vec3(0.98,0.17,1.));
  tank.color = tankColor;
  s = opU(s, tank);

  tank.dist = sdRectangle(offset - vec3(0.,2.27,1.), vec3(0.6,.15,0.6));
  tank.color = tankColor;
  s = opU(s, tank);

  tank.dist = sdRoundedCylinder(offset-vec3(0.,1.5,1.),.45, .45, .4);
  tank.color = tankColor;
  s = opU(s, tank);

  // Дуло — для врага не даём управление клавой, просто статично
  Surface dulo;
  vec3 directionDulo = vec3(0.,0.25,-2.9); // локально направлено вперёд танка
  dulo.dist = sdCylinder(offset-vec3(0.,1.55,1.25), vec3(0.,0.25,-0.3), directionDulo, 0.15);
  dulo.color = tankColor;
  s = opU(s, dulo);

  return s;
}

float noise(vec2 st) { return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123); }

Surface sdFloor(vec3 p, float h)
{
  float baseplane = p.y;
  float frequency = 0.05;
  float amplitude = 0.2; 

  vec2 coord = p.xz * frequency;
  float height = noise(coord) * amplitude;
    
  vec3 col = vec3(0.0,0.5,0.0);
  return Surface(baseplane - height - 0.3, col);
}

Surface sdScene(vec3 p) 
{
    Surface o;

    // Игрок
    Surface Player = sdPlayer(p);
    
    // Пол
    Surface objF = sdFloor(p,0.);


    o = opU(Player, objF);

    vec4 bullet = texelFetch(iChannel3, ivec2(0,0), 0);
    vec4 bulletDir = texelFetch(iChannel3, ivec2(1,0), 0);
    vec4 enemy = texelFetch(iChannel3, ivec2(2,0), 0);
    vec4 enemy2 = texelFetch(iChannel3, ivec2(5,0), 0);
    vec4 explosion = texelFetch(iChannel3, ivec2(3,0), 0);

    if (enemy.w > 0.5) {
        Surface EnemyTank = sdEnemy(p, enemy.xyz, 0.0); // угол можно хранить в другом элементе, если нужно
        o = opU(o, EnemyTank);
    }
    
    if (enemy2.w > 0.5) {
        Surface EnemyTank = sdEnemy(p, enemy2.xyz, 0.0); // угол можно хранить в другом элементе, если нужно
        o = opU(o, EnemyTank);
    }

    if (bullet.w > 0.5) {
        Surface b;
        b.dist = length(p - bullet.xyz) - 0.25;
        b.color = vec3(1.0, 0.2, 0.05);
        o = opU(o, b);
    }


    if (enemy.w > 0.5) {
        Surface EnemyTank = sdEnemy(p, enemy.xyz, 0.0); // угол можно хранить в другом элементе, если нужно
        o = opU(o, EnemyTank);
    }

    if (bullet.w > 0.5) {
        Surface b;
        b.dist = length(p - bullet.xyz) - 0.25;
        b.color = vec3(1.0, 0.2, 0.05);
        o = opU(o, b);
    }
    
    return o;
}


float rayMarch(vec3 ro, vec3 rd, float start, float end) { //ro - начало луча, rd - направление луча.
  float depth = start;

  for (int i = 0; i < MAX_MARCHING_STEPS; i++) {
    vec3 p = ro + depth * rd;
    float d = sdScene(p).dist;
    depth += d;
    if (d < PRECISION || depth > end) { break; }
  }

  return depth;
}

vec3 calcNormal(vec3 p, float r) { // освещение Ламберта
    vec2 e = vec2(1.0, -1.0) * 0.0005; // я хз что это, но для формулы надо
    return normalize( e.xyy * sdScene(p + e.xyy).dist + e.yyx * sdScene(p + e.yyx).dist +
      e.yxy * sdScene(p + e.yxy).dist + e.xxx * sdScene(p + e.xxx).dist);
}

vec3 DrawScene(vec2 uv) {
    vec3 backgroundColor = vec3(0.83, 1, 1);
    vec3 col = vec3(0);

    vec3 state = texelFetch(iChannel0, ivec2(0,0),0).xyz; 
    vec3 tankCenter = vec3(state.x, 0., state.y - 6.);

    float rotY = texelFetch(iChannel2, ivec2(0,0),0).x;
    mat3 rot = rotateY(rotY);

    vec3 offsetCam = vec3(0., 4., 6.);

    vec3 ro = tankCenter + rot * offsetCam;

    vec3 tankForward = rot * vec3(0.0, 0.0, -1.0);
    vec3 target = tankCenter + tankForward * 4.0; 

    vec3 forward = normalize(target - ro); 
    vec3 up = vec3(0.0, 1., 0.0);            
    vec3 right = normalize(cross(forward, up));  
    up = cross(right, forward);          

    float fov = 1.0; 
    vec3 rd = normalize(forward + uv.x * right * fov + uv.y * up * fov);

    float d = rayMarch(ro, rd, MIN_DIST, MAX_DIST);

    if (d > MAX_DIST) {
        col = backgroundColor; 
    } else {
        vec3 p = ro + rd * d;
        vec3 normal = calcNormal(p, 2.0);
        vec3 lightPosition = vec3(5, 50, 7);
        vec3 lightDirection = normalize(lightPosition - p);

        float dif = clamp(dot(normal, lightDirection), 0.3, 1.);
        col = dif * sdScene(p).color;
        
        vec4 explosion = texelFetch(iChannel3, ivec2(3,0), 0);
        if (explosion.w > 0.0) {
            float e = max(0.0, 1.0 - distance(p, explosion.xyz) * 0.1);
            col += vec3(1.0, 0.5, 0.2) * e * explosion.w;
        }
    }

    return col;
}



void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
  vec2 uv = (fragCoord-0.5*iResolution.xy)/iResolution.y;
  fragColor = vec4(DrawScene(uv), 1.0);
}
