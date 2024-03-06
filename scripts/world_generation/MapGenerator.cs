using Godot;
using System;

[Tool]
public partial class MapGenerator : Node3D
{
    public int mapWidth;
    public int mapHeight;
    public float noiseScale;

    public bool autoUpdate;

    public void GenerateMap()
    {
        float[,] noiseMap = MapNoise.GenerateNoiseMap(mapWidth, mapHeight, noiseScale);

        MapDisplay display = (MapDisplay)GetNode("MapDisplay");
        display.DrawNoiseMap(noiseMap);
    }
}