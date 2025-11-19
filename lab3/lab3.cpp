#include "tgaimage.h"
#include "parserOBJ.h"
#include "MyMath.h"

const TGAColor white = TGAColor(255, 255, 255, 255);
const TGAColor black = TGAColor(30, 30, 30, 255);
const TGAColor green = TGAColor(0, 180, 0, 255);
const TGAColor red = TGAColor(180, 0, 0, 255);

void line(int x0, int y0, int x1, int y1, TGAImage& image, TGAColor color) {
    bool steep = false;
    if (std::abs(x0 - x1) < std::abs(y0 - y1)) {
        std::swap(x0, y0);
        std::swap(x1, y1);
        steep = true;
    }
    if (x0 > x1) {
        std::swap(x0, x1);
        std::swap(y0, y1);
    }
    int dx = x1 - x0;
    int dy = y1 - y0;
    int derror2 = std::abs(dy) * 2;
    int error2 = 0;
    int y = y0;
    for (int x = x0; x <= x1; x++) {
        if (steep) {
            image.set(y, x, color);
        }
        else {
            image.set(x, y, color);
        }
        error2 += derror2;

        if (error2 > dx) {
            y += (y1 > y0 ? 1 : -1);
            error2 -= dx * 2;
        }
    }
}

void triangle(Vec2i t0, Vec2i t1, Vec2i t2, TGAImage& image, TGAColor color) {
    if (t0.y > t1.y) std::swap(t0, t1);
    if (t0.y > t2.y) std::swap(t0, t2);
    if (t1.y > t2.y) std::swap(t1, t2);

    int total_height = t2.y - t0.y;
    for (int y = t0.y; y <= t1.y; y++) {
        int segment_height = t1.y - t0.y + 1;
        float alpha = (float)(y - t0.y) / total_height;
        float beta = (float)(y - t0.y) / segment_height;
        Vec2i A = t0 + (t2 - t0) * alpha;
        Vec2i B = t0 + (t1 - t0) * beta;
        if (A.x > B.x) std::swap(A, B);
        for (int j = A.x; j <= B.x; j++) {
            image.set(j, y, color); 
        }
    }
    for (int y = t1.y; y <= t2.y; y++) {
        int segment_height = t2.y - t1.y + 1;
        float alpha = (float)(y - t0.y) / total_height;
        float beta = (float)(y - t1.y) / segment_height; 
        Vec2i A = t0 + (t2 - t0) * alpha;
        Vec2i B = t1 + (t2 - t1) * beta;
        if (A.x > B.x) std::swap(A, B);
        for (int j = A.x; j <= B.x; j++) {
            image.set(j, y, color); 
        }
    }
}

void drawModelTriangle(const Model& model, int width, int height, TGAImage& image, TGAColor color) {
    for (int i = 0; i < model.faces.size(); i++) {
        const Face& face = model.faces[i];

        if (face.vertexId.size() >= 3) {
            std::vector<Vec2i> screen_coords;

            for (int j = 0; j < face.vertexId.size(); j++) {
                const Vertex& v = model.vertices[face.vertexId[j]];
                int x = (v.x + 1.0f) * width / 2.0f;
                int y = (v.y + 1.0f) * height / 2.0f;
                screen_coords.push_back(Vec2i(x, y));
            }

            for (int j = 1; j < screen_coords.size() - 1; j++) {
                triangle(screen_coords[0], screen_coords[j], screen_coords[j + 1], image, color);
            }
        }
    }
}

void drawModelTriangleL(const Model& model, int width, int height, TGAImage& image, const Vec3& light_dir) {
    for (int i = 0; i < model.faces.size(); i++) {
        const Face& face = model.faces[i];

        if (face.vertexId.size() >= 3) {
            std::vector<Vec2i> screen_coords;
            std::vector<Vec3> world_coords;

            for (int j = 0; j < face.vertexId.size(); j++) {
                const Vertex& v = model.vertices[face.vertexId[j]];
                int x = (v.x + 1.0f) * width / 2.0f;
                int y = (v.y + 1.0f) * height / 2.0f;
                screen_coords.push_back(Vec2i(x, y));
                world_coords.push_back(Vec3(v.x, v.y, v.z));
            }

            // Триангулируем полигон и для каждого треугольника вычисляем освещение
            for (int j = 1; j < screen_coords.size() - 1; j++) {
                int idx0 = 0;
                int idx1 = j;
                int idx2 = j + 1;

                Vec3 v0 = world_coords[idx0];
                Vec3 v1 = world_coords[idx1];
                Vec3 v2 = world_coords[idx2];

                Vec3 edge1 = v1 - v0;
                Vec3 edge2 = v2 - v0;
                Vec3 normal = cross(edge1, edge2);
                normal.normalize();

                float intensity = normal * light_dir;

                if (intensity > 0) {
                    TGAColor color = TGAColor(intensity * 255, intensity * 255, intensity * 255, 255);
                    triangle(screen_coords[idx0], screen_coords[idx1], screen_coords[idx2], image, color);
                }
            }
        }
    }
}

Vec3 barycentric(Vec3* pts, Vec2 P) {
    Vec3 u = cross(Vec3(pts[2].x - pts[0].x, pts[1].x - pts[0].x, pts[0].x - P.x),
        Vec3(pts[2].y - pts[0].y, pts[1].y - pts[0].y, pts[0].y - P.y));

    // Если треугольник вырожденный
    if (std::abs(u.z) < 1e-2) {
        return Vec3(-1, 1, 1);
    }

    return Vec3(1.0f - (u.x + u.y) / u.z, u.y / u.z, u.x / u.z);
}

void triangle_with_zbuffer(Vec3* pts, int width, int height, float* zbuffer, TGAImage& image, TGAColor color) {
    Vec2 bboxmin(std::numeric_limits<float>::max(), std::numeric_limits<float>::max());
    Vec2 bboxmax(-std::numeric_limits<float>::max(), -std::numeric_limits<float>::max());

    for (int i = 0; i < 3; i++) {
        bboxmin.x = std::min(bboxmin.x, pts[i].x);
        bboxmin.y = std::min(bboxmin.y, pts[i].y);
        bboxmax.x = std::max(bboxmax.x, pts[i].x);
        bboxmax.y = std::max(bboxmax.y, pts[i].y);
    }

    bboxmin.x = std::max(0.f, bboxmin.x);
    bboxmin.y = std::max(0.f, bboxmin.y);
    bboxmax.x = std::min(width - 1.f, bboxmax.x);
    bboxmax.y = std::min(height - 1.f, bboxmax.y);

    for (int x = (int)bboxmin.x; x <= (int)bboxmax.x; x++) {
        for (int y = (int)bboxmin.y; y <= (int)bboxmax.y; y++) {
            Vec3 bc = barycentric(pts, Vec2(x, y));

            if (bc.x >= 0 && bc.y >= 0 && bc.z >= 0) {
                float z = 0;
                for (int i = 0; i < 3; i++) {
                    z += pts[i].z * bc[i];
                }

                // Проверяем Z-буфер
                int idx = x + y * width;
                if (z < zbuffer[idx]) {
                    zbuffer[idx] = z;
                    image.set(x, y, color);
                }
            }
        }
    }
}

void drawModelWithZBuffer(const Model& model, int width, int height, TGAImage& image,
    float* zbuffer, const Vec3& light_dir) {
    for (int i = 0; i < model.faces.size(); i++) {
        const Face& face = model.faces[i];

        if (face.vertexId.size() >= 3) {
            for (int j = 1; j < face.vertexId.size() - 1; j++) {
                int idx0 = 0;
                int idx1 = j;
                int idx2 = j + 1;

                const Vertex& v0 = model.vertices[face.vertexId[idx0]];
                const Vertex& v1 = model.vertices[face.vertexId[idx1]];
                const Vertex& v2 = model.vertices[face.vertexId[idx2]];

                Vec3 screen_coords[3];
                screen_coords[0] = Vec3((v0.x + 1.0f) * width / 2.0f,
                    (v0.y + 1.0f) * height / 2.0f,
                    v0.z);
                screen_coords[1] = Vec3((v1.x + 1.0f) * width / 2.0f,
                    (v1.y + 1.0f) * height / 2.0f,
                    v1.z);
                screen_coords[2] = Vec3((v2.x + 1.0f) * width / 2.0f,
                    (v2.y + 1.0f) * height / 2.0f,
                    v2.z);

                Vec3 world_coords[3] = {
                    Vec3(v0.x, v0.y, v0.z),
                    Vec3(v1.x, v1.y, v1.z),
                    Vec3(v2.x, v2.y, v2.z)
                };

                Vec3 edge1 = world_coords[1] - world_coords[0];
                Vec3 edge2 = world_coords[2] - world_coords[0];
                Vec3 normal = cross(edge1, edge2);
                normal.normalize();

                float intensity = normal * light_dir;

                Vec3 Texture(0, 0, 0);

                model.texCoords[i].u;
                model.texCoords[i].v;

                if (intensity > 0) {
                    TGAColor color = TGAColor(intensity * 255, intensity * 255,
                        intensity * 255, 255);
                    triangle_with_zbuffer(screen_coords, width, height, zbuffer, image, color);
                }
            }
        }
    }
}

void drawModelLine(const Model& model, int width, int height, TGAImage& image, TGAColor color) {
    for (int i = 0; i < model.faces.size(); i++) {
        const Face& face = model.faces[i];

        for (int j = 0; j < face.vertexId.size(); j++) {
            int currentVertexIndex = face.vertexId[j];
            int nextVertexIndex = face.vertexId[(j + 1) % face.vertexId.size()];
            const Vertex& v0 = model.vertices[currentVertexIndex];
            const Vertex& v1 = model.vertices[nextVertexIndex];

            int x0 = (v0.x + 1.0f) * width / 2.0f ;
            int y0 = (v0.y + 1.0f) * height / 2.0f ;
            int x1 = (v1.x + 1.0f) * width / 2.0f ;
            int y1 = (v1.y + 1.0f) * height / 2.0f;

            line(x0, y0, x1, y1, image, color);
        }
    }
}

int main() {
	int width = 1000;
	int height = 1000;
	TGAImage image(width, height, TGAImage::RGB);

	for (int x = 0; x < width; x++) {
		for (int y = 0; y < height; y++) {
			image.set(x, y, black);
		}
	}

    //Линии
	//line(20, 20, 480, 20, image, white);
	//line(20, 20, 250, 480, image, white);
	//line(480, 20, 250, 480, image, white);

    Model obj;
    obj = parseOBJ("base.obj");
    printInfo(obj);

    //Модель на линиях
    //drawModelLine(obj, width, height, image, white);

    //Треугольники
    //Vec2i t0[3] = { Vec2i(10, 70),   Vec2i(50, 160),  Vec2i(70, 80) };
    //Vec2i t1[3] = { Vec2i(180, 50),  Vec2i(150, 1),   Vec2i(70, 180) };
    //Vec2i t2[3] = { Vec2i(180, 150), Vec2i(120, 160), Vec2i(130, 180) };
    //triangle(t1[0], t1[1], t1[2], image, red);
    //triangle(t0[0], t0[1], t0[2], image, green);
    //triangle(t2[0], t2[1], t2[2], image, white);

    std::cout << "Start" << std::endl;

    Vec3 light_dir(0, 0., -1);
    std::vector<float> zBuffer(width * height, std::numeric_limits<float>::max());
    drawModelWithZBuffer(obj, width, height, image, zBuffer.data(), light_dir);
    std::cout << "End";

	image.flip_vertically();
	image.write_tga_file("output.tga"); 

}