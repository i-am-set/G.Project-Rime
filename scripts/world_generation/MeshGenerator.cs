using System;
using System.Collections.Generic;
using System.Linq;
using Godot;

[Tool]
public static class MeshGenerator
{
	public const int numSupportedLODs = 5;
	public static readonly int[] supportedChunkSizes = {48,72,96,120,144,168,192,216,240};

	public static MeshData GenerateTerrainMesh(FastNoiseLite perlinNoise, int width, int height, float heightMultiplier, Curve _heightCurve, int levelOfDetail, Vector2 chunkPosition, float scale, StaticBody3D staticBody, ResourceChunkInstancer resourceChunkInstancer) {
		Curve heightCurve = (Curve)_heightCurve.Duplicate();

		float topLeftX = (width - 1) / -2f;
		float topLeftZ = (height - 1) / 2f;

		int meshSimplificationIncrement = (levelOfDetail == 0) ? 1 : levelOfDetail * 2;
		int verticesPerLine = (width-1) / meshSimplificationIncrement + 1;

    	HashSet<Vector3> chunkPositions = new();

		MeshData meshData = new MeshData (verticesPerLine, verticesPerLine);
		int vertexIndex = 0;
		float _vertexHeight;

		for (int y = 0; y < height; y += meshSimplificationIncrement) {
			for (int x = 0; x < width; x += meshSimplificationIncrement) {
				float normalizedNoise = (perlinNoise.GetNoise2D(x, y) + 1.0f) / 2.0f;
				_vertexHeight =  heightCurve.Sample(normalizedNoise) * heightMultiplier;
				meshData.vertices [vertexIndex] = new Vector3 (topLeftX + x, _vertexHeight, topLeftZ - y);
				meshData.uvs [vertexIndex] = new Vector2 (x / (float)width, y / (float)height);

				if (x < width - 1 && y < height - 1) {
					meshData.AddTriangle(vertexIndex + verticesPerLine, vertexIndex + verticesPerLine + 1, vertexIndex);
					meshData.AddTriangle(vertexIndex + 1, vertexIndex, vertexIndex + verticesPerLine + 1);
				}

				vertexIndex++;
			}
		}

		// if (levelOfDetail <= 10){
		// 	chunkPositions.Clear();
		// 	for (int y = 0; y < height; y += 2) {
		// 		for (int x = 0; x < width; x += 2) {
		// 			float normalizedNoise = (perlinNoise.GetNoise2D(x, y) + 1.0f) / 2.0f;
		// 			_vertexHeight = heightCurve.Sample(normalizedNoise) * heightMultiplier;
		// 			chunkPositions.Add(new Vector3 ((topLeftX + x), _vertexHeight, (topLeftZ - y)));
		// 		}
		// 	}
		// 	resourceChunkInstancer.queuedChunk.Enqueue(new ChunkData(chunkPositions, staticBody));
		// }

		meshData.CalculateNormals();

		return meshData;

	}
}

[Tool]
public class MeshData
{
	public Vector3[] vertices;
	public int[] triangles;
	public Vector2[] uvs;
	public Vector3[] normals;

	int triangleIndex;

	public MeshData(int meshWidth, int meshHeight) {
		vertices = new Vector3[meshWidth * meshHeight];
		uvs = new Vector2[meshWidth * meshHeight];
		triangles = new int[(meshWidth-1)*(meshHeight-1)*6];
		normals = new Vector3[meshWidth * meshHeight];
	}

	public void AddTriangle(int a, int b, int c) {
		triangles [triangleIndex] = a;
		triangles [triangleIndex + 1] = b;
		triangles [triangleIndex + 2] = c;
		triangleIndex += 3;
	}

	public void CalculateNormals() {
		for (int i = 0; i < triangles.Length; i += 3) {
			int index0 = triangles[i];
			int index1 = triangles[i + 1];
			int index2 = triangles[i + 2];

			Vector3 side1 = vertices[index1] - vertices[index0];
			Vector3 side2 = vertices[index2] - vertices[index0];
			Vector3 normal = side1.Cross(side2).Normalized();

			normals[index0] -= normal;
			normals[index1] -= normal;
			normals[index2] -= normal;
		}

		for (int i = 0; i < normals.Length; i++) {
			normals[i] = normals[i].Normalized();
		}
	}

	public ArrayMesh CreateMesh() {
		ArrayMesh arrayMesh = new();
		Godot.Collections.Array arrays = new();
		arrays.Resize((int)Mesh.ArrayType.Max);
		arrays[(int)Mesh.ArrayType.Vertex] = vertices;
		arrays[(int)Mesh.ArrayType.Index] = triangles;
		arrays[(int)Mesh.ArrayType.TexUV] = uvs;
		arrays[(int)Mesh.ArrayType.Normal] = normals;
		arrayMesh.AddSurfaceFromArrays(Mesh.PrimitiveType.Triangles, arrays);
		return arrayMesh;
	}
}

public struct ChunkData
{
    public HashSet<Vector3> Positions { get; set; }
    public StaticBody3D Body { get; set; }

    public ChunkData(HashSet<Vector3> positions, StaticBody3D body)
    {
        Positions = positions;
        Body = body;
    }
}