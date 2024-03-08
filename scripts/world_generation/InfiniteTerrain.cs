using Godot;
using System;
using System.Collections.Generic;

[Tool]
public partial class InfiniteTerrain : Node3D
{
    public const float MaxViewDst = 450;
    [Export] public Node3D Viewer;

    public static Vector2 ViewerPosition;
    int ChunkSize;
    int ChunksVisibleInViewDst;

    Dictionary<Vector2, TerrainChunk> TerrainChunkDictionary = new();
    List<TerrainChunk> TerrainChunksVisibleLastUpdate = new();

    public override void _Ready()
    {
        ChunkSize = MapGenerator.mapChunkSize - 1;
        ChunksVisibleInViewDst = Mathf.RoundToInt(MaxViewDst / ChunkSize);
    }

    public override void _Process(double delta)
    {
        ViewerPosition = new Vector2(Viewer.Position.X, Viewer.Position.Z);
        UpdateVisibleChunks();
    }

    void UpdateVisibleChunks()
    {
        foreach (var terrainChunk in TerrainChunksVisibleLastUpdate)
        {
            terrainChunk.SetVisible(false);
        }
        TerrainChunksVisibleLastUpdate.Clear();
		
        int currentChunkCoordX = Mathf.RoundToInt(ViewerPosition.X / ChunkSize);
        int currentChunkCoordY = Mathf.RoundToInt(ViewerPosition.Y / ChunkSize);

        for (int yOffset = -ChunksVisibleInViewDst; yOffset <= ChunksVisibleInViewDst; yOffset++){
            for (int xOffset = -ChunksVisibleInViewDst; xOffset <= ChunksVisibleInViewDst; xOffset++){
                Vector2 viewedChunkCoord = new Vector2(currentChunkCoordX + xOffset, currentChunkCoordY + yOffset);
				
                if (TerrainChunkDictionary.ContainsKey(viewedChunkCoord)){
                    TerrainChunkDictionary[viewedChunkCoord].UpdateTerrainChunk();
                    if (TerrainChunkDictionary[viewedChunkCoord].IsVisible()){
                        TerrainChunksVisibleLastUpdate.Add(TerrainChunkDictionary[viewedChunkCoord]);
                    }
                }else{
                    TerrainChunkDictionary.Add(viewedChunkCoord, new TerrainChunk(viewedChunkCoord, ChunkSize, this));
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

        public TerrainChunk(Vector2 coord, int size, Node parent)
        {
            chunkPosition = coord * size;
            Bounds = new Aabb(new Vector3(chunkPosition.X, 0, chunkPosition.Y), new Vector3(size, size, size));

			PlaneMesh planeMesh = new();
			planeMesh.Size = new Vector2(size, size);
            meshObject = new MeshInstance3D
            {
                Mesh = planeMesh,
                Position = new Vector3(chunkPosition.X, 0, chunkPosition.Y),
                Visible = false
            };

            parent.AddChild(meshObject);
        }

        public void UpdateTerrainChunk()
        {
            float viewerDstFromNearestEdge = Bounds.GetCenter().DistanceTo(new Vector3(ViewerPosition.X, 0, ViewerPosition.Y));

            bool visible = viewerDstFromNearestEdge <= MaxViewDst;
            SetVisible(visible);
        }

        public void SetVisible(bool visible)
        {
            meshObject.Visible = visible;
        }

        public bool IsVisible()
        {
            return meshObject.Visible;
        }
    }
}