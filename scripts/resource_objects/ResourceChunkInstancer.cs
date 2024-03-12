using System;
using System.Collections.Generic;
using System.Linq;
using Godot;

[Tool]
public partial class ResourceChunkInstancer : Node3D
{
    // #-------------------- Trees ---------------------------#
	private static readonly PackedScene birchTree = GD.Load<PackedScene>("res://scenes/resourceobjects/nature/trees/birch_tree_controller.tscn");

	private static readonly PackedScene pineTree = GD.Load<PackedScene>("res://scenes/resourceobjects/nature/trees/pine_tree_controller.tscn");
	
	private static readonly PackedScene tallPineTree = GD.Load<PackedScene>("res://scenes/resourceobjects/nature/trees/tall_pine_tree_controller.tscn");

	private readonly PackedScene[] trees = new PackedScene[]
	{
		birchTree,
		pineTree,
		tallPineTree
	};

	// #-------------------- Nodes ---------------------#
	private static readonly PackedScene flintNode = GD.Load<PackedScene>("res://scenes/resourceobjects/nature/nodes/flint_node_controller.tscn");

	private static readonly PackedScene stoneNode = GD.Load<PackedScene>("res://scenes/resourceobjects/nature/nodes/stone_node_controller.tscn");
	
	private readonly PackedScene[] nodes = new PackedScene[]
	{
		flintNode,
		stoneNode
	};

	// #-------------------- Shrubs ---------------------#
	private static readonly PackedScene richTwigShrub = GD.Load<PackedScene>("res://scenes/resourceobjects/nature/shrub/rich_twig_shrub_controller.tscn");

	private static readonly PackedScene poorTwigShrub = GD.Load<PackedScene>("res://scenes/resourceobjects/nature/shrub/poor_twig_shrub_controller.tscn");

	private readonly PackedScene[] shrubs = new PackedScene[]
	{
		richTwigShrub,
        poorTwigShrub
	};

	// #------------------------------------------------------#

	private readonly System.Collections.Generic.Dictionary<PackedScene, float> weights = new()
	{
		{ birchTree, 3.0f },
		{ pineTree, 0.5f },
		{ tallPineTree, 10.0f },
		{ flintNode, 0.2f },
		{ stoneNode, 0.1f },
		{ richTwigShrub, 0.3f },
        { poorTwigShrub, 0.1f }
	};

    private HashSet<Vector2> cachedPositions = new();
    private int tick = 0;
    private Vector3 authorizedPlayerPosition = new();
    private int authorizedPlayerResourceSpawnRadius = 10;
    private int authorizedPlayerResourceSpawnRadiusHalf = 5;
    private System.Collections.Generic.Dictionary<Vector3, Node3D> resourceData = new();
    private FastNoiseLite noise = (FastNoiseLite)GD.Load("res://world/heightmap/resource_noise.tres");
    private PackedScene testObject = (PackedScene)GD.Load("res://scenes/test_object.tscn");
    private bool isGeneratingResources = false;

    Queue<Vector3> queuedResourcePositions = new Queue<Vector3>();
    private int currentX, currentZ;
    private const int positionsPerFrame = 50;

    private bool isInitialized = false;
	private float totalWeight = 0;
	private RandomNumberGenerator rngBase = new();


    public override void _Ready()
    {
        InitiateWeightSystem();
    }

    // public override void _Process(double delta){
    //     GenerateLocalResources();
    // }

	private void InitiateWeightSystem()
	{
		if (!isInitialized)
		{
			foreach (var resource in weights)
			{
				totalWeight += weights[resource.Key];
			}
			isInitialized = true;
		}
	}

    public void GenerateLocalResources(Vector3 resourcePosition){   
        resourceData = IterateThroughResources(authorizedPlayerPosition, authorizedPlayerResourceSpawnRadiusHalf, noise, resourceData, resourcePosition);
        
        isGeneratingResources = false;
    }

    private System.Collections.Generic.Dictionary<Vector3, Node3D> IterateThroughResources(Vector3 authorizedPlayerPosition, float authorizedPlayerResourceSpawnRadiusHalf, Noise noise, System.Collections.Generic.Dictionary<Vector3, Node3D> resourceData, Vector3 resourcePosition){
        Node3D resource = (Node3D)testObject.Instantiate();
        CallDeferred("add_child", resource);
        resource.Position = resourcePosition;

        // Vector2 cachedPosition = new();
        // Vector3 resourcePosition = new();

        // for (int i = 0; i < positionsPerFrame; i++)
        // {
        //     cachedPosition.X = currentX;
        //     cachedPosition.Y = currentZ;
        //     if (!cachedPositions.Contains(cachedPosition))
        //     {
        //         cachedPositions.Add(cachedPosition);
        //         float height = noise.GetNoise2D(currentX, currentZ) * 100;
        //         float heightmapY = (float)Heightmap.Call("get_height", currentX, currentZ);
        //         if (height > 0.425)
        //         {
        //             resourcePosition.X = currentX;
        //             resourcePosition.Y = heightmapY;
        //             resourcePosition.Z = currentZ;
        //             if (!resourceData.ContainsKey(resourcePosition))
        //             {
        //                 Node3D resource = InstantiateResource((ulong)(height * 100), GetParent());
        //                 resource.Position = resourcePosition;
        //                 resourceData[resourcePosition] = resource;
        //             }
        //         }
        //     }

        //     // Update currentX and currentZ for the next frame
        //     currentZ++;
        //     if (currentZ >= authorizedPlayerPosition.Z + authorizedPlayerResourceSpawnRadiusHalf)
        //     {
        //         currentZ = (int)(authorizedPlayerPosition.Z - authorizedPlayerResourceSpawnRadiusHalf);
        //         currentX++;
        //         if (currentX >= authorizedPlayerPosition.X + authorizedPlayerResourceSpawnRadiusHalf)
        //         {
        //             // We've finished processing the entire area
        //             // Reset currentX and currentZ to the start of the area
        //             currentX = (int)(authorizedPlayerPosition.X - authorizedPlayerResourceSpawnRadiusHalf);
        //         }
        //     }
        // }

        return resourceData;
    }

    private Node3D InstantiateResource(ulong heightSeed, Node parent)
    {
        rngBase.Seed = heightSeed;
        float diceRoll = rngBase.RandfRange(0, totalWeight);
        
        foreach (var resource in weights)
        {
            float weight = (float)weights[resource.Key];
            if (weight >= diceRoll)
            {
                PackedScene currentResource = (PackedScene)resource.Key;
                Node3D resourceInstance = (Node3D)currentResource.Instantiate();
                float resourceScale = rngBase.RandfRange(0.4f, 2.5f);
                int childrenCount = resourceInstance.GetChildren().Count;
                int randResource = rngBase.RandiRange(0, childrenCount - 1);

                resourceInstance.Call("ShowResource", randResource);
                resourceInstance.Scale = new Vector3(resourceScale, resourceScale, resourceScale);
                resourceInstance.Rotation = new Vector3(Mathf.DegToRad(rngBase.RandiRange(-5, 5)), Mathf.DegToRad(rngBase.RandiRange(0, 359)), Mathf.DegToRad(rngBase.RandiRange(-5, 5)));

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
}
