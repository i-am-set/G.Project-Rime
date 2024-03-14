using Godot;
using System;
using System.Collections.Generic;

[Tool]
public partial class PregenTerrain : Node3D
{
	const float scale = 24.0f;

	const float viewerMoveThresholdForChunkUpdate = 25f;
	const float sqrViewerMoveThresholdForChunkUpdate = viewerMoveThresholdForChunkUpdate * viewerMoveThresholdForChunkUpdate;
	const float colliderGenerationDistanceThreshold = 130;

	[Export] public int colliderLODIndex;
	[Export] public LODInfo[] detailLevels;
    public static float maxViewDst;

    [Export] public Node3D viewer;
	[Export] public ShaderMaterial shaderMaterial;

    public static Vector2 viewerPosition;
	Vector2 viewerPositionOld;
	static MapGenerator mapGenerator;
    int chunkSize;
	[Export(PropertyHint.Range, "1, 10")] public int worldSize = 3;
    int chunksVisibleInViewDst;

    Dictionary<Vector2, TerrainChunk> TerrainChunkDictionary = new();
    List<TerrainChunk> TerrainChunksVisibleLastUpdate = new();

    public override void _Ready()
    {
		mapGenerator = (MapGenerator)GetParent();

		maxViewDst = detailLevels[detailLevels.Length-1].visibleDstThreshold;
        chunkSize = mapGenerator.mapChunkSize - 1;
        chunksVisibleInViewDst = Mathf.RoundToInt(maxViewDst / chunkSize);

		GenerateWorld();

		UpdateVisibleChunks();
    }

	public override void _Process(double delta){
		viewerPosition = new Vector2(viewer.Position.X, viewer.Position.Z) / scale;

		if (viewerPosition != viewerPositionOld){
			foreach (TerrainChunk chunk in TerrainChunksVisibleLastUpdate){
				chunk.UpdateCollisionMesh();
			}
		}
	}

    public override void _PhysicsProcess(double delta)
    {
        viewerPosition = new Vector2(viewer.Position.X, viewer.Position.Z) / scale;

		if ((viewerPositionOld - viewerPosition).LengthSquared() > sqrViewerMoveThresholdForChunkUpdate){
			viewerPositionOld = viewerPosition;
        	UpdateVisibleChunks();
		}
    }

	void GenerateWorld()
	{
		int interation = 0;
		// generate terrain
		for (int i = 0; i < worldSize; i++){
			for (int j = 0; j < worldSize; j++){
				Vector2 chunkCoord = new(i, j);

				TerrainChunkDictionary.Add(chunkCoord, new TerrainChunk(chunkCoord, chunkSize, detailLevels, colliderLODIndex, this, shaderMaterial, interation += 1));
			}
		}

		// generate resources
		foreach (KeyValuePair<Vector2, TerrainChunk> entry in TerrainChunkDictionary){
			// Vector3[] terrainChunkVertices = entry.Value.GetCollisionLODMeshVertices();
			// for (int i = 0; i < terrainChunkVertices.Length; i++){
			// 	GD.Print(terrainChunkVertices[i]);
			// }
		}
	}

    void UpdateVisibleChunks()
    {
        foreach (var terrainChunk in TerrainChunksVisibleLastUpdate)
        {
            terrainChunk.SetVisible(false);
        }
        TerrainChunksVisibleLastUpdate.Clear();
		
        int currentChunkCoordX = Mathf.RoundToInt(viewerPosition.X / chunkSize);
        int currentChunkCoordY = Mathf.RoundToInt(viewerPosition.Y / chunkSize);

        for (int yOffset = -chunksVisibleInViewDst; yOffset <= chunksVisibleInViewDst; yOffset++){
            for (int xOffset = -chunksVisibleInViewDst; xOffset <= chunksVisibleInViewDst; xOffset++){
                Vector2 viewedChunkCoord = new(currentChunkCoordX + xOffset, currentChunkCoordY + yOffset);
				
                if (TerrainChunkDictionary.ContainsKey(viewedChunkCoord)){
                    TerrainChunkDictionary[viewedChunkCoord].UpdateTerrainChunk();
                    if (TerrainChunkDictionary[viewedChunkCoord].IsVisible()){
                        TerrainChunksVisibleLastUpdate.Add(TerrainChunkDictionary[viewedChunkCoord]);
                    }
                }
            }
        }
    }

	[Tool]
    public class TerrainChunk
    {
        MeshInstance3D meshObject;
        Vector2 chunkPosition;
        Aabb Bounds;

		public StaticBody3D staticBody;
		CollisionShape3D meshCollider;
		int chunkNumber;

		LODInfo[] detailLevels;
		LODMesh[] lodMeshes;
		int colliderLODIndex;

		MapData mapData;
		bool mapDataReceived;
		int previousLODIndex = -1;
		bool hasSetCollider;

        public TerrainChunk(Vector2 coord, int size, LODInfo[] detailLevels, int colliderLODIndex, Node parent, ShaderMaterial shaderMaterial, int chunkNum){
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
                Visible = false,
            };
			staticBody = new();
			meshObject.AddChild(staticBody);
			meshCollider = new();
			staticBody.AddChild(meshCollider);
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
			if (mapDataReceived) {
				float viewerDstFromNearestEdge = Bounds.Position.DistanceTo(new Vector3(viewerPosition.X, 0, viewerPosition.Y));
				bool visible = viewerDstFromNearestEdge <= maxViewDst;

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

				SetVisible(visible);
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
				
				if(chunkNumber == 1){
					GD.Print(sqrDistanceFromViewerToEdge, " ------- ", colliderGenerationDistanceThreshold * colliderGenerationDistanceThreshold);
				}

				if (sqrDistanceFromViewerToEdge < colliderGenerationDistanceThreshold * colliderGenerationDistanceThreshold){
					if (lodMeshes[colliderLODIndex].hasMesh){
						meshCollider.Shape = lodMeshes[colliderLODIndex].mesh.CreateTrimeshShape();
						hasSetCollider = true;
					}
				}
			}
		}

		public Vector3[] GetCollisionLODMeshVertices(){
			if (!lodMeshes[colliderLODIndex].hasRequestedMesh){
				lodMeshes[colliderLODIndex].RequestMesh(mapData, chunkPosition, scale, staticBody);
			}

			if (lodMeshes[colliderLODIndex].hasMesh){
				return lodMeshes[colliderLODIndex].meshData.vertices;
			}

			return null;
		}

        public void SetVisible(bool visible){
			staticBody.SetCollisionLayerValue(1, visible);
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