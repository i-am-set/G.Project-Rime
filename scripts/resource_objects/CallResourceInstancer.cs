using System;
using System.Collections.Generic;
using Godot;
using Godot.Collections;

public partial class CallResourceInstancer : Node3D
{
    private HashSet<Vector2> cachedPositions = new();
    private int tick = 0;
    private Node Heightmap;
    private Node Global;

    public override void _Ready()
    {
        Heightmap = GetNode<Node>("/root/Heightmap");
        Global = GetNode<Node>("/root/Global");
    }

    public Godot.Collections.Dictionary IterateThroughResources(Vector3 authorizedPlayerPosition, float authorizedPlayerResourceSpawnRadiusHalf, Noise noise, Dictionary resourceData)
    {
        for (int x = (int)(authorizedPlayerPosition.X-(authorizedPlayerResourceSpawnRadiusHalf)); x < (int)(authorizedPlayerPosition.X+(authorizedPlayerResourceSpawnRadiusHalf)); x++)
        {
            for (int z = (int)(authorizedPlayerPosition.Z-(authorizedPlayerResourceSpawnRadiusHalf)); z < (int)(authorizedPlayerPosition.Z+(authorizedPlayerResourceSpawnRadiusHalf)); z++)
            {
                if (cachedPositions.Contains(new Vector2(x, z)))
                {
                    continue;
                }
                cachedPositions.Add(new Vector2(x, z));
                float height = noise.GetNoise2D(x, z) * 100;
                float heightmapY = (float)Heightmap.Call("get_height", x, z);
                if (height > 0.4 && !resourceData.ContainsKey(new Vector3(x, heightmapY, z)))
                {
                    Node3D resource = InstantiateResource((ulong)(height * 100), GetParent());
                    // Node3D resource = (Node3D)GetParent().Call("instantiate_resource", height*100);
                    Vector3 resourcePosition = new(x, heightmapY, z);
                    resource.Position = resourcePosition;
                    resourceData[resourcePosition] = resource;
                }
            }
        }

        return resourceData;
    }

    private Node3D InstantiateResource(ulong heightSeed, Node parent)
    {
        RandomNumberGenerator rngBase = (RandomNumberGenerator)parent.Get("_rng_base");
        Dictionary weights = (Dictionary)parent.Get("weights");
        Godot.Collections.Array trees = (Godot.Collections.Array)parent.Get("trees");

        rngBase.Seed = heightSeed;
        float diceRoll = rngBase.RandfRange(0, (float)parent.Get("_total_weight"));
        
        foreach (var resource in weights)
        {
            if (((float)weights[resource.Key]) >= diceRoll)
            {
                PackedScene currentResource = (PackedScene)resource.Key;
                int randResource = 0;
                Node3D resourceInstance = (Node3D)currentResource.Instantiate();
                var resourceScale = rngBase.RandfRange(0.8f, 2.0f);
                randResource = rngBase.RandiRange(0, resourceInstance.GetChildren().Count-1);
                resourceInstance.Call("ShowResource", randResource);
                resourceInstance.Scale = new Vector3(resourceScale, resourceScale, resourceScale);
                resourceInstance.Rotation = new Vector3(DegToRad(rngBase.RandiRange(-2, 2)), DegToRad(rngBase.RandiRange(0, 359)), DegToRad(rngBase.RandiRange(-2, 2)));

                if (trees.Contains(resource.Key))
				{
					return TreeParameters(resourceInstance, randResource, rngBase);
				}

                return resourceInstance;
            }
            diceRoll -= (float)weights[resource.Key];
        }

        GD.PrintErr("failed to roll a resource");

        return null;
    }

    private Node3D TreeParameters(Node3D tree, int treeNumber, RandomNumberGenerator rngBase)
    {
        MeshInstance3D firstChild = (MeshInstance3D)tree.GetChild(treeNumber).GetChild(0);
		Material firstChildMaterial = firstChild.MaterialOverride;
		// float LODBias = (float)Global.Get("LOD_BIAS");
		firstChildMaterial = (ShaderMaterial)firstChildMaterial.Duplicate();
		var treeShader = (ShaderMaterial)firstChildMaterial;
		firstChildMaterial.Set("lod_bias", 0.2);
		treeShader.SetShaderParameter("tree_base_height", rngBase.RandfRange(0.1f, 1.2f));
		treeShader.SetShaderParameter("tree_base_darkness", rngBase.RandfRange(0.1f, 0.2f));
		treeShader.SetShaderParameter("uv1_offset", new Vector3(rngBase.RandfRange(1, 20), 1, 1));
        firstChild.MaterialOverride = firstChildMaterial;

        return tree;
    }

    public void ReseatResources(Dictionary resourceData, Vector3 _authorizedPlayerPosition, int _authorizedPlayerResourceSpawnRadius)
    {
        Vector2 playerPos2D = new(_authorizedPlayerPosition.X, _authorizedPlayerPosition.Z);
        foreach (Vector3 resourceLocation in resourceData.Keys)
        {
            Node node = (Node)resourceData[resourceLocation];
            if (node == null)
            {
                continue;
            }
            var distance = new Vector2(resourceLocation.X, resourceLocation.Z).DistanceTo(playerPos2D);
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

    private float DegToRad(float inputDegrees)
	{
		float outputRadians = (float)((Math.PI / 180) * inputDegrees);
		return outputRadians;
	}
    
    // public override void _PhysicsProcess(double delta)
    // {
    //     tick++;
    //     if (tick >= 240)
    //     {
    //         tick = 0;
    //         cachedPositions.Clear();
    //     }
    // }
}
