using System.Collections.Generic;
using System.Linq;
using Godot;
using Godot.Collections;

public partial class CallResourceInstancer : Node3D
{
    private HashSet<Vector2> cachedPositions = new HashSet<Vector2>();

    public Godot.Collections.Dictionary IterateThroughResources(Vector3 _authorized_player_position, float _authorized_player_resource_spawn_radius_half, Noise noise, Dictionary resourceData)
    {
        var Heightmap = GetNode<Node>("/root/Heightmap");

        for (int x = (int)(_authorized_player_position.X-(_authorized_player_resource_spawn_radius_half)); x < (int)(_authorized_player_position.X+(_authorized_player_resource_spawn_radius_half)); x++)
        {
            for (int z = (int)(_authorized_player_position.Z-(_authorized_player_resource_spawn_radius_half)); z < (int)(_authorized_player_position.Z+(_authorized_player_resource_spawn_radius_half)); z++)
            {
                if (cachedPositions.Contains(new Vector2(x, z)))
                {
                    continue;
                }
                cachedPositions.Add(new Vector2(x, z));
                float height = noise.GetNoise2D(x, z) * 100;
                if (height > 0.4 && !resourceData.ContainsKey(new Vector3(x, (float)Heightmap.Call("get_height", x, z), z)))
                {
                    Node3D resource = (Node3D)GetParent().Call("instantiate_resource", height*100);
                    Vector3 resourcePosition = new(x, (float)Heightmap.Call("get_height", x, z),z);
                    resource.Position = resourcePosition;
                    resourceData[resourcePosition] = resource;
                }
            }
        }

        return resourceData;
    }

    public void ReseatResources(Dictionary resourceData, Vector3 _authorizedPlayerPosition, int _authorizedPlayerResourceSpawnRadius)
    {
        foreach (Vector3 resourceLocation in resourceData.Keys)
        {
            Node node = (Node)resourceData[resourceLocation];
            if (node == null)
            {
                continue;
            }
            var distance = new Vector2(resourceLocation.X, resourceLocation.Z).DistanceTo(new Vector2(_authorizedPlayerPosition.X, _authorizedPlayerPosition.Z));
            if (distance < _authorizedPlayerResourceSpawnRadius && node.GetParent() == null)
            {
                GetParent().AddChild(node);
            }
            else if (distance >= _authorizedPlayerResourceSpawnRadius && node.GetParent() != null)
            {
                GetParent().RemoveChild(node);
            }
        }
    }
}
