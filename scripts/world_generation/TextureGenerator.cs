using Godot;
using System;

[Tool]
public static partial class TextureGenerator
{
	public static ImageTexture TextureFromColorMap(Color[] colorMap, int width, int height){
		byte[] byteArray = new byte[colorMap.Length * 4];
		for (int i = 0; i < colorMap.Length; i++)
		{
			byteArray[i * 4] = (byte)(colorMap[i].R8);
			byteArray[i * 4 + 1] = (byte)(colorMap[i].G8);
			byteArray[i * 4 + 2] = (byte)(colorMap[i].B8);
			byteArray[i * 4 + 3] = (byte)(colorMap[i].A8);
		}

		Image img = Image.CreateFromData(width, height, false, Image.Format.Rgba8, byteArray);
		ImageTexture texture = ImageTexture.CreateFromImage(img);

		return texture;
	}

	public static ImageTexture TextureFromHeightMap(FastNoiseLite perlinNoise, int mapWidth, int mapHeight)
    {
        Image img = perlinNoise.GetImage(mapWidth, mapHeight, false, false, true);        
        ImageTexture texture = ImageTexture.CreateFromImage(img);

		return texture;
    }
}
