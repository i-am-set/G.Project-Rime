using Godot;
using System;

[Tool]
public partial class MapDisplay : MeshInstance3D
{
    [Export] ShaderMaterial shaderMaterial;

    public void DrawTexture(ImageTexture texture)
    {
        shaderMaterial.SetShaderParameter("texture_albedo", texture);
        PlaneMesh planeMesh = new();
        Texture2D tempTex = texture;
        planeMesh.Size = new Vector2(tempTex.GetWidth(), tempTex.GetHeight());
        this.Mesh = planeMesh;
        this.MaterialOverride = shaderMaterial;
    }

    public void DrawMesh(MeshData meshData, ImageTexture texture)
    {
        // shaderMaterial.SetShaderParameter("texture_albedo", texture);
		this.Mesh = meshData.CreateMesh();
        this.MaterialOverride = shaderMaterial;
    }
}