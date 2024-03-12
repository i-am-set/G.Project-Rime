using Godot;

[Tool]
public static class MeshGenerator
{
	public static MeshData GenerateTerrainMesh(FastNoiseLite perlinNoise, int width, int height, float heightMultiplier, Curve _heightCurve, int levelOfDetail, Vector2 chunkPosition, ResourceChunkInstancer resourceChunkInstancer) {
		Curve heightCurve = (Curve)_heightCurve.Duplicate();

		float topLeftX = (width - 1) / -2f;
		float topLeftZ = (height - 1) / 2f;

		int meshSimplificationIncrement = (levelOfDetail == 0) ? 1 : levelOfDetail * 2;
		int verticesPerLine = (width-1) / meshSimplificationIncrement + 1;

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

		// for (int y = 0; y < height; y += 2) {
		// 	for (int x = 0; x < width; x += 2) {
		// 		float normalizedNoise = (perlinNoise.GetNoise2D(x, y) + 1.0f) / 2.0f;
		// 		_vertexHeight =  heightCurve.Sample(normalizedNoise) * heightMultiplier;
		// 		resourceChunkInstancer.GenerateLocalResources(new Vector3 ((topLeftX + x) + chunkPosition.X, _vertexHeight, (topLeftZ - y)+chunkPosition.Y)*3);
		// 	}
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