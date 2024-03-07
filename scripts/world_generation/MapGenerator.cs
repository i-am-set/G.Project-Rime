using Godot;
using System;

[Tool]
public partial class MapGenerator : Node3D
{
    [Export]
    public int mapWidth;
    [Export]
    public int mapHeight;
    [Export]
    public float noiseScale;

    [Export]
    public int octaves;
    [Export]
    public float persistance;
    [Export]
    public float lacunarity;

    [Export]
    public int seed;

    [Export]
    public bool autoUpdate;

    public void GenerateMap()
    {
        FastNoiseLite perlinNoise = MapNoise.GenerateNoiseMap(noiseScale, octaves, persistance, lacunarity, seed);

        for (int i = 0; i < mapWidth; i++)
        {
            float noiseValue = perlinNoise.GetNoise2D(i, 1);

            
        }

        MapDisplay display = (MapDisplay)GetNode("MapDisplay");
        display.DrawNoiseMap(mapWidth, mapHeight, perlinNoise);
    }

    public void RandomizeSeed()
    {
        Random rnd = new Random();
        seed = rnd.Next(0, 999999999);
    }
}