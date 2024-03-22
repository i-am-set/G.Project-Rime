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
	private static readonly PackedScene birchTreeCollider = GD.Load<PackedScene>("res://scenes/resourceobjects/nature/trees/colliders/col_birch_tree.tscn");

    private Queue<StaticBody3D> queuedBirchTreeColliderPool = new();

	private static readonly PackedScene pineTree = GD.Load<PackedScene>("res://scenes/resourceobjects/nature/trees/pine_tree_controller.tscn");
	private static readonly PackedScene pineTreeCollider = GD.Load<PackedScene>("res://scenes/resourceobjects/nature/trees/colliders/col_pine_tree.tscn");

    private Queue<StaticBody3D> queuedPineTreeColliderPool = new();
	
	private static readonly PackedScene tallPineTree = GD.Load<PackedScene>("res://scenes/resourceobjects/nature/trees/tall_pine_tree_controller.tscn");
	private static readonly PackedScene tallPineTreeCollider = GD.Load<PackedScene>("res://scenes/resourceobjects/nature/trees/colliders/col_tall_pine_tree.tscn");

    private Queue<StaticBody3D> queuedTallPineTreeColliderPool = new();


	private readonly PackedScene[] trees = new PackedScene[]
	{
		birchTree,
		pineTree,
		tallPineTree
	};

	// #-------------------- Nodes ---------------------#
	private static readonly PackedScene flintNode = GD.Load<PackedScene>("res://scenes/resourceobjects/nature/nodes/flint_node_controller.tscn");
	private static readonly PackedScene flintNodeCollider = GD.Load<PackedScene>("res://scenes/resourceobjects/nature/nodes/colliders/col_flint_node.tscn");

    private Queue<StaticBody3D> queuedFlintNodeColliderPool = new();

	private static readonly PackedScene stoneNode = GD.Load<PackedScene>("res://scenes/resourceobjects/nature/nodes/stone_node_controller.tscn");
	private static readonly PackedScene stoneNodeCollider = GD.Load<PackedScene>("res://scenes/resourceobjects/nature/nodes/colliders/col_stone_node.tscn");

    private Queue<StaticBody3D> queuedStoneNodeColliderPool = new();

	
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

    private System.Collections.Generic.Dictionary<PackedScene, Queue<StaticBody3D>> colliders = new();

    private int tick = 0;
    private Vector3 authorizedPlayerPosition = new();
    private int authorizedPlayerResourceSpawnRadius = 10;
    private int authorizedPlayerResourceSpawnRadiusHalf = 5;
    private FastNoiseLite noise = (FastNoiseLite)GD.Load("res://world/heightmap/resource_noise.tres");
    private FastNoiseLite noiseMask = (FastNoiseLite)GD.Load("res://world/heightmap/resource_noise_mask.tres");
    private PackedScene testObject = (PackedScene)GD.Load("res://scenes/test_object.tscn");
    private bool isGeneratingResources = false;

    private System.Collections.Generic.Dictionary<Vector3, PackedScene> resourceData = new();
    int resourceDataCountCached = 0;
    private System.Collections.Generic.Dictionary<PackedScene, Node3D> resourceColliderData = new();
    private Queue<ResourceInfo> queuedResourceForReseating = new();
    private System.Collections.Generic.Dictionary<Vector3, Node3D> seatedResourcesData = new();
    private System.Collections.Generic.Dictionary<Vector3, StaticBody3D> resourcePositionsWithColliders = new();
    private List<Vector3> resourcePositionsCloseToThePlayer = new();

    private static int positionsPerFrame = 5;
    private Timer initGenerationTimer;

    private bool isWeightSystemInitialized = false;
	private float totalWeight = 0;
	private RandomNumberGenerator rngBase = new();


    public override void _Ready(){
        InitializeChunkLoadingSpeed();
        InitiateWeightSystem();
        InitializeColliderDictionary();
    }

    public override void _PhysicsProcess(double delta){
        for (int i = 0; i < positionsPerFrame; i++){
            if (queuedResourceForReseating.Count > 0){
                ResourceInfo resourceInfo = queuedResourceForReseating.Dequeue();
                if(resourceData.ContainsKey(resourceInfo.position)){
                }
                ReseatResource(resourceInfo.position, resourceInfo.parent);
            }
        }
    }

    private void InitializeChunkLoadingSpeed(){
        positionsPerFrame = 500;

        initGenerationTimer = new Timer();
        AddChild(initGenerationTimer);
        initGenerationTimer.WaitTime = 5.0f;
        initGenerationTimer.OneShot = true;
        Action myAction = () => { SetChunkLoadingSpeed(); };
        initGenerationTimer.Connect("timeout", Callable.From(myAction));
        initGenerationTimer.Start();
    }

    private void SetChunkLoadingSpeed(){
        positionsPerFrame = 5;
    }

	private void InitiateWeightSystem(){
		if (!isWeightSystemInitialized)
		{
			foreach (var resource in weights)
			{
				totalWeight += weights[resource.Key];
			}
			isWeightSystemInitialized = true;
		}
	}

    private void InitializeColliderDictionary(){
        colliders = new System.Collections.Generic.Dictionary<PackedScene, Queue<StaticBody3D>>(){
            { birchTree, queuedBirchTreeColliderPool },
            { pineTree, queuedPineTreeColliderPool },
            { tallPineTree, queuedTallPineTreeColliderPool },
            { flintNode, queuedFlintNodeColliderPool },
            { stoneNode, queuedStoneNodeColliderPool }
        };

        foreach (var key in colliders.Keys.ToList()){
            if (key == birchTree){
                GD.Print("Instancing birch colliders");
                for (int i = 0; i < 20; i++){
                    StaticBody3D body = (StaticBody3D)birchTreeCollider.Instantiate();
                    CallDeferred("add_child", body);
                    body.Position = new Vector3(0, -10000, 0);
                    colliders[key].Enqueue(body);
                }
            } else if (key == pineTree) {
                GD.Print("Instancing pine colliders");
                for (int i = 0; i < 20; i++){
                    StaticBody3D body = (StaticBody3D)pineTreeCollider.Instantiate();
                    CallDeferred("add_child", body);
                    body.Position = new Vector3(0, -10000, 0);
                    colliders[key].Enqueue(body);
                }
            } else if (key == tallPineTree) {
                GD.Print("Instancing tall pine colliders");
                for (int i = 0; i < 20; i++){
                    StaticBody3D body = (StaticBody3D)tallPineTreeCollider.Instantiate();
                    CallDeferred("add_child", body);
                    body.Position = new Vector3(0, -10000, 0);
                    colliders[key].Enqueue(body);
                }
            } else if (key == flintNode) {
                GD.Print("Instancing flint colliders");
                for (int i = 0; i < 20; i++){
                    StaticBody3D body = (StaticBody3D)flintNodeCollider.Instantiate();
                    CallDeferred("add_child", body);
                    body.Position = new Vector3(0, -10000, 0);
                    colliders[key].Enqueue(body);
                }
            } else if (key == stoneNode) {
                GD.Print("Instancing stone colliders");
                for (int i = 0; i < 20; i++){
                    StaticBody3D body = (StaticBody3D)stoneNodeCollider.Instantiate();
                    CallDeferred("add_child", body);
                    body.Position = new Vector3(0, -10000, 0);
                    colliders[key].Enqueue(body);
                }
            } else {
                GD.Print("Key entry doesn't exist in 'colliders'");
            }
        }
    }

    public bool TryToSetLocalResources(Vector3 resourcePosition){
        resourceDataCountCached = resourceData.Count;
        resourceData = FindResource(resourceData, resourcePosition);
        
        if(resourceDataCountCached != resourceData.Count){
            return true;
        }

        return false;
    }

    private System.Collections.Generic.Dictionary<Vector3, PackedScene> FindResource(System.Collections.Generic.Dictionary<Vector3, PackedScene> resourceData, Vector3 resourcePosition){
        float mappedNoise = noise.GetNoise2D(resourcePosition.X, resourcePosition.Z) * 100;
        // float maskedNoise = noiseMask.GetNoise2D(resourcePosition.X, resourcePosition.Z) * 100;
        // float finalNoise = mappedNoise + maskedNoise;
        if (mappedNoise > 0.125){
            if (!resourceData.ContainsKey(resourcePosition)){
                PackedScene resource = RollResource((ulong)(mappedNoise * 100));
                resourceData[resourcePosition] = resource;
            }
        }

        return resourceData;
    }

    private PackedScene RollResource(ulong heightSeed){
        rngBase.Seed = heightSeed;
        float diceRoll = rngBase.RandfRange(0, totalWeight);
        
        foreach (KeyValuePair<PackedScene, float> resource in weights){
            float weight = (float)weights[resource.Key];
            if (weight >= diceRoll){
                return resource.Key;
            }
            diceRoll -= weight;
        }

        GD.PrintErr("failed to roll a resource");

        return null;
    }

    private Node3D InstantiateResource(PackedScene currentResource, ulong bitwiseXORSeed){
        Node3D resourceInstance = (Node3D)currentResource.Instantiate();
        rngBase.Seed = bitwiseXORSeed;
        float resourceScale = rngBase.RandfRange(0.75f, 2.5f);
        int childrenCount = resourceInstance.GetChildren().Count;
        int randResource = rngBase.RandiRange(0, childrenCount - 1);

        resourceInstance.Call("ShowResource", randResource);
        resourceInstance.Scale = new Vector3(resourceScale, resourceScale, resourceScale);
        resourceInstance.Rotation = new Vector3(Mathf.DegToRad(rngBase.RandiRange(-5, 5)), Mathf.DegToRad(rngBase.RandiRange(0, 359)), Mathf.DegToRad(rngBase.RandiRange(-5, 5)));

        if (trees.Contains(currentResource)){
        	return TreeParameters(resourceInstance, randResource, rngBase);
        }

        return resourceInstance;
    }

    private Node3D TreeParameters(Node3D tree, int treeNumber, RandomNumberGenerator rngBase)
    {
        MeshInstance3D firstChild = (MeshInstance3D)tree.GetChild(treeNumber).GetChild(0);
		Material firstChildMaterial = firstChild.MaterialOverride;
		firstChildMaterial = (ShaderMaterial)firstChildMaterial.Duplicate();
		var treeShader = (ShaderMaterial)firstChildMaterial;
		firstChildMaterial.Set("lod_bias", 0.2);
		treeShader.SetShaderParameter("tree_base_height", rngBase.RandfRange(0.1f, 1.0f));
		// treeShader.SetShaderParameter("tree_base_darkness", rngBase.RandfRange(0.1f, 0.2f));
		treeShader.SetShaderParameter("uv1_offset", new Vector3(rngBase.RandfRange(1, 20), 1, 1));
        firstChild.MaterialOverride = firstChildMaterial;

        return tree;
    }

    public void QueueNextReseatedResource(Vector3 resourcePosition, Node3D resourceParent){
        ResourceInfo resourceInfo = new ResourceInfo(resourcePosition, resourceParent);
        queuedResourceForReseating.Enqueue(resourceInfo);
    }

    void ReseatResource(Vector3 resourcePosition, Node3D resourceParent){
        if (resourceData.ContainsKey(resourcePosition)){
            if(!seatedResourcesData.ContainsKey(resourcePosition)){
                Node3D resource = InstantiateResource(resourceData[resourcePosition], (ulong)((int)resourcePosition.Y ^ (int)resourcePosition.Z));
                resourceParent.CallDeferred("add_child", resource);
                resource.Position = resourcePosition;
                seatedResourcesData[resourcePosition] = resource;
            } else {
                seatedResourcesData[resourcePosition].Position = resourcePosition;
            }
        }
    }

    public void DisplaceResource(Vector3 resourcePosition){
        if (seatedResourcesData.ContainsKey(resourcePosition)){
            seatedResourcesData[resourcePosition].Position = new Vector3(0, -10000, 0);
        }
    }
    
    public void SetCloseResourcePositions(List<Vector3> givenResourcePositionsCloseToThePlayer){
        foreach (KeyValuePair<Vector3, StaticBody3D> entry in resourcePositionsWithColliders){
            Vector3 position = entry.Key;
            StaticBody3D body = entry.Value;

            if(!givenResourcePositionsCloseToThePlayer.Contains(position)){
                if (resourceData.TryGetValue(position, out PackedScene scene)){
                    if (colliders.TryGetValue(scene, out Queue<StaticBody3D> bodies)){
                        body.Position = new Vector3(0, -10000, 0);
                        bodies.Enqueue(body);
                    }
                }
                resourcePositionsWithColliders.Remove(position);
            }
        }

        foreach (Vector3 position in givenResourcePositionsCloseToThePlayer){
            if (!resourcePositionsWithColliders.ContainsKey(position)){
                if (resourceData.TryGetValue(position, out PackedScene scene)){
                    if (colliders.TryGetValue(scene, out Queue<StaticBody3D> bodies) && bodies.Count > 0 && seatedResourcesData.TryGetValue(position, out Node3D resource)){
                        StaticBody3D body = bodies.Dequeue();
                        body.Position = position;
                        body.Scale = resource.Scale;
                        body.Rotation = resource.Rotation;
                        int bodyChildCount = body.GetChildCount();
                        if(bodyChildCount > 1){
                            Godot.Collections.Array<Godot.Node> resourceChildren = resource.GetChildren();
                            int resourceChildCount = resourceChildren.Count;
                            if (bodyChildCount == resourceChildCount){
                                int childIndex = -1;
                                Godot.Collections.Array<Godot.Node> bodyChildren = body.GetChildren();
                                Node3D resourceChild; 
                                CollisionShape3D bodyChild;

                                for (int i = 0; i < resourceChildCount; i++){
                                    resourceChild = (Node3D)resourceChildren[i];
                                    bodyChild = (CollisionShape3D)bodyChildren[i];

                                    if (resourceChild.Visible){ childIndex = i;bodyChild.Disabled = false; GD.PrintErr(position); } else { bodyChild.Disabled = true; }
                                }

                                if(childIndex <= -1){ GD.PrintErr("Zero visible children in ", resource, " : ", scene, " : ", position); }
                            } else {
                                GD.PrintErr("dont match");
                            }
                        }
                        resourcePositionsWithColliders[position] = body;
                    } else {
                        GD.Print("No available bodies for scene: " + scene);
                    }
                } else {
                    GD.Print("No scene for position: " + position);
                }
            }
        }
    }

    struct ResourceInfo {
        public readonly Vector3 position;
        public readonly Node3D parent;

        public ResourceInfo(Vector3 position, Node3D parent)
        {
            this.position = position;
            this.parent = parent;
        }
    }
}
