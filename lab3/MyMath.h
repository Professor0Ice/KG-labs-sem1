#include <cmath>

struct Vec4i {
    int r, g, b, a;
};

struct Vec3 {
    float x, y, z;

    Vec3 operator - (const Vec3& other) const {
        return Vec3(x - other.x, y - other.y, z - other.z);
    }

    Vec3 operator + (const Vec3& other) const {
        return Vec3(x + other.x, y + other.y, z + other.z);
    }

    Vec3 operator ^ (const Vec3& other) const {
        return Vec3(
            y * other.z - z * other.y,
            z * other.x - x * other.z,
            x * other.y - y * other.x
        );
    }

    float operator[](unsigned index) const
    {
        switch (index)
        {
        case 0: return x;
        case 1: return y; 
        case 2: return z;
        default: return 0;
        }
    }

    float operator * (const Vec3& other) const {
        return x * other.x + y * other.y + z * other.z;
    }

    void normalize() {
        float len = sqrt(x * x + y * y + z * z);
        if (len > 0) {
            x /= len;
            y /= len;
            z /= len;
        }
    }
};

Vec3 cross(const Vec3& a, const Vec3& b) {
    return Vec3(
        a.y * b.z - a.z * b.y,
        a.z * b.x - a.x * b.z,
        a.x * b.y - a.y * b.x
    );
}

struct Vec2 {
    float x, y;
};

struct Vec3i {
    float x, y, z;
};

struct Vec2i {
    int x, y;
};

float dot(const Vec3& a, const Vec3& b) {
    return a.x * b.x + a.y * b.y + a.z * b.z;
}

Vec2i operator + (const Vec2i& c1, const Vec2i& c2)
{
    return Vec2i{ c1.x + c2.x, c1.y + c2.y };
}

Vec2i operator - (const Vec2i& c1, const Vec2i& c2)
{
    return Vec2i{ c1.x - c2.x, c1.y - c2.y };
}

Vec2i operator * (const Vec2i& c1, const float& c2)
{
    int x = c1.x * c2;
    int y = c1.y * c2;
    return Vec2i{ x, y };
}
