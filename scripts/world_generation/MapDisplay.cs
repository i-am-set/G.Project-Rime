using Godot;
using System;

[Tool]
public partial class MapDisplay : MeshInstance3D
{
    public void DrawNoiseMap(float[,] noiseMap)
    {
        int width = noiseMap.GetLength(0);
        int height = noiseMap.GetLength(1);

        Image img = new();

        for (int y = 0; y < height; y++)
        {
            for (int x = 0; x < width; x++)
            {
                float noiseValue = noiseMap[x, y];
                byte colorValue = (byte)(noiseValue * 255);
                img.SetPixel(x, y, new Color(colorValue, colorValue, colorValue));
            }
        }

        StandardMaterial3D standardMaterial3D = new();
        ImageTexture texture = ImageTexture.CreateFromImage(img);
        standardMaterial3D.AlbedoTexture = texture;
        PlaneMesh planeMesh = new();
        planeMesh.Size = new Vector2(width, height);
        this.Mesh = planeMesh;
        this.MaterialOverride = standardMaterial3D;
    }
}