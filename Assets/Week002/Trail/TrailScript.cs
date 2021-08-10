using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[System.Serializable]
public struct TrailPosRot
{
    public Vector3 pos;
    public Quaternion rot;

    public TrailPosRot(Vector3 pos, Quaternion rot)
    {
        this.pos = pos;
        this.rot = rot;
    }

    public override string ToString() => $"({pos}, {rot})";
}

public class TrailScript : MonoBehaviour
{
    public Transform trailGizmos;
    public List<TrailPosRot> posList = new List<TrailPosRot>();
    int posListCount;

    Mesh mesh;
    public Material material;
    MeshFilter meshFilter;

    List<Vector3> vertices = new List<Vector3>();
    List<int> triangles = new List<int>();
    List<Vector2> uvs = new List<Vector2>();

    public int stepMax = 20;
    public float timeMax = 1.0f;
    float myTime = 0.0f;
    
    public float trailWidth = 1.5f;
    public float spacing = 0.5f;

    void Start()
    {
        MeshRenderer meshRenderer = gameObject.AddComponent<MeshRenderer>();
        if (material) meshRenderer.material = material;
        meshFilter = gameObject.AddComponent<MeshFilter>();

        mesh = new Mesh();
        mesh.name = "myMesh";

        myTime = timeMax;
    }

    void Update()
    {
        if (posList.Count == 0) posList.Add(new TrailPosRot(trailGizmos.position, trailGizmos.rotation));
        posListCount = posList.Count;

        var pos = trailGizmos.position;
        var head = posList[posList.Count - 1].pos - pos;
        var distance  = head.magnitude;
        
        if (distance > spacing)
        {
            posList.Add(new TrailPosRot(trailGizmos.position, trailGizmos.rotation));
        }

        if (posList.Count > stepMax)
        {
            posList.RemoveAt(0);
        }

        /* CountDown Delect */
        if (myTime <= 0.0f)
        {
            myTime = timeMax;
            if (posList.Count > 0) posList.RemoveAt(0);
        }
        else
        {
            myTime -= Time.deltaTime;
        }

        if (posListCount != posList.Count)
        {
            CreateMesh();
            UpdateMesh();
        }
    }

    void CreateMesh()
    {
        vertices.Clear();
        triangles.Clear();
        uvs.Clear();
        mesh.Clear();

        for (int i = 0; i < posList.Count - 1; i++)
        {
            /*
            ^Forward^
            3-----2
                    /
                /
                /
            1-----0
            */
            float uvHeightBottom  = (float) i / posList.Count;
            float uvHeightTop     = (float) (i+1) / posList.Count;

            Vector3[] v = new Vector3[4];
            v[0] = posList[i].pos + posList[i].rot * Vector3.right * trailWidth * uvHeightBottom;
            v[1] = posList[i].pos - posList[i].rot * Vector3.right * trailWidth * uvHeightBottom;

            v[2] = posList[i+1].pos + posList[i+1].rot * Vector3.right * trailWidth * uvHeightTop;
            v[3] = posList[i+1].pos - posList[i+1].rot * Vector3.right * trailWidth * uvHeightTop;

            vertices.Add( v[0] );
            vertices.Add( v[1] );
            vertices.Add( v[2] );
            vertices.Add( v[3] );

            triangles.Add( i * 4 + 0 );
            triangles.Add( i * 4 + 1 );
            triangles.Add( i * 4 + 2 );

            triangles.Add( i * 4 + 3 );
            triangles.Add( i * 4 + 2 );
            triangles.Add( i * 4 + 1 );

            uvs.Add(new Vector2(1, uvHeightBottom)); //1,0
            uvs.Add(new Vector2(0, uvHeightBottom)); //0,0
            uvs.Add(new Vector2(1, uvHeightTop));    //1,1
            uvs.Add(new Vector2(0, uvHeightTop));    //0,1
            
        }

        if (vertices.Count > 4)
        {
            vertices[vertices.Count-1] = trailGizmos.position - trailGizmos.right * trailWidth;
            vertices[vertices.Count-2] = trailGizmos.position + trailGizmos.right * trailWidth;
        }
    }

    void UpdateMesh()
    {
        if(posList.Count > 1)
        {
            mesh.vertices   = vertices.ToArray();
            mesh.triangles  = triangles.ToArray();
            mesh.uv         = uvs.ToArray();
            meshFilter.mesh = mesh;
        }
        else
        {
            meshFilter.mesh = null;
        }
    }

    private void OnGUI()
    {
        GUI.Label(new Rect(10, 10, 100, 200), $"{posList.Count}" );
    }

    private void OnDrawGizmos()
    {
        #if UNITY_EDITOR

        Gizmos.color = Color.black;
        Gizmos.DrawLine(trailGizmos.position, trailGizmos.position + trailGizmos.right * trailWidth);
        Gizmos.DrawLine(trailGizmos.position, trailGizmos.position - trailGizmos.right * trailWidth);
        
        UnityEditor.Handles.Label(trailGizmos.position + Vector3.up, $"myTime:{myTime}");

        foreach (var item in posList)
        {
            Gizmos.color = Color.white;
            Gizmos.DrawSphere(item.pos, 0.1f);
            Gizmos.color = Color.blue;
            Gizmos.DrawLine(item.pos, item.pos + item.rot * Vector3.forward * 1);
            Gizmos.color = Color.green;
            Gizmos.DrawLine(item.pos, item.pos + item.rot * Vector3.up * 1);
            Gizmos.color = Color.red;
            Gizmos.DrawLine(item.pos, item.pos + item.rot * Vector3.right * 1);
        }

        #endif
    }
}
