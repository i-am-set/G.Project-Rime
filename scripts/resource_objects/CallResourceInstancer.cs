using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Godot;
using Godot.Collections;

public partial class CallResourceInstancer : Node3D
{
    private HashSet<Vector2> cachedPositions = new();
    private int tick = 0;
    private Node Heightmap;
    private Node Global;
    private Vector3 authorizedPlayerPosition = new();
    private int authorizedPlayerResourceSpawnRadius = 10;
    private int authorizedPlayerResourceSpawnRadiusHalf = 5;
    private System.Collections.Generic.Dictionary<Vector3, Node3D> resourceData = new();
    private FastNoiseLite noise = (FastNoiseLite)GD.Load("res://world/heightmap/resource_noise.tres");
    private bool isGeneratingResources = false;

    private int currentX, currentZ;
    private const int positionsPerFrame = 100;

    public override void _Ready()
    {
        Heightmap = GetNode<Node>("/root/Heightmap");
        Global = GetNode<Node>("/root/Global");
        
        currentX = (int)(authorizedPlayerPosition.X - authorizedPlayerResourceSpawnRadiusHalf);
        currentZ = (int)(authorizedPlayerPosition.Z - authorizedPlayerResourceSpawnRadiusHalf);
    }

    public override void _Process(double delta)
    {
        GenerateLocalResources();
    }

    // public override void _PhysicsProcess(double delta)
    // {
    //     if (!isGeneratingResources)
    //     {
    //         if ((int)Global.Get("Global") % 40 == 0)
    //         {
    //             isGeneratingResources = true;
    //             GenerateLocalResources();
    //         }
    //     }
    // }

    private void GenerateLocalResources()
    {   
        resourceData = IterateThroughResources(authorizedPlayerPosition, authorizedPlayerResourceSpawnRadiusHalf, noise, resourceData);
        
        ReseatResources(resourceData, authorizedPlayerPosition, authorizedPlayerResourceSpawnRadius);
        
        isGeneratingResources = false;
    }

    private System.Collections.Generic.Dictionary<Vector3, Node3D> IterateThroughResources(Vector3 authorizedPlayerPosition, float authorizedPlayerResourceSpawnRadiusHalf, Noise noise, System.Collections.Generic.Dictionary<Vector3, Node3D> resourceData)
    {
        Vector2 cachedPosition = new();
        Vector3 resourcePosition = new();

        for (int i = 0; i < positionsPerFrame; i++)
        {
            cachedPosition.X = currentX;
            cachedPosition.Y = currentZ;
            if (!cachedPositions.Contains(cachedPosition))
            {
                cachedPositions.Add(cachedPosition);
                float height = noise.GetNoise2D(currentX, currentZ) * 100;
                float heightmapY = (float)Heightmap.Call("get_height", currentX, currentZ);
                if (height > 0.425)
                {
                    resourcePosition.X = currentX;
                    resourcePosition.Y = heightmapY;
                    resourcePosition.Z = currentZ;
                    if (!resourceData.ContainsKey(resourcePosition))
                    {
                        Node3D resource = InstantiateResource((ulong)(height * 100), GetParent());
                        resource.Position = resourcePosition;
                        resourceData[resourcePosition] = resource;
                    }
                }
            }

            // Update currentX and currentZ for the next frame
            currentZ++;
            if (currentZ >= authorizedPlayerPosition.Z + authorizedPlayerResourceSpawnRadiusHalf)
            {
                currentZ = (int)(authorizedPlayerPosition.Z - authorizedPlayerResourceSpawnRadiusHalf);
                currentX++;
                if (currentX >= authorizedPlayerPosition.X + authorizedPlayerResourceSpawnRadiusHalf)
                {
                    // We've finished processing the entire area
                    // Reset currentX and currentZ to the start of the area
                    currentX = (int)(authorizedPlayerPosition.X - authorizedPlayerResourceSpawnRadiusHalf);
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
        float totalWeight = (float)parent.Get("_total_weight");

        rngBase.Seed = heightSeed;
        float diceRoll = rngBase.RandfRange(0, totalWeight);
        
        foreach (var resource in weights)
        {
            float weight = (float)weights[resource.Key];
            if (weight >= diceRoll)
            {
                PackedScene currentResource = (PackedScene)resource.Key;
                Node3D resourceInstance = (Node3D)currentResource.Instantiate();
                float resourceScale = rngBase.RandfRange(0.8f, 2.0f);
                int childrenCount = resourceInstance.GetChildren().Count;
                int randResource = rngBase.RandiRange(0, childrenCount - 1);

                resourceInstance.Call("ShowResource", randResource);
                resourceInstance.Scale = new Vector3(resourceScale, resourceScale, resourceScale);
                resourceInstance.Rotation = new Vector3(Mathf.DegToRad(rngBase.RandiRange(-2, 2)), Mathf.DegToRad(rngBase.RandiRange(0, 359)), Mathf.DegToRad(rngBase.RandiRange(-2, 2)));

                if (trees.Contains(resource.Key))
				{
					return TreeParameters(resourceInstance, randResource, rngBase);
				}

                return resourceInstance;
            }
            diceRoll -= weight;
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

    private void ReseatResources(System.Collections.Generic.Dictionary<Vector3, Node3D> resourceData, Vector3 _authorizedPlayerPosition, int _authorizedPlayerResourceSpawnRadius)
    {
        Vector2 playerPos2D = new(_authorizedPlayerPosition.X, _authorizedPlayerPosition.Z);
        float spawnRadiusSquared = _authorizedPlayerResourceSpawnRadius * _authorizedPlayerResourceSpawnRadius;
        foreach (KeyValuePair<Vector3, Node3D> entry in resourceData)
        {
            Vector3 resourceLocation = entry.Key;
            Node node = entry.Value;
            if (node == null)
            {
                continue;
            }
            float distanceSquared = new Vector2(resourceLocation.X, resourceLocation.Z).DistanceSquaredTo(playerPos2D);
            if (distanceSquared < spawnRadiusSquared && node.GetParent() == null)
            {
                GetParent().AddChild(node);
            }
            else if (distanceSquared >= spawnRadiusSquared && node.GetParent() != null)
            {
                GetParent().RemoveChild(node);
            }
        }
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
