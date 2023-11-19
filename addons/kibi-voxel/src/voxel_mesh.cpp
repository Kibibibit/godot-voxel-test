#include "voxel_mesh.h"
#include <stdlib.h>

#include <godot_cpp/variant/utility_functions.hpp>

using namespace godot;

face_t::face_t(bool transparent, int type, side_t side)
{
    this->transparent = type == 0 ? true : transparent;
    this->type = type;
    this->side = side;
}

VoxelMesh::VoxelMesh()
{
    this->chunk_size = 0;
}
VoxelMesh::~VoxelMesh() {}

void VoxelMesh::_bind_methods()
{
    ClassDB::bind_method(D_METHOD("get_chunk_size"), &VoxelMesh::get_chunk_size);
    ClassDB::bind_method(D_METHOD("remesh", "p_chunk_size", "data"), &VoxelMesh::remesh);
}

int VoxelMesh::get_chunk_size()
{
    return this->chunk_size;
}

int VoxelMesh::get_voxel_index(int x, int y, int z)
{
    return (this->chunk_size * this->chunk_size * y) + (this->chunk_size * z) + x;
}

face_t *VoxelMesh::get_face(int x, int y, int z, const PackedByteArray &data, side_t side)
{
    face_t *face = new face_t(false, data[get_voxel_index(x, y, z)], side);

    return face;
}

bool VoxelMesh::face_equals(face_t *face_a, face_t *face_b)
{
    return face_a->type == face_b->type && face_a->transparent == face_b->transparent;
}

Vector3 VoxelMesh::face_normal(side_t side)
{
    switch (side)
    {
    case SIDE_SOUTH:
        return Vector3(0, 0, -1);
    case SIDE_NORTH:
        return Vector3(0, 0, 1);
    case SIDE_EAST:
        return Vector3(1, 0, 0);
    case SIDE_WEST:
        return Vector3(-1, 0, 0);
    case SIDE_TOP:
        return Vector3(0, 1, 0);
    case SIDE_BOTTOM:
        return Vector3(0, -1, 0);
    default:
        return Vector3(0, 0, 0);
    }
}

void VoxelMesh::remesh(int p_chunk_size, const PackedByteArray &data, int p_material_count)
{
    this->chunk_size = p_chunk_size;
    this->material_count = p_material_count;

    Array surface_array = Array();
    surface_array.resize(Mesh::ARRAY_MAX);

    PackedVector3Array verts = PackedVector3Array();
    PackedVector2Array uvs = PackedVector2Array();
    PackedVector3Array normals = PackedVector3Array();
    PackedInt32Array indices = PackedInt32Array();
    PackedFloat32Array custom0 = PackedFloat32Array();

    face_t *mask[this->chunk_size * this->chunk_size];

    for (int i = 0; i < this->chunk_size * this->chunk_size; i++)
    {
        mask[i] = nullptr;
    }

    int i, j, k, l, w, h, u, v, n = 0;
    side_t side = SIDE_SOUTH;

    face_t *face_a;
    face_t *face_b;

    int x[3] = {0, 0, 0};
    int q[3] = {0, 0, 0};
    int du[3] = {0, 0, 0};
    int dv[3] = {0, 0, 0};

    int iters = 1;
    bool back_face = true;

    while (iters >= 0)
    {

        for (int dimension = 0; dimension < 3; dimension++)
        {
            u = (dimension + 1) % 3;
            v = (dimension + 2) % 3;

            x[0] = 0;
            x[1] = 0;
            x[2] = 0;

            q[0] = 0;
            q[1] = 0;
            q[2] = 0;
            q[dimension] = 1;

            if (dimension == DIMENSION_WEST_EAST)
            {
                side = back_face ? SIDE_WEST : SIDE_EAST;
            }
            else if (dimension == DIMENSION_BOTTOM_TOP)
            {
                side = back_face ? SIDE_BOTTOM : SIDE_TOP;
            }
            else if (dimension == DIMENSION_SOUTH_NORTH)
            {
                side = back_face ? SIDE_SOUTH : SIDE_NORTH;
            }

            for (x[dimension] = -1; x[dimension] < this->chunk_size;)
            {
                n = 0;

                for (x[v] = 0; x[v] < this->chunk_size; x[v]++)
                {
                    for (x[u] = 0; x[u] < this->chunk_size; x[u]++)
                    {

                        face_a = x[dimension] >= 0 ? get_face(x[0], x[1], x[2], data, side) : nullptr;
                        face_b = x[dimension] < this->chunk_size - 1 ? get_face(x[0] + q[0], x[1] + q[1], x[2] + q[2], data, side) : nullptr;

                        if (face_a != nullptr && face_b != nullptr && face_equals(face_a, face_b))
                        {
                            mask[n++] = nullptr;
                        }
                        else
                        {
                            mask[n++] = back_face ? face_b : face_a;
                        }
                    }
                }

                x[dimension]++;

                n = 0;

                for (j = 0; j < this->chunk_size; j++)
                {
                    for (i = 0; i < this->chunk_size;)
                    {
                        if (mask[n] != nullptr)
                        {
                            for (w = 1; i + w < this->chunk_size && mask[n + w] != nullptr && face_equals(mask[n + w], mask[n]); w++)
                            {
                            }

                            bool done = false;

                            for (h = 1; j + h < this->chunk_size; h++)
                            {
                                for (k = 0; k < w; k++)
                                {
                                    if (
                                        mask[n + k + h * this->chunk_size] == nullptr ||
                                        !face_equals(mask[n + k + h * this->chunk_size], mask[n]))
                                    {
                                        done = true;
                                        break;
                                    }
                                }
                                if (done)
                                {
                                    break;
                                }
                            }

                            if (!mask[n]->transparent)
                            {
                                x[u] = i;
                                x[v] = j;
                                du[0] = 0;
                                du[1] = 0;
                                du[2] = 0;
                                du[u] = w;

                                dv[0] = 0;
                                dv[1] = 0;
                                dv[2] = 0;
                                dv[v] = h;

                                int index_offset = verts.size();

                                Vector3 normal = face_normal(side);

                                int type = mask[n]->type;

                                Vector3 v1 = Vector3(x[0], x[1], x[2]);
                                Vector3 v2 = Vector3(x[0] + du[0], x[1] + du[1], x[2] + du[2]);
                                Vector3 v3 = Vector3(x[0] + du[0] + dv[0], x[1] + du[1] + dv[1], x[2] + du[2] + dv[2]);
                                Vector3 v4 = Vector3(x[0] + dv[0], x[1] + dv[1], x[2] + dv[2]);

                                Vector3 face_size_vector = v3-v1;
                                float uv_offset_x, uv_offset_y = 0.0;

                                if (dimension == DIMENSION_SOUTH_NORTH) {
                                    uv_offset_x = face_size_vector.y;
                                    uv_offset_y = face_size_vector.x;
                                } else if (dimension == DIMENSION_WEST_EAST) {
                                    uv_offset_x = face_size_vector.z;
                                    uv_offset_y = face_size_vector.y;
                                } else {
                                    uv_offset_x = face_size_vector.x;
                                    uv_offset_y = face_size_vector.z;
                                }


                                verts.append(v1);
                                verts.append(v2);
                                verts.append(v3);
                                verts.append(v4);

                               
                                
                                normals.append(normal);
                                normals.append(normal);
                                normals.append(normal);
                                normals.append(normal);
                                uvs.append(Vector2(0.0, 0.0));
                                uvs.append(Vector2(0.0, uv_offset_y));
                                uvs.append(Vector2(uv_offset_x, uv_offset_y));
                                uvs.append(Vector2(uv_offset_x, 0.0));

                                float custom_value = ((float)type -1.0) / (float)material_count;

                                custom0.append(custom_value);
                                custom0.append(custom_value);
                                custom0.append(custom_value);
                                custom0.append(custom_value);
                                if (back_face)
                                {
                                    indices.append(index_offset + 1);
                                    indices.append(index_offset + 3);
                                    indices.append(index_offset);
                                    indices.append(index_offset + 1);
                                    indices.append(index_offset + 2);
                                    indices.append(index_offset + 3);
                                }
                                else
                                {
                                    indices.append(index_offset);
                                    indices.append(index_offset + 3);
                                    indices.append(index_offset + 1);
                                    indices.append(index_offset + 3);
                                    indices.append(index_offset + 2);
                                    indices.append(index_offset + 1);
                                }
                            }

                            for (l = 0; l < h; ++l)
                            {
                                for (k = 0; k < w; ++k)
                                {
                                    mask[n + k + l * this->chunk_size] = nullptr;
                                }
                            }

                            i += w;
                            n += w;
                        }
                        else
                        {
                            i++;
                            n++;
                        }
                    }
                }
            }
        }
        back_face = false;
        iters -= 1;
    }
    surface_array[Mesh::ARRAY_VERTEX] = verts;
    surface_array[Mesh::ARRAY_TEX_UV] = uvs;
    surface_array[Mesh::ARRAY_NORMAL] = normals;
    surface_array[Mesh::ARRAY_INDEX] = indices;
    surface_array[Mesh::ARRAY_CUSTOM0] = custom0;

    this->clear_surfaces();
    if (verts.size() > 0)
    {
        this->add_surface_from_arrays(Mesh::PRIMITIVE_TRIANGLES, surface_array, Array(), Dictionary(), Mesh::ARRAY_CUSTOM_R_FLOAT << Mesh::ARRAY_FORMAT_CUSTOM0_SHIFT);
    }
}
