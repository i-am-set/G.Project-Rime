using Godot;
using System;
using System.Collections.Generic;
using System.Linq;

public partial class ResourceInstancer : Node3D
{
	// Trees
	private static PackedScene[] birchTree = new PackedScene[]
	{
		GD.Load<PackedScene>("res://scenes/resourceobjects/nature/trees/birch_tree_1.tscn"),
		GD.Load<PackedScene>("res://scenes/resourceobjects/nature/trees/birch_tree_2.tscn"),
		GD.Load<PackedScene>("res://scenes/resourceobjects/nature/trees/birch_tree_3.tscn"),
		GD.Load<PackedScene>("res://scenes/resourceobjects/nature/trees/birch_tree_4.tscn")
	};

	private static PackedScene[] pineTree = new PackedScene[]
	{
		GD.Load<PackedScene>("res://scenes/resourceobjects/nature/trees/pine_tree_1.tscn"),
		GD.Load<PackedScene>("res://scenes/resourceobjects/nature/trees/pine_tree_2.tscn"),
		GD.Load<PackedScene>("res://scenes/resourceobjects/nature/trees/pine_tree_3.tscn"),
		GD.Load<PackedScene>("res://scenes/resourceobjects/nature/trees/pine_tree_4.tscn")
	};
	
	private static PackedScene[] tallPineTree = new PackedScene[]
	{
		GD.Load<PackedScene>("res://scenes/resourceobjects/nature/trees/tall_pine_tree_1.tscn"),
		GD.Load<PackedScene>("res://scenes/resourceobjects/nature/trees/tall_pine_tree_2.tscn")
	};

	private Array[] trees = new Array[]
	{
		birchTree,
		pineTree,
		tallPineTree
	};

	private Dictionary<PackedScene[], float> weights = new Dictionary<PackedScene[], float>()
	{
		{ birchTree, 3.0f },
		{ pineTree, 0.5f },
		{ tallPineTree, 10.0f }
	};

	private bool isInitialized = false;
	private float totalWeight = 0;
	private RandomNumberGenerator rngBase = new RandomNumberGenerator();

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

	public Node3D InstantiateResource(int heightSeed)
	{
		InitiateWeightSystem();

		rngBase.Seed = (ulong)heightSeed;
		var diceRoll = rngBase.RandfRange(0, totalWeight);

		foreach (var resource in weights)
		{
			if (weights[resource.Key] >= diceRoll)
			{
				var randResource = rngBase.RandiRange(0, resource.Key.Length - 1);
				var resourceInstance = (Node3D)resource.Key[randResource].Instantiate();
				var resourceScale = rngBase.RandfRange(0.8f, 2.0f);
				resourceInstance.Scale = new Vector3(resourceScale, resourceScale, resourceScale);
				resourceInstance.Rotation = new Vector3(DegToRad(rngBase.RandiRange(-2, 2)), DegToRad(rngBase.RandiRange(0, 359)), DegToRad(rngBase.RandiRange(-2, 2)));
				
				if (trees.Contains(resource.Key))
				{
					return TreeParameters(resourceInstance);
				}

				return resourceInstance;
			}
			diceRoll -= weights[resource.Key];
		}

		GD.PrintErr("Failed to roll a resource");
		return null;
	}

	private Node3D TreeParameters(Node3D tree)
	{
		// var Global = GetNode("/root/Global");
		// var firstChild = tree.GetChild(0);
		// var firstChildName = firstChild.GetPath();
		// var firstChildMaterial = GetNode<MeshInstance3D>(firstChildName).MaterialOverride;
		// var LODRange = (int)Global.Call("get_render_distance") * 6;
		// firstChildMaterial = (ShaderMaterial)firstChildMaterial.Duplicate();
		// var treeShader = (ShaderMaterial)firstChildMaterial;
		// firstChildMaterial.Set("lod_bias", 0.25f);
		// treeShader.SetShaderParameter("tree_base_height", rngBase.RandfRange(0.1f, 1.2f));
		// treeShader.SetShaderParameter("tree_base_darkness", rngBase.RandfRange(0.1f, 0.2f));
		// treeShader.SetShaderParameter("uv1_offset", new Vector3(rngBase.RandfRange(1, 20), 1, 1));

		return tree;
	}

	private float DegToRad(float inputDegrees)
	{
		float outputRadians = (float)((Math.PI / 180) * inputDegrees);
		return outputRadians;
	}
}
