using Godot;
using System;

[Tool]
[GlobalClass]
public partial class TerrainType : Resource
{
    [Export] public string name { get; set; }

    [Export] public float height { get; set; }

    [Export] public Color color { get; set; }
}