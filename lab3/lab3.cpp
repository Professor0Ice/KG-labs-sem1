#include "tgaimage.h"
#include "parserOBJ.h"
#include "MyMath.h"
#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

const TGAColor white = TGAColor(255, 255, 255, 255);
const TGAColor black = TGAColor(30, 30, 30, 255);
const TGAColor green = TGAColor(0, 180, 0, 255);
const TGAColor red = TGAColor(180, 0, 0, 255);

struct Texture {
private:
    unsigned char* data;
    int width, height;
    int channels;

public:
    Texture(const std::string& filename) {
        data = stbi_load(filename.c_str(), &width, &height, &channels, 0);
        if (!data) {
            std::cout << "Failed to load texture: " << filename << std::endl;
            width = height = channels = 0;
        }
        else {
            std::cout << "Texture loaded " << std::endl;
        }
    }

    ~Texture() {
        if (data) stbi_image_free(data);
    }

    TGAColor getColor(float u, float v) const {
        if (!data) return TGAColor(255, 0, 255, 255);

        v = 1.0f - v;

        int x = static_cast<int>(u * width) % width;
        int y = static_cast<int>(v * height) % height;

        if (x < 0) x += width;
        if (y < 0) y += height;

        int index = (y * width + x) * channels;

        if (channels >= 3) {
            return TGAColor(data[index], data[index + 1], data[index + 2], 255);
        }
        else if (channels == 1) {
            return TGAColor(data[index], data[index], data[index], 255);
        }

        return TGAColor(255, 0, 255, 255);
    }
};

Vec3 barycentric(Vec3* pts, Vec2 P) {
    Vec3 u = cross(Vec3(pts[2].x - pts[0].x, pts[1].x - pts[0].x, pts[0].x - P.x),
        Vec3(pts[2].y - pts[0].y, pts[1].y - pts[0].y, pts[0].y - P.y));

    // Если треугольник вырожденный
    if (std::abs(u.z) < 1e-2) {
        return Vec3(-1, 1, 1);
    }

    return Vec3(1.0f - (u.x + u.y) / u.z, u.y / u.z, u.x / u.z);
}

void DrawTriangle(Vec3* pts, Vec2* uvs, int width, int height, float* zbuffer,
    TGAImage& image, const Texture& texture, float intensity) {

    Vec2 bboxmin(std::numeric_limits<float>::max(), std::numeric_limits<float>::max());
    Vec2 bboxmax(-std::numeric_limits<float>::max(), -std::numeric_limits<float>::max());

    for (int i = 0; i < 3; i++) {
        bboxmin.x = std::max(0.f, std::min(bboxmin.x, pts[i].x));
        bboxmin.y = std::max(0.f, std::min(bboxmin.y, pts[i].y));
        bboxmax.x = std::min(width - 1.f, std::max(bboxmax.x, pts[i].x));
        bboxmax.y = std::min(height - 1.f, std::max(bboxmax.y, pts[i].y));
    }

    for (int x = (int)bboxmin.x; x <= (int)bboxmax.x; x++) {
        for (int y = (int)bboxmin.y; y <= (int)bboxmax.y; y++) {
            Vec3 bc = barycentric(pts, Vec2(x, y));

            if (bc.x < 0 || bc.y < 0 || bc.z < 0) continue;

            float z = pts[0].z * bc.x + pts[1].z * bc.y + pts[2].z * bc.z;

            float u = uvs[0].x * bc.x + uvs[1].x * bc.y + uvs[2].x * bc.z;
            float v = uvs[0].y * bc.x + uvs[1].y * bc.y + uvs[2].y * bc.z;

            int idx = x + y * width;
            if (z < zbuffer[idx]) {
                zbuffer[idx] = z;

                TGAColor tex_color = texture.getColor(u, v);
                TGAColor final_color = TGAColor(
                    tex_color.r * intensity,
                    tex_color.g * intensity,
                    tex_color.b * intensity,
                    255
                );

                image.set(x, y, final_color);
            }
        }
    }
}

class Camera {
private:
    Vec3 position;     
    Vec3 target;         
    Vec3 up;        

    float field_of_view;   
    float near_distance;  
    float far_distance; 

    Matrix4 view_matrix; 
    Matrix4 projection_matrix;

public:
    Camera(const Vec3& camera_position = Vec3(0, 0, 3),
        const Vec3& look_at_target = Vec3(0, 0, 0),
        float fov_degrees = 45.0f,
        float near_plane = 0.1f,
        float far_plane = 100.0f)
        : position(camera_position),
        target(look_at_target),
        up(0, 1, 0),
        field_of_view(fov_degrees),
        near_distance(near_plane),
        far_distance(far_plane) {

        recalculateMatrices();
    }

    void recalculateMatrices() {
        updateViewMatrix();
        updateProjectionMatrix();
    }

private:
    void updateViewMatrix() {
        Vec3 forward_direction = (target - position).normalize();

        Vec3 right_direction = cross(forward_direction, up).normalize();

        Vec3 corrected_up = cross(right_direction, forward_direction);

        view_matrix = Matrix4::lookAt(position, target, corrected_up);
    }

    void updateProjectionMatrix() {
        const float PI = 3.14159265358979323846f;
        float fov_radians = field_of_view * PI / 180.0f;

        float aspect_ratio = 1.0f; // Если наебнётся - возможно изменил разрешение

        projection_matrix = Matrix4::perspective(fov_radians, aspect_ratio,
            near_distance, far_distance);
    }

public:
    void move(const Vec3& movement_offset) {
        position = position + movement_offset;
        target = target + movement_offset;
        updateViewMatrix();
    }

    void setPosition(const Vec3& new_position) {
        Vec3 look_direction = target - position;
        position = new_position;
        target = position + look_direction;
        updateViewMatrix();
    }

    void lookAt(const Vec3& new_target) {
        target = new_target;
        updateViewMatrix();
    }

    void setFieldOfView(float new_fov_degrees) {
        field_of_view = new_fov_degrees;
        updateProjectionMatrix();
    }

    Matrix4 getViewMatrix() const { return view_matrix; }
    Matrix4 getProjectionMatrix() const { return projection_matrix; }
};

void renderWithCamera(const Model& model, const Texture& texture, const Camera& camera, int width, int height,
    TGAImage& image, float* zbuffer, const Vec3& light_dir) {

    Matrix4 view = camera.getViewMatrix();
    Matrix4 projection = camera.getProjectionMatrix();

    for (int i = 0; i < model.faces.size(); i++) {
        const Face& face = model.faces[i];

        if (face.vertexId.size() >= 3) {
            for (int j = 1; j < face.vertexId.size() - 1; j++) {
                int idx0 = 0, idx1 = j, idx2 = j + 1;

                const Vertex& v0 = model.vertices[face.vertexId[idx0]];
                const Vertex& v1 = model.vertices[face.vertexId[idx1]];
                const Vertex& v2 = model.vertices[face.vertexId[idx2]];

                Vec3 world_v0(v0.x, v0.y, v0.z);
                Vec3 world_v1(v1.x, v1.y, v1.z);
                Vec3 world_v2(v2.x, v2.y, v2.z);

                Vec3 clip_v0 = projection.transformPoint(view.transformPoint(world_v0));
                Vec3 clip_v1 = projection.transformPoint(view.transformPoint(world_v1));
                Vec3 clip_v2 = projection.transformPoint(view.transformPoint(world_v2));

                Vec3 screen_coords[3] = {
                    Vec3((clip_v0.x + 1.0f) * width / 2.0f, (clip_v0.y + 1.0f) * height / 2.0f, clip_v0.z),
                    Vec3((clip_v1.x + 1.0f) * width / 2.0f, (clip_v1.y + 1.0f) * height / 2.0f, clip_v1.z),
                    Vec3((clip_v2.x + 1.0f) * width / 2.0f, (clip_v2.y + 1.0f) * height / 2.0f, clip_v2.z)
                };

                const TextureCoord& uv0 = model.texCoords[face.textureId[idx0]];
                const TextureCoord& uv1 = model.texCoords[face.textureId[idx1]];
                const TextureCoord& uv2 = model.texCoords[face.textureId[idx2]];
                Vec2 texture_coords[3] = {
                    Vec2(uv0.u, uv0.v),
                    Vec2(uv1.u, uv1.v),
                    Vec2(uv2.u, uv2.v)
                };
                Vec3 edge1 = world_v1 - world_v0;
                Vec3 edge2 = world_v2 - world_v0;
                Vec3 normal = cross(edge1, edge2).normalize();
                float intensity = normal * light_dir;

                if (intensity > 0) {
                    DrawTriangle(screen_coords, texture_coords, width, height, zbuffer, image, texture, intensity);
                }
                else {
                    DrawTriangle(screen_coords, texture_coords, width, height, zbuffer, image, texture, 0);
                }
            }
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

    Model obj;
    obj = parseOBJ("Isacc.obj");
    printInfo(obj);

    std::cout << "Start" << std::endl;

    Vec3 light_dir(0, 0., 1);
    std::vector<float> zBuffer(width * height, std::numeric_limits<float>::max());

    //drawModelWithZBuffer(obj, width, height, image, zBuffer.data(), light_dir);
    Camera camera(Vec3(0, 2.5, 8), //камера 
        Vec3(0, 2.5, 0),  // моделька
        40.0f,          // FOV
        0.1f,           // мин
        50.0f);         // макс

    Texture texture("Isaac.png");

    renderWithCamera(obj, texture, camera, width, height, image, zBuffer.data(), light_dir);

    std::cout << "End";

	image.flip_vertically();
	image.write_tga_file("output.tga"); 

}