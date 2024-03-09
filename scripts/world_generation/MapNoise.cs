using Godot;
using System;

[Tool]
public partial class MapNoise
{
    public enum NormalizeMode {Local, Global};

    public static FastNoiseLite GenerateNoiseMap(float scale, int octaves, float persistance, float lacunarity, int seed, Vector2 offset)
    {
        Vector3 noiseOffset = new(offset.X, -offset.Y, 0);

        if (scale <= 0)
        {
            scale = 0.0001f;
        }

        FastNoiseLite perlinNoise = new FastNoiseLite();
        perlinNoise.Offset = noiseOffset;
        perlinNoise.NoiseType = FastNoiseLite.NoiseTypeEnum.Perlin;
        perlinNoise.Frequency = scale;
        perlinNoise.FractalOctaves = octaves;
        perlinNoise.FractalGain = persistance;
        perlinNoise.FractalLacunarity = lacunarity;

        perlinNoise.Seed = seed;
        
        return perlinNoise;
    }
}