using Godot;
using System;

[Tool]
public partial class MapNoise
{
    public static FastNoiseLite GenerateNoiseMap(float scale, int octaves, float persistance, float lacunarity, int seed)
    {
        if (scale <= 0)
        {
            scale = 0.0001f;
        }

        FastNoiseLite perlinNoise = new FastNoiseLite();
        perlinNoise.Frequency = scale;
        perlinNoise.FractalOctaves = octaves;
        perlinNoise.FractalGain = persistance;
        perlinNoise.FractalLacunarity = lacunarity;

        perlinNoise.Seed = seed;


        // float maxNoiseHeight = float.MinValue;
        // float minNoiseHeight = float.MaxValue;

        // for (int y = 0; y < mapHeight; y++){
        //     for (int x = 0; x < mapWidth; x++){
                
        //         float amplitude = 1;
        //         float frequency = 1;
        //         float noiseHeight = 0;

        //         for (int i = 0; i < octaves; i++) {
        //             float sampleX = x / scale * frequency;
        //             float sampleY = y / scale * frequency;

        //             float perlinValue = new FastNoiseLite().GetNoise2D(sampleX, sampleY);
        //             noiseHeight += perlinValue * amplitude;

        //             amplitude *= persistance;
        //             frequency *= lacunarity;
        //         }
        //         if (noiseHeight > maxNoiseHeight){
        //             maxNoiseHeight = noiseHeight;
        //         } else if (noiseHeight < maxNoiseHeight){
        //             minNoiseHeight = noiseHeight;
        //         }
        //         noiseMap[x, y] = noiseHeight;
        //     }
        // }

        // for (int y = 0; y < mapHeight; y++){
        //     for (int x = 0; x < mapWidth; x++){
        //         noiseMap[x, y] = Mathf.Lerp(minNoiseHeight, maxNoiseHeight, noiseMap[x, y]);
        //     }
        // }
        
        return perlinNoise;
    }
}