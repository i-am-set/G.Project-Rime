using Godot;
using Godot.Collections;
using System;
using System.Threading.Tasks;

public partial class CallResourceInstancer : Node3D
{
    public Godot.Collections.Dictionary IterateThroughTrees(Vector3 _authorized_player_position, float _authorized_player_resource_spawn_radius_half, Noise noise, Dictionary resourceData)
    {
        int generationCycle = 0;
        var Heightmap = GetNode<Node>("/root/Heightmap");

        for (int x = (int)(_authorized_player_position.X-(_authorized_player_resource_spawn_radius_half)); x < (int)(_authorized_player_position.X+(_authorized_player_resource_spawn_radius_half)); x++)
        {
            for (int z = (int)(_authorized_player_position.Z-(_authorized_player_resource_spawn_radius_half)); z < (int)(_authorized_player_position.Z+(_authorized_player_resource_spawn_radius_half)); z++)
            {
                float height = noise.GetNoise2D(x, z) * 100;
                if (height > 0.4 && !resourceData.ContainsKey(new Vector3(x, (float)Heightmap.Call("get_height", x, z), z)))
                {
                    Node3D tree = (Node3D)GetParent().Call("instantiate_resource", height*100);
                    tree.Position = new Vector3(x, (float)Heightmap.Call("get_height", x, z),z);
                    resourceData[tree.Position] = tree;
                    generationCycle += 1;
                    if (generationCycle >= 5)
                    {
                        generationCycle = 0;
                    }
                }
            }
        }

        return resourceData;
    }
}
