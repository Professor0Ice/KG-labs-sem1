#include "MyMath.h"
#include "parserOBJ.h"
#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

struct Texture {
private:
    unsigned char* data;
    int width, height;
    int channels;

public:
    Texture() : data(nullptr), width(0), height(0), channels(0) {}

    Texture(const std::string& filename) {
        stbi_set_flip_vertically_on_load(true);
        data = stbi_load(filename.c_str(), &width, &height, &channels, 0);
        if (!data) {
            std::cerr << "Not texture " << filename << std::endl;
            width = height = channels = 0;
        }
    }

    ~Texture() {
        if (data) stbi_image_free(data);
    }

    TGAColor getColor(float u, float v) const {
        if (!data) {
            return TGAColor(255, 0, 255, 255);
        }

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

    int getWidth() const { return width; }
    int getHeight() const { return height; }
    bool isValid() const { return data != nullptr; }
};

struct ShaderVarying {
    Vec3 screen_pos;
    Vec3 world_pos;
    Vec3 normal;
    Vec2 texcoord;
    float intensity;
};

struct Material {
    Vec3 ambient;      
    Vec3 diffuse;      
    Vec3 specular;     
    float shininess;   
    Texture* texture;
    Vec3 ExtraColor;
};

struct Light {
    Vec3 position;     
    Vec3 ambient;     
    Vec3 diffuse;      
    Vec3 specular;   
};

struct ShaderUniform {
    Matrix4 view_matrix;
    Matrix4 projection_matrix;
    Vec3 light_dir;
    Vec3 camera_pos;
    int width;
    int height;

    Material material;
    Light light;
};

TGAColor phongLight(const Vec3& world_pos, Vec3& normal, const Vec2& texcoord, const ShaderUniform& uniform) {
    const Material& material = uniform.material;
    const Light& light = uniform.light;
    Vec3 norm = normal.normalize();
    Vec3 light_dir = (light.position - world_pos).normalize();
    Vec3 view_dir = (uniform.camera_pos - world_pos).normalize();

    TGAColor tex_color = material.texture->getColor(texcoord.x, texcoord.y);
    Vec3 tex_vec(tex_color.r / 255.0f, tex_color.g / 255.0f, tex_color.b / 255.0f);

    Vec3 ambient = light.ambient * material.ambient;
    float diff = std::max(0.0f, dot(norm, light_dir));
    Vec3 diffuse = light.diffuse * material.diffuse * diff;

    Vec3 halfway_dir = (light_dir + view_dir).normalize();
    float spec = pow(std::max(0.0f, dot(norm, halfway_dir)), material.shininess);
    Vec3 specular = light.specular * material.specular * spec;

    Vec3 result = ambient + (diffuse * tex_vec) + specular;
    result.x = std::min(1.0f, std::max(0.0f, result.x));
    result.y = std::min(1.0f, std::max(0.0f, result.y));
    result.z = std::min(1.0f, std::max(0.0f, result.z));

    TGAColor color = TGAColor(result.x * 255 + uniform.material.ExtraColor.x, result.y * 255 + uniform.material.ExtraColor.y, result.z * 255 + uniform.material.ExtraColor.z, 255);
    return color;
}