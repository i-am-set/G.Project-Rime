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
        perlinNoise.NoiseType = FastNoiseLite.NoiseTypeEnum.Perlin;
        perlinNoise.Frequency = scale;
        perlinNoise.FractalOctaves = octaves;
        perlinNoise.FractalGain = persistance;
        perlinNoise.FractalLacunarity = lacunarity;

        perlinNoise.Seed = seed;
        
        return perlinNoise;
    }
}