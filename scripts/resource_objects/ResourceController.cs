using Godot;

[Tool]
public partial class ResourceController : Node3D
{
	[Export]
	public Node3D[] children;

	public PackedScene _packedScene;

	public int currentResource = 0;

	public void ShowResource(int child)
	{
		if (child >= 0 && child <= children.Length)
		{
			children[child].Visible = true;
			currentResource = child;
		}
		else
		{
			GD.PrintErr("Invalid child index : ShowResource( | ", children, " | ", child);
		}
	}

	public void HideResource(int child)
	{
		if (child >= 0 && child <= children.Length)
		{
			children[child].Visible = false;
			currentResource = 0;
		}
		else
		{
			GD.PrintErr("Invalid child index : HideResource() | ", children, " | ", child);
		}
	}

	public void HideAllResources()
	{
		for (int i = 0; i <= children.Length; i++)
		{
			if (children[i].Visible)
			{
				children[i].Visible = false;
			}
		}

		currentResource = 0;
	}
}
