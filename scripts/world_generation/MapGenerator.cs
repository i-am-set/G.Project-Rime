using Godot;
using System;
using System.Runtime.CompilerServices;
using System.Threading;
using System.Threading.Tasks;
using System.Collections.Generic;

[Tool]
public partial class MapGenerator : Node3D
{
    public enum DrawMode {NoiseMap, ColorMap, Mesh}
    [Export] public DrawMode drawMode;

	[Export(PropertyHint.Range, "0, 8")]public int chunkSizeIndex;
    public int mapChunkSize{get { return MeshGenerator.supportedChunkSizes[chunkSizeIndex]+1; } }
    private int _editorPreviewLOD;
    [Export(PropertyHint.Range, "0, 4")] public int editorPreviewLOD { get { return _editorPreviewLOD; } set { _editorPreviewLOD = value; FlagNeedsUpdate(); } }
    private float _noiseScale;
    [Export] public float noiseScale { get { return _noiseScale; } set { _noiseScale = value; FlagNeedsUpdate(); } }

    private int _octaves;
    [Export(PropertyHint.Range, "0, 10")] public int octaves { get { return _octaves; } set { _octaves = value; FlagNeedsUpdate(); } }
    private float _persistance;
    [Export(PropertyHint.Range, "0, 1")] public float persistance { get { return _persistance; } set { _persistance = value; FlagNeedsUpdate(); } }
    private float _lacunarity;
    [Export(PropertyHint.Range, "1, 10")] public float lacunarity { get { return _lacunarity; } set { _lacunarity = value; FlagNeedsUpdate(); } }

    private int _seed;
    [Export] public int seed { get { return _seed; } set { _seed = value; FlagNeedsUpdate(); } }
    private Vector2 _offset;
    [Export] public Vector2 offset { get { return _offset; } set { _offset = value; FlagNeedsUpdate(); } }

    private float _meshHeightMultiplier;
    [Export(PropertyHint.Range, "1, 50")] public float meshHeightMultiplier { get { return _meshHeightMultiplier; } set { _meshHeightMultiplier = value; FlagNeedsUpdate(); } } 
    private Curve _meshHeightCurve;
    [Export] public Curve meshHeightCurve { get { return _meshHeightCurve; } set { _meshHeightCurve = value; FlagNeedsUpdate(); } } 

    [Export] public bool autoUpdate;
    public bool needsUpdating = false;

    [Export] public TerrainType[] regions;

	ResourceChunkInstancer resourceChunkInstancer;

    Queue<MapThreadInfo<MapData>> mapDataThreadInfoQueue = new Queue<MapThreadInfo<MapData>>();
	Queue<MapThreadInfo<MeshData>> meshDataThreadInfoQueue = new Queue<MapThreadInfo<MeshData>>();

    public override void _Ready(){
        resourceChunkInstancer = (ResourceChunkInstancer)GetNode("ResourceChunkInstancer");
    }

    public void DrawMapInEditor()
    {
        MapData mapData = GenerateMapData(Vector2.Zero);

        MapDisplay display = (MapDisplay)GetNode("MapDisplay");
        if (drawMode == DrawMode.NoiseMap){
            display.DrawTexture(TextureGenerator.TextureFromHeightMap(mapData.perlinNoise, mapChunkSize, mapChunkSize));
        } else if (drawMode == DrawMode.ColorMap){
            display.DrawTexture(TextureGenerator.TextureFromColorMap(mapData.colorMap, mapChunkSize, mapChunkSize));
        } else if (drawMode == DrawMode.Mesh){
            display.DrawMesh(MeshGenerator.GenerateTerrainMesh(mapData.perlinNoise, mapChunkSize, mapChunkSize, meshHeightMultiplier, meshHeightCurve, editorPreviewLOD, new Vector2(0, 0), 1.0f, new StaticBody3D(), resourceChunkInstancer), TextureGenerator.TextureFromColorMap(mapData.colorMap, mapChunkSize, mapChunkSize));
        }
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

    public void RandomizeSeed()
    {
        Random rnd = new();
        seed = rnd.Next(0, 999999999);
    }

    private void FlagNeedsUpdate()
    {
        needsUpdating = true;
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
