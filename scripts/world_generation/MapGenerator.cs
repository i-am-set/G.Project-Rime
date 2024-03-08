using Godot;
using System;
using System.Runtime.InteropServices;

[Tool]
public partial class MapGenerator : Node3D
{
    public enum DrawMode {NoiseMap, ColorMap, Mesh}
    [Export] public DrawMode drawMode;

    public const int mapChunkSize = 241;
    private int _levelOfDetail;
    [Export(PropertyHint.Range, "0, 6")] public int levelOfDetail { get { return _levelOfDetail; } set { _levelOfDetail = value; FlagNeedsUpdate(); } }
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

    private float _meshHeightMultiplier;
    [Export(PropertyHint.Range, "1, 50")] public float meshHeightMultiplier { get { return _meshHeightMultiplier; } set { _meshHeightMultiplier = value; FlagNeedsUpdate(); } }

    [Export] public bool autoUpdate;
    public bool needsUpdating = false;

    [Export] public TerrainType[] regions;

    public void DrawMapInEditor()
    {
        MapData mapData = GenerateMapData();

        MapDisplay display = (MapDisplay)GetNode("MapDisplay");
        if (drawMode == DrawMode.NoiseMap){
            display.DrawTexture(TextureGenerator.TextureFromHeightMap(mapData.perlinNoise, mapChunkSize, mapChunkSize));
        } else if (drawMode == DrawMode.ColorMap){
            display.DrawTexture(TextureGenerator.TextureFromColorMap(mapData.colorMap, mapChunkSize, mapChunkSize));
        } else if (drawMode == DrawMode.Mesh){
            display.DrawMesh(MeshGenerator.GenerateTerrainMesh(mapData.perlinNoise, mapChunkSize, mapChunkSize, meshHeightMultiplier, levelOfDetail), TextureGenerator.TextureFromColorMap(mapData.colorMap, mapChunkSize, mapChunkSize));
        }
    }

    private MapData GenerateMapData()
    {
        FastNoiseLite perlinNoise = MapNoise.GenerateNoiseMap(noiseScale, octaves, persistance, lacunarity, seed);

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
        Random rnd = new Random();
        seed = rnd.Next(0, 999999999);
    }

    private void FlagNeedsUpdate()
    {
        needsUpdating = true;
    }
}

[Tool]
public partial class MapData : Resource
{
    [Export] public FastNoiseLite perlinNoise { get; set; }

    [Export] public Color[] colorMap { get; set; }

    public MapData(FastNoiseLite perlinNoise, Color[] colorMap)
    {
        this.perlinNoise = perlinNoise;
        this.colorMap = colorMap;
    }
}