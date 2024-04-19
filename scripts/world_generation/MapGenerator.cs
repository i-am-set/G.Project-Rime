using Godot;
using System;
using System.Runtime.CompilerServices;
using System.Threading;
using System.Threading.Tasks;
using System.Collections.Generic;

public partial class MapGenerator : Node3D
{
    public enum DrawMode {NoiseMap, ColorMap, Mesh}
    [Export] public DrawMode drawMode;

	[Export(PropertyHint.Range, "0, 8")]public int chunkSizeIndex;
    public int mapChunkSize{get { return MeshGenerator.supportedChunkSizes[chunkSizeIndex]+1; } }
    [Export(PropertyHint.Range, "0, 4")] public int editorPreviewLOD;
    [Export] public float noiseScale = 0.005f;

    [Export(PropertyHint.Range, "0, 10")] public int octaves = 8;
    [Export(PropertyHint.Range, "0, 1")] public float persistance = 0.5f;
    [Export(PropertyHint.Range, "1, 10")] public float lacunarity = 2.0f;

    public int seed = 0;
    [Export] public Vector2 offset;

    [Export(PropertyHint.Range, "1, 50")] public float meshHeightMultiplier = 30.0f;
    [Export] public Curve meshHeightCurve;

    [Export] public TerrainType[] regions;

	ResourceChunkInstancer resourceChunkInstancer;

    Queue<MapThreadInfo<MapData>> mapDataThreadInfoQueue = new Queue<MapThreadInfo<MapData>>();
	Queue<MapThreadInfo<MeshData>> meshDataThreadInfoQueue = new Queue<MapThreadInfo<MeshData>>();
    Queue<RollResourceThreadInfo<List<Vector3>>> rollResourceThreadInfoQueue = new Queue<RollResourceThreadInfo<List<Vector3>>>();

    public override void _Ready(){
        seed = (int)GetNode<Node>("/root/Global").Get("WORLD_SEED");
        resourceChunkInstancer = (ResourceChunkInstancer)GetNode("ResourceChunkInstancer");
    }

    // #---------------------MAP THREADING----------------------------#
    public void RequestMapData(Vector2 center, Action<MapData> callback)
    {
        ThreadStart threadStart = delegate {
            MapDataThread(center, callback);
        };

        new Thread(threadStart).Start();
    }

    private void MapDataThread(Vector2 center, Action<MapData> callback)
    {
        MapData mapData = GenerateMapData(center);
        lock(mapDataThreadInfoQueue){
            mapDataThreadInfoQueue.Enqueue(new MapThreadInfo<MapData>(callback, mapData));
        }
    }

    // #---------------------MESH THREADING----------------------------#
    public void RequestMeshData(MapData mapData, int lod, Vector2 chunkPosition, float scale, StaticBody3D staticBody, Action<MeshData> callback)
    {
        ThreadStart threadStart = delegate {
            MeshDataThread(mapData, lod, chunkPosition, scale, staticBody, callback);
        };

        new Thread(threadStart).Start();
    }

    private void MeshDataThread(MapData mapData, int lod, Vector2 chunkPosition, float scale, StaticBody3D staticBody, Action<MeshData> callback)
    {
        MeshData meshData = MeshGenerator.GenerateTerrainMesh(mapData.perlinNoise, mapChunkSize, mapChunkSize, meshHeightMultiplier, meshHeightCurve, lod, chunkPosition, scale, staticBody, resourceChunkInstancer);
        lock(meshDataThreadInfoQueue){
            meshDataThreadInfoQueue.Enqueue(new MapThreadInfo<MeshData>(callback, meshData));
        }
    }

    // #----------------------RESOURCE THREADING-------------------------#
    public void RequestRollResource(InfiniteTerrainGenerator.TerrainChunk terrainChunk, Action<List<Vector3>> callback)
    {
        ThreadStart threadStart = delegate {
            RollResourceThread(terrainChunk, callback);
        };

        new Thread(threadStart).Start();
    }

    private void RollResourceThread(InfiniteTerrainGenerator.TerrainChunk terrainChunk, Action<List<Vector3>> callback)
    {
        List<Vector3> rolledChunkResourcePositions = terrainChunk.RollResources();
        lock(rollResourceThreadInfoQueue){
            rollResourceThreadInfoQueue.Enqueue(new RollResourceThreadInfo<List<Vector3>>(callback, rolledChunkResourcePositions));
        }
    }
    
    public override void _Process(double delta)
    {
        if (mapDataThreadInfoQueue.Count > 0)
        {
            for (int i = 0; i < mapDataThreadInfoQueue.Count; i++)
            {
                MapThreadInfo<MapData> threadInfo = mapDataThreadInfoQueue.Dequeue();
                threadInfo.callback(threadInfo.parameter);
            }
        }

        if (meshDataThreadInfoQueue.Count > 0)
        {
            for (int i = 0; i < meshDataThreadInfoQueue.Count; i++)
            {
                MapThreadInfo<MeshData> threadInfo = meshDataThreadInfoQueue.Dequeue();
                threadInfo.callback(threadInfo.parameter);
            }
        }

        if (rollResourceThreadInfoQueue.Count > 0)
        {
            for (int i = 0; i < rollResourceThreadInfoQueue.Count; i++)
            {
                RollResourceThreadInfo<List<Vector3>> threadInfo = rollResourceThreadInfoQueue.Dequeue();
                threadInfo.callback(threadInfo.parameter);
            }
        }
    }

    MapData GenerateMapData(Vector2 center)
    {
        FastNoiseLite perlinNoise = MapNoise.GenerateNoiseMap(noiseScale, octaves, persistance, lacunarity, seed, center + offset);

        Color[] colorMap = new Color[mapChunkSize * mapChunkSize];
        for (int x = 0; x < mapChunkSize; x++){
            for (int y = 0; y < mapChunkSize; y++){
                float currentHeight = perlinNoise.GetNoise2D(x, y);
                for (int i = 0; i < regions.Length; i++){
                    if (currentHeight <= regions[i].height){
                        colorMap[y * mapChunkSize + x] = regions[i].color;
                        break;
                    }
                }
            }
        }

        return new MapData(perlinNoise, colorMap);
    }

    struct MapThreadInfo<T> {
        public readonly Action<T> callback;
        public readonly T parameter;

        public MapThreadInfo(Action<T> callback, T parameter)
        {
            this.callback = callback;
            this.parameter = parameter;
        }
    }

    struct RollResourceThreadInfo<T> {
			public readonly Action<T> callback;
			public readonly T parameter;

			public RollResourceThreadInfo(Action<T> callback, T parameter)
			{
				this.callback = callback;
				this.parameter = parameter;
			}
		}
}

[Tool]
public partial class MapData : Resource
{
    public FastNoiseLite perlinNoise { get; set; }

    public Color[] colorMap { get; set; }

    public MapData(FastNoiseLite perlinNoise, Color[] colorMap)
    {
        this.perlinNoise = perlinNoise;
        this.colorMap = colorMap;
    }
}
