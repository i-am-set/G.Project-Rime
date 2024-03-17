using Godot;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Intrinsics;

[Tool]
public partial class PregenTerrain : Node3D
{
	const float scale = 4.0f;

	const float viewerMoveThresholdForChunkUpdate = 5f;
	const float sqrViewerMoveThresholdForChunkUpdate = viewerMoveThresholdForChunkUpdate * viewerMoveThresholdForChunkUpdate;
	const float colliderGenerationDistanceThreshold = 35;

	[Export]public int colliderLODIndex;
	[Export] public LODInfo[] detailLevels;
    public static float maxViewDst;
    int chunksVisibleInViewDst;
    int chunkSize;
	[Export(PropertyHint.Range, "1, 50")] public int worldSize = 3;

    [Export] public Node3D viewer;
	[Export] public ShaderMaterial shaderMaterial;

	[Export] public bool generateWorld = false;

    public static Vector2 viewerPosition;
	Vector2 viewerPositionOld;
	static MapGenerator mapGenerator;
	static ResourceChunkInstancer resourceChunkInstancer;

	// bool hasWorldBeenGenerated = false;

    Dictionary<Vector2, TerrainChunk> TerrainChunkDictionary = new();
    static List<TerrainChunk> visibleTerrainChunks = new();

    // public override void _Ready(){
	void StartWorld(){
		mapGenerator = (MapGenerator)GetParent();
		resourceChunkInstancer = (ResourceChunkInstancer)mapGenerator.GetNode("ResourceChunkInstancer");

		maxViewDst = detailLevels[detailLevels.Length-1].visibleDstThreshold;
        chunkSize = mapGenerator.mapChunkSize - 1;
        chunksVisibleInViewDst = Mathf.RoundToInt(maxViewDst / chunkSize);

		GenerateWorld();

		UpdateVisibleChunks();
    }

	public override void _Process(double delta){
		viewerPosition = new Vector2(viewer.Position.X, viewer.Position.Z) / scale;

		if (generateWorld){
			generateWorld = false;
			StartWorld();
		}

		if (viewerPosition != viewerPositionOld){
			foreach (TerrainChunk chunk in visibleTerrainChunks){
				chunk.UpdateCollisionMesh();
			}
		}
	}

    public override void _PhysicsProcess(double delta){
        viewerPosition = new Vector2(viewer.Position.X, viewer.Position.Z) / scale;

		if ((viewerPositionOld - viewerPosition).LengthSquared() > sqrViewerMoveThresholdForChunkUpdate){
			viewerPositionOld = viewerPosition;
        	UpdateVisibleChunks();
		}
    }

	// generate world
	void GenerateWorld(){
		int interation = 0;
		for (int i = 0; i < worldSize; i++){
			for (int j = 0; j < worldSize; j++){
				Vector2 chunkCoord = new(i, j);
				TerrainChunk terrainChunk = new TerrainChunk(chunkCoord, chunkSize, detailLevels, colliderLODIndex, this, shaderMaterial, interation += 1);
				TerrainChunkDictionary.Add(chunkCoord, terrainChunk);
			}
		}
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
        Aabb Bounds;

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
		bool hasFullyGenerated = false;

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
			if (!hasFullyGenerated && lodMeshes[colliderLODIndex].hasMesh){
				GenerateResources();
				hasFullyGenerated = true;
			}

			if (mapDataReceived) {
				float viewerDstFromNearestEdge = Bounds.Position.DistanceTo(new Vector3(viewerPosition.X, 0, viewerPosition.Y));

				bool wasVisible = IsVisible();
				bool visible = viewerDstFromNearestEdge <= maxViewDst;
				if (!hasFullyGenerated){
					lodMeshes[colliderLODIndex].RequestMesh(mapData, chunkPosition, scale, staticBody);
				}

				if(visible){
					int lodIndex = 0;

					for (int i = 0; i < detailLevels.Length-1; i++){
						if (viewerDstFromNearestEdge > detailLevels[i].visibleDstThreshold) {
							lodIndex = i + 1;
						} else {
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

				if (wasVisible != visible) {
					if (visible) {
						visibleTerrainChunks.Add(this);
						if (hasFullyGenerated){
							resourceChunkInstancer.ReseatResources(chunkVertices, resourceParent);
						}
					} else {
						visibleTerrainChunks.Remove(this);
						resourceChunkInstancer.DisplaceResource(chunkVertices);
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
		void GenerateResources(){
			chunkVertices = GetCollisionLODMeshVertices();
			if (chunkVertices == null){
				GD.Print(chunkNumber, " ------ ", chunkPosition, " : Failed to find Vertices");
				return;
			}
			GD.Print(chunkNumber, " =========== ", chunkPosition, " : Generating Resources");
			for (int i = 0; i < chunkVertices.Length; i++){
				resourceChunkInstancer.GenerateLocalResources(new Vector3(chunkVertices[i].X + chunkPosition.X, chunkVertices[i].Y, chunkVertices[i].Z + chunkPosition.Y)*scale);
			}
		}

		Vector3[] GetCollisionLODMeshVertices(){
		if (lodMeshes[colliderLODIndex].hasMesh){
			return lodMeshes[colliderLODIndex].meshData.vertices;
		}
		
		return null;
		}

        public void SetVisible(bool visible){
			staticBody.SetCollisionLayerValue(1, visible);
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