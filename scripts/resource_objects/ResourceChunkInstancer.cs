using System;
using System.Collections;
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

    private int tick = 0;
    private Vector3 authorizedPlayerPosition = new();
    private int authorizedPlayerResourceSpawnRadius = 10;
    private int authorizedPlayerResourceSpawnRadiusHalf = 5;
    private FastNoiseLite noise = (FastNoiseLite)GD.Load("res://world/heightmap/resource_noise.tres");
    private PackedScene testObject = (PackedScene)GD.Load("res://scenes/test_object.tscn");
    private bool isGeneratingResources = false;

    private System.Collections.Generic.Dictionary<Vector3, PackedScene> resourceData = new();
    private System.Collections.Generic.Dictionary<Vector3, Node3D> seatedResourcesData = new();
    private const int positionsPerFrame = 150;

    private bool isInitialized = false;
	private float totalWeight = 0;
	private RandomNumberGenerator rngBase = new();


    public override void _Ready()
    {
        InitiateWeightSystem();
    }

    // public override void _PhysicsProcess(double delta){
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
        resourceData = IterateThroughResources(resourceData, resourcePosition);
        GD.Print(resourceData.Count, " resources");
    }

    private System.Collections.Generic.Dictionary<Vector3, PackedScene> IterateThroughResources(System.Collections.Generic.Dictionary<Vector3, PackedScene> resourceData, Vector3 resourcePosition){
        float mappedNoise = noise.GetNoise2D(resourcePosition.X, resourcePosition.Z) * 100;
        if (mappedNoise > 0.125){
            if (!resourceData.ContainsKey(resourcePosition)){
                PackedScene resource = RollResource((ulong)(mappedNoise * 100));
                // Node3D resource = (Node3D)testObject.Instantiate();
                // resourceParent.CallDeferred("add_child", resource);
                resourceData[resourcePosition] = resource;
            }
        }

        return resourceData;
    }

    private PackedScene RollResource(ulong heightSeed){
        rngBase.Seed = heightSeed;
        float diceRoll = rngBase.RandfRange(0, totalWeight);
        
        foreach (var resource in weights){
            float weight = (float)weights[resource.Key];
            if (weight >= diceRoll)
            {
                // PackedScene currentResource = (PackedScene)resource.Key;
                // Node3D resourceInstance = (Node3D)currentResource.Instantiate();
                // float resourceScale = rngBase.RandfRange(0.4f, 2.5f);
                // int childrenCount = resourceInstance.GetChildren().Count;
                // int randResource = rngBase.RandiRange(0, childrenCount - 1);

                // resourceInstance.Call("ShowResource", randResource);
                // resourceInstance.Scale = new Vector3(resourceScale, resourceScale, resourceScale);
                // resourceInstance.Rotation = new Vector3(Mathf.DegToRad(rngBase.RandiRange(-5, 5)), Mathf.DegToRad(rngBase.RandiRange(0, 359)), Mathf.DegToRad(rngBase.RandiRange(-5, 5)));

                // if (trees.Contains(resource.Key))
				// {
				// 	TreeParameters(resourceInstance, randResource, rngBase);
				// }

                return resource.Key;
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

    public void ReseatResources(Vector3[] possibleResourcePositions, Node3D resourceParent){
        for (int i = 0; i < possibleResourcePositions.Length; i++){
            if (resourceData.ContainsKey(possibleResourcePositions[i])){
                Node3D resource = (Node3D)testObject.Instantiate();
                resourceParent.CallDeferred("add_child", resource);
                resource.Position = possibleResourcePositions[i];
                seatedResourcesData[possibleResourcePositions[i]] = resource;
            }
        }
    }

    public void DisplaceResource(Vector3[] possibleResourcePositions){
        for (int i = 0; i < possibleResourcePositions.Length; i++){
            if (seatedResourcesData.ContainsKey(possibleResourcePositions[i])){
                seatedResourcesData[possibleResourcePositions[i]].Position = new Vector3(0, -10000, 0);
                seatedResourcesData.Remove(possibleResourcePositions[i]);
            }
        }
    }
}
