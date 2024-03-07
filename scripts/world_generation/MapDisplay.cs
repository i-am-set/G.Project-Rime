using Godot;
using System;

[Tool]
public partial class MapDisplay : MeshInstance3D
{
    public void DrawNoiseMap(int mapWidth, int mapHeight, FastNoiseLite perlinNoise)
    {
        Image img = perlinNoise.GetImage(mapWidth, mapHeight, false, false, false);        

        StandardMaterial3D standardMaterial3D = new();
        ImageTexture texture = ImageTexture.CreateFromImage(img);
        standardMaterial3D.AlbedoTexture = texture;
        PlaneMesh planeMesh = new();
        planeMesh.Size = new Vector2(mapWidth, mapHeight);
        this.Mesh = planeMesh;
        this.MaterialOverride = standardMaterial3D;
    }
}