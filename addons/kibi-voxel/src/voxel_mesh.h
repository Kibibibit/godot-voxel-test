#ifndef KIBIVOXEL_VOXEL_MESH_H
#define KIBIVOXEL_VOXEL_MESH_H

#include <godot_cpp/classes/array_mesh.hpp>

#define SIDE_SOUTH 0
#define SIDE_NORTH 1
#define SIDE_EAST 2
#define SIDE_WEST 3
#define SIDE_TOP 4
#define SIDE_BOTTOM 5

#define DIMENSION_WEST_EAST 0
#define DIMENSION_BOTTOM_TOP 1
#define DIMENSION_SOUTH_NORTH 2

#define WATER_SURFACE 6

typedef int side_t;

namespace godot
{

    struct face_t {
        bool transparent;
        int type;
        side_t side;
        face_t(bool transparent, int type, side_t side);
    };


    class VoxelMesh : public ArrayMesh
    {
        GDCLASS(VoxelMesh, ArrayMesh)

    private:
        int material_count;
        int chunk_size;
        int get_voxel_index(int x, int y, int z);
        bool face_equals(face_t * face_a, face_t * face_b);
        face_t * get_face(int x, int y, int z, const PackedByteArray &data, side_t side);
        Vector3 face_normal(side_t side);
        void add_face(float x1, float y1, float x2, float y2, face_t * face);

    protected:
        static void _bind_methods();

    public:
        VoxelMesh();
        ~VoxelMesh();

        int get_chunk_size();
        void remesh(int p_chunk_size, const PackedByteArray &data, int p_material_count);
    };

}

#endif