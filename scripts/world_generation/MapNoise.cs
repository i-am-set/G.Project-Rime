using Godot;
using System;

[Tool]
public partial class MapNoise
{
    public static FastNoiseLite GenerateNoiseMap(float scale, int octaves, float persistance, float lacunarity, int seed, Vector2 offset)
    {
        Vector3 noiseOffset = new(offset.X, -offset.Y, 0);

        if (scale <= 0)
        {
            scale = 0.0001f;
        }

        FastNoiseLite perlinNoise = new()
        {
            Offset = noiseOffset,
            NoiseType = FastNoiseLite.NoiseTypeEnum.Perlin,
            Frequency = scale,
            FractalOctaves = octaves,
            FractalGain = persistance,
            FractalLacunarity = lacunarity,

            Seed = seed
        };

        return perlinNoise;
    }
}