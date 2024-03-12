using Godot;
using System;
using System.Collections.Generic;

[Tool]
public partial class InfiniteTerrain : Node3D
{
	const float scale = 3.0f;

	const float viewerMoveThresholdForChunkUpdate = 25f;
	const float sqrViewerMoveThresholdForChunkUpdate = viewerMoveThresholdForChunkUpdate * viewerMoveThresholdForChunkUpdate;

	[Export] public LODInfo[] detailLevels;
    public static float maxViewDst;

    [Export] public Node3D viewer;
	[Export] public ShaderMaterial shaderMaterial;

    public static Vector2 viewerPosition;
	Vector2 viewerPositionOld;
	static MapGenerator mapGenerator;
    int chunkSize;
    int chunksVisibleInViewDst;

    Dictionary<Vector2, TerrainChunk> TerrainChunkDictionary = new();
    List<TerrainChunk> TerrainChunksVisibleLastUpdate = new();

    public override void _Ready()
    {
		mapGenerator = (MapGenerator)GetParent();

		maxViewDst = detailLevels[detailLevels.Length-1].visibleDstThreshold;
        chunkSize = MapGenerator.mapChunkSize - 1;
        chunksVisibleInViewDst = Mathf.RoundToInt(maxViewDst / chunkSize);

		UpdateVisibleChunks();
    }

    public override void _Process(double delta)
    {
        viewerPosition = new Vector2(viewer.Position.X, viewer.Position.Z) / scale;

		if ((viewerPositionOld - viewerPosition).LengthSquared() > sqrViewerMoveThresholdForChunkUpdate){
			viewerPositionOld = viewerPosition;
        	UpdateVisibleChunks();
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
                Vector2 viewedChunkCoord = new Vector2(currentChunkCoordX + xOffset, currentChunkCoordY + yOffset);
				
                if (TerrainChunkDictionary.ContainsKey(viewedChunkCoord)){
                    TerrainChunkDictionary[viewedChunkCoord].UpdateTerrainChunk();
                    if (TerrainChunkDictionary[viewedChunkCoord].IsVisible()){
                        TerrainChunksVisibleLastUpdate.Add(TerrainChunkDictionary[viewedChunkCoord]);
                    }
                }else{
                    TerrainChunkDictionary.Add(viewedChunkCoord, new TerrainChunk(viewedChunkCoord, chunkSize, detailLevels, this, shaderMaterial));
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

		StaticBody3D staticBody;
		CollisionShape3D meshCollider;

		LODInfo[] detailLevels;
		LODMesh[] lodMeshes;
		LODMesh collisionLODMesh;

		MapData mapData;
		bool mapDataReceived;
		int previousLODIndex = -1;

        public TerrainChunk(Vector2 coord, int size, LODInfo[] detailLevels, Node parent, ShaderMaterial shaderMaterial){
			this.detailLevels = detailLevels;

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
				lodMeshes[i] = new LODMesh(detailLevels[i].lod, UpdateTerrainChunk);
				if (detailLevels[i].useForCollider) {
					collisionLODMesh = lodMeshes[i];
				}
			}

			mapGenerator.RequestMapData(chunkPosition, OnMapDataReceived);
        }

		private void OnMapDataReceived(MapData mapData){
			this.mapData = mapData;
			// resourceChunkInstancer.QueueResourcePosition(mapData.perlinNoise, chunkSize);
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
							lodMesh.RequestMesh(mapData, chunkPosition);
						}
					}

					if (lodIndex == 0) {
						if (collisionLODMesh.hasMesh) {
							meshCollider.Shape = collisionLODMesh.mesh.CreateTrimeshShape();
						} else if (!collisionLODMesh.hasRequestedMesh) {
							collisionLODMesh.RequestMesh(mapData, chunkPosition);
						}
					}
				}

				SetVisible(visible);
			}
        }

        public void SetVisible(bool visible){
            meshObject.Visible = visible;
        }

        public bool IsVisible(){
            return meshObject.Visible;
        }
    }

	[Tool]
	partial class LODMesh : Resource {

		public Mesh mesh;
		public MeshData meshData;
		public bool hasRequestedMesh;
		public bool hasMesh;
		int lod;
		System.Action updateCallback;

		public LODMesh(int lod, System.Action updateCallback) {
			this.lod = lod;
			this.updateCallback = updateCallback;
		}

		private void OnMeshDataReceived(MeshData tempMeshData) {
			meshData = tempMeshData;
			mesh = tempMeshData.CreateMesh();
			hasMesh = true;

			updateCallback();
		}

		public void RequestMesh(MapData mapData, Vector2 chunkPosition){
			hasRequestedMesh = true;
			mapGenerator.RequestMeshData(mapData, lod, chunkPosition, OnMeshDataReceived);
		}
	}
}