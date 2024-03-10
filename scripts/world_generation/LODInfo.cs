using Godot;
using System;

[Tool]
[GlobalClass]
public partial class LODInfo : Resource
{
    [Export] public int lod { get; set; }

    [Export] public float visibleDstThreshold { get; set; }

    [Export] public bool useForCollider { get; set; }
}
