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
    public bool autoUpdate;

    public void GenerateMap()
    {
        float[,] noiseMap = MapNoise.GenerateNoiseMap(mapWidth, mapHeight, noiseScale, octaves, persistance, lacunarity);

        MapDisplay display = (MapDisplay)GetNode("MapDisplay");
        display.DrawNoiseMap(noiseMap);
    }
}