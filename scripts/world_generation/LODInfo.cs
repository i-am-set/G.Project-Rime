using Godot;
using System;

[Tool]
[GlobalClass]
public partial class LODInfo : Resource
{
    [Export(PropertyHint.Range, "0, 4")] public int lod { get; set; } // the max of the range is MeshGenerator.numSupportedLODs-1

    [Export] public float visibleDstThreshold { get; set; }

    public float SqrVisibleDstThreshold{ get {return visibleDstThreshold * visibleDstThreshold;} }

    [Export]
    public float ExportedSqrVisibleDstThreshold
    {
        get { return SqrVisibleDstThreshold; }
        set { /* Do nothing, this is just for Godot editor */ }
    }
}
