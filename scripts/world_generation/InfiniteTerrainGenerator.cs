using Godot;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Intrinsics;

public partial class InfiniteTerrainGenerator : Node3D
{
	const float scale = 3.0f;

	const float viewerMoveThresholdForChunkUpdate = 5f;
	const float sqrViewerMoveThresholdForChunkUpdate = viewerMoveThresholdForChunkUpdate * viewerMoveThresholdForChunkUpdate;
	const float colliderGenerationDistanceThreshold = 35;

	[Export]public int colliderLODIndex;
	[Export] public LODInfo[] detailLevels;
    public static float maxViewDst;
    int chunksVisibleInViewDst;
    int chunkSize;
	[Export(PropertyHint.Range, "1, 50")] public int worldSize = 3;
	private int worldChunkAmount;

    [Export] public Node3D viewer;
	[Export] public ShaderMaterial shaderMaterial;

	[Export] public bool generateWorld = false;

	int latestChunkNumber = 0;
    public static Vector2 viewerPosition;
	public static Vector2 spawnPoint;
	public Vector2 viewerPositionOld;
	static MapGenerator mapGenerator;
	static ResourceChunkInstancer resourceChunkInstancer;

	// bool hasWorldBeenGenerated = false;

    Dictionary<Vector2, TerrainChunk> TerrainChunkDictionary = new();
    static List<TerrainChunk> visibleTerrainChunks = new();

    // public override void _Ready(){
	// 	if (!Engine.IsEditorHint()){
	// 		StartWorld();
    // 	}
	// }

	public override void _Ready(){
	// void StartWorld(){
		mapGenerator = (MapGenerator)GetParent();
		GD.Print(mapGenerator.seed);
		resourceChunkInstancer = (ResourceChunkInstancer)mapGenerator.GetNode("ResourceChunkInstancer");

		worldChunkAmount = worldSize * worldSize;
		maxViewDst = detailLevels[detailLevels.Length-1].visibleDstThreshold;
        chunkSize = mapGenerator.mapChunkSize - 1;
        chunksVisibleInViewDst = Mathf.RoundToInt(maxViewDst / chunkSize);

		GenerateWorld();

		UpdateVisibleChunks();

		// Vector2 firstChunkPosition = Vector2.Zero;
		// Vector2 lastChunkPosition = Vector2.Zero;
		// foreach (KeyValuePair<Vector2, TerrainChunk> item in TerrainChunkDictionary){
		// 	if (item.Value.chunkNumber == 1){
		// 		firstChunkPosition = item.Value.chunkPosition;
		// 	} else if (item.Value.chunkNumber == worldChunkAmount){
		// 		lastChunkPosition = item.Value.chunkPosition;
		// 	}
		// }
		// spawnPoint = (firstChunkPosition + lastChunkPosition) / 2;
		spawnPoint = Vector2.Zero;
		GetNode<Node>("/root/Global").Set("SPAWN_POINT", spawnPoint);
    }

	// public override void _Process(double delta){
	// 	if (generateWorld){
	// 		generateWorld = false;
	// 		StartWorld();
	// 	}
	// }

    

    public override void _PhysicsProcess(double delta){
        viewerPosition = new Vector2(viewer.Position.X, viewer.Position.Z) / scale;

		if (viewerPosition != viewerPositionOld){
			// set colliders close to player
			resourceChunkInstancer.SetCloseResourcePositions(GetCloseResourcePositions());

			// update terrain mesh collision
			foreach (TerrainChunk chunk in visibleTerrainChunks){
				chunk.UpdateCollisionMesh();
			}
		}

		if ((viewerPositionOld - viewerPosition).LengthSquared() > sqrViewerMoveThresholdForChunkUpdate){
			viewerPositionOld = viewerPosition;
        	UpdateVisibleChunks();
		}
    }

	// generate world
	void GenerateWorld(){
		for (int i = 0; i < worldSize; i++){
			for (int j = 0; j < worldSize; j++){
				Vector2 chunkCoord = new(i, j);
				latestChunkNumber++;
				TerrainChunk terrainChunk = new TerrainChunk(chunkCoord, chunkSize, detailLevels, colliderLODIndex, this, shaderMaterial, latestChunkNumber);
				TerrainChunkDictionary.Add(chunkCoord, terrainChunk);
			}
		}
	}

	private List<Vector3> GetCloseResourcePositions(){
        List<Vector3> resourcesNearPlayer = new();
		for (int i = 0; i < visibleTerrainChunks.Count; i++){
			if (visibleTerrainChunks[i].isPlayerClose){
				// resourcesNearPlayer.AddRange(visibleTerrainChunks[i].chunkResourcePositions);
				List<Vector3> chunkResourcePositions = visibleTerrainChunks[i].chunkResourcePositions;
				Vector3 cachedViewerPosition = viewer.Position;
				for (int j = 0; j < chunkResourcePositions.Count; j++){
					Vector3 closeResourcePosition = chunkResourcePositions[j];
					int distanceSqr = (int)cachedViewerPosition.DistanceSquaredTo(closeResourcePosition);
					if (distanceSqr < 100){
						resourcesNearPlayer.Add(closeResourcePosition);
					}
				}
			}
		}

		// if(resourcesNearPlayer.Count > 0){
		// 	GD.Print(String.Join(",", resourcesNearPlayer));
		// }

		return resourcesNearPlayer;
    }

    void UpdateVisibleChunks(){
		HashSet<Vector2> alreadyUpdatedChunkCoords = new();
		for (int i = visibleTerrainChunks.Count-1; i >= 0; i--){
			alreadyUpdatedChunkCoords.Add(visibleTerrainChunks[i].coord);
			visibleTerrainChunks[i].UpdateTerrainChunk();
		}
		
        int currentChunkCoordX = Mathf.RoundToInt(viewerPosition.X / chunkSize);
        int currentChunkCoordY = Mathf.RoundToInt(viewerPosition.Y / chunkSize);

        for (int yOffset = -chunksVisibleInViewDst; yOffset <= chunksVisibleInViewDst; yOffset++){
            for (int xOffset = -chunksVisibleInViewDst; xOffset <= chunksVisibleInViewDst; xOffset++){
                Vector2 viewedChunkCoord = new(currentChunkCoordX + xOffset, currentChunkCoordY + yOffset);
				if (!alreadyUpdatedChunkCoords.Contains(viewedChunkCoord)){
					if (TerrainChunkDictionary.ContainsKey(viewedChunkCoord)){
						TerrainChunkDictionary[viewedChunkCoord].UpdateTerrainChunk();
					} else {
						latestChunkNumber++;
						TerrainChunkDictionary.Add (viewedChunkCoord, new TerrainChunk(viewedChunkCoord, chunkSize, detailLevels, colliderLODIndex, this, shaderMaterial, latestChunkNumber));
					}
				}
            }
        }
    }

	[Tool]
    public class TerrainChunk{
		public Vector2 coord;

        MeshInstance3D meshObject;
		Node3D resourceParent;
        public Vector2 chunkPosition;
		Vector3[] chunkVertices;
		public List<Vector3> chunkResourcePositions = new();
        Aabb Bounds;

		public bool isPlayerClose = false;

		public StaticBody3D staticBody;
		CollisionShape3D meshCollider;
		public int chunkNumber;

		LODInfo[] detailLevels;
		LODMesh[] lodMeshes;
		int colliderLODIndex;

		MapData mapData;
		bool mapDataReceived;
		int previousLODIndex = -1;
		bool hasSetCollider;
		bool hasRolledResources = false;
		bool hasSeatedResources = false;

        public TerrainChunk(Vector2 coord, int size, LODInfo[] detailLevels, int colliderLODIndex, Node parent, ShaderMaterial shaderMaterial, int chunkNum){
			this.coord = coord;
			this.detailLevels = detailLevels;
			this.colliderLODIndex = colliderLODIndex;
			this.chunkNumber = chunkNum;

            chunkPosition = coord * size;
            Bounds = new Aabb(new Vector3(chunkPosition.X, 0, chunkPosition.Y), new Vector3(size, size, size));
			Vector3 positionV3 = new Vector3(chunkPosition.X, 0, chunkPosition.Y);
			
            meshObject = new MeshInstance3D
            {
				MaterialOverride = (Material)shaderMaterial.Duplicate(),
                Position = positionV3 * scale,
				Scale = Vector3.One * scale,
                Visible = false
            };
			resourceParent = new();
			staticBody = new();
			meshObject.AddChild(staticBody);
			meshCollider = new();
			staticBody.AddChild(meshCollider);
			parent.AddChild(resourceParent);
            parent.AddChild(meshObject);

			lodMeshes = new LODMesh[detailLevels.Length];
			for (int i = 0; i < detailLevels.Length; i++){
				lodMeshes[i] = new LODMesh(detailLevels[i].lod);
				lodMeshes[i].updateCallback += UpdateTerrainChunk;
				if (i == colliderLODIndex) {
					lodMeshes[i].updateCallback += UpdateCollisionMesh;
				}
			}

			mapGenerator.RequestMapData(chunkPosition, OnMapDataReceived);
        }

		private void OnMapDataReceived(MapData mapData){
			this.mapData = mapData;
			mapDataReceived = true;

			UpdateTerrainChunk();
		}

        public void UpdateTerrainChunk(){
			if (!hasRolledResources && lodMeshes[colliderLODIndex].hasMesh){
				RollResources();
				hasRolledResources = true;
			}

			if (mapDataReceived) {
				float viewerDstFromNearestEdge = Bounds.Position.DistanceTo(new Vector3(viewerPosition.X, 0, viewerPosition.Y));

				bool wasVisible = IsVisible();
				bool visible = viewerDstFromNearestEdge <= maxViewDst;
				if (!hasRolledResources){
					lodMeshes[colliderLODIndex].RequestMesh(mapData, chunkPosition, scale, staticBody);
				}

				if(visible){
					int lodIndex = 0;
					isPlayerClose = false;

					for (int i = 0; i < detailLevels.Length-1; i++){
						if (viewerDstFromNearestEdge > detailLevels[i].visibleDstThreshold) {
							lodIndex = i + 1;
						} else {
							if(detailLevels[i].lod == 0){
								isPlayerClose = true;
							}
							break;
						}
					}

					if (lodIndex != previousLODIndex){
						LODMesh lodMesh = lodMeshes[lodIndex];
						if (lodMesh.hasMesh) {
							previousLODIndex = lodIndex;
							meshObject.Mesh = lodMesh.mesh;
						} else if (!lodMesh.hasRequestedMesh){
							lodMesh.RequestMesh(mapData, chunkPosition, scale, staticBody);
						}
					}

				}

				if(hasRolledResources){
					if (visible){
						if (!hasSeatedResources){
							// GD.Print("Reseating resource in chunk ", chunkNumber);
							ReseatResources();
							hasSeatedResources = true;
						} else {
							GD.Print("Chunk ", chunkNumber, "'s resources are already seated...");
						}
					} else {
						if(hasSeatedResources){
							// GD.Print("Displacing resource in chunk ", chunkNumber);
							DisplaceResource();
							hasSeatedResources = false;
						} else {
							GD.Print("Chunk ", chunkNumber, "'s resources are already displaced...");
						}
					}
				}

				if (wasVisible != visible) {
					if (visible) {
						visibleTerrainChunks.Add(this);
					} else {
						visibleTerrainChunks.Remove(this);
					}
					SetVisible (visible);
				}
			}
        }

		public void UpdateCollisionMesh(){
			if(!hasSetCollider){
				float sqrDistanceFromViewerToEdge = Bounds.Position.DistanceSquaredTo(new Vector3(viewerPosition.X, 0, viewerPosition.Y));
				if (sqrDistanceFromViewerToEdge < detailLevels[colliderLODIndex].SqrVisibleDstThreshold){
					if (!lodMeshes[colliderLODIndex].hasRequestedMesh){
						lodMeshes[colliderLODIndex].RequestMesh(mapData, chunkPosition, scale, staticBody);
					}
				}

				if (sqrDistanceFromViewerToEdge < colliderGenerationDistanceThreshold * colliderGenerationDistanceThreshold){
					if (lodMeshes[colliderLODIndex].hasMesh){
						meshCollider.Shape = lodMeshes[colliderLODIndex].mesh.CreateTrimeshShape();
						hasSetCollider = true;
					}
				}
			}
		}

	// generate resources
		void RollResources(){
			chunkVertices = GetCollisionLODMeshVertices();
			if (chunkVertices == null){
				GD.Print(chunkNumber, " ------ ", chunkPosition, " : Failed to find Vertices");
				return;
			}
			GD.Print(chunkNumber, " =========== ", chunkPosition, " : Generating Resources");
			for (int i = 0; i < chunkVertices.Length; i++){
				bool isViableResourcePosition;
				Vector3 resourcePosition = new Vector3(chunkVertices[i].X + chunkPosition.X, chunkVertices[i].Y, chunkVertices[i].Z + chunkPosition.Y)*scale;
				isViableResourcePosition = resourceChunkInstancer.TryToSetLocalResources(resourcePosition);

				if (isViableResourcePosition){
					chunkResourcePositions.Add(resourcePosition);
				}
			}
		}

		void ReseatResources(){
			foreach (Vector3 resourcePosition in chunkResourcePositions){
				resourceChunkInstancer.QueueNextReseatedResource(resourcePosition, resourceParent);
			}
    	}

		public void DisplaceResource(){
			foreach (Vector3 resourcePosition in chunkResourcePositions){
				resourceChunkInstancer.DisplaceResource(resourcePosition);
			}
		}

	// get collisionLODMeshVertices
		Vector3[] GetCollisionLODMeshVertices(){
		if (lodMeshes[colliderLODIndex].hasMesh){
			return lodMeshes[colliderLODIndex].meshData.vertices;
		}
		
		return null;
		}

	// visibility logic
        public void SetVisible(bool visible){
			resourceParent.Visible = visible;
            meshObject.Visible = visible;
        }

        public bool IsVisible(){
            return meshObject.Visible;
        }
    }

	[Tool]
	public partial class LODMesh : Resource {

		public Mesh mesh;
		public MeshData meshData;
		public bool hasRequestedMesh;
		public bool hasMesh;
		int lod;
		public event System.Action updateCallback;

		public LODMesh(int lod) {
			this.lod = lod;
		}

		private void OnMeshDataReceived(MeshData tempMeshData) {
			meshData = tempMeshData;
			mesh = tempMeshData.CreateMesh();
			hasMesh = true;

			updateCallback();
		}

		public void RequestMesh(MapData mapData, Vector2 chunkPosition, float scale, StaticBody3D staticBody){
			hasRequestedMesh = true;
			mapGenerator.RequestMeshData(mapData, lod, chunkPosition, scale, staticBody, OnMeshDataReceived);
		}
	}
}