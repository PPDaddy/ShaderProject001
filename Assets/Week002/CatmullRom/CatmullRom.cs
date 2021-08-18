using System.Collections;
using System.Collections.Generic;
using UnityEngine;
[ExecuteInEditMode]
[System.Serializable]
public struct cat
{
    public Vector3 pos;
    public float dis;
    
    public cat(Vector3 pos, float dis)
    {
        this.pos = pos;
        this.dis = dis;
    }
}

public class CatmullRom : MonoBehaviour
{
    public List<Transform> pointList;
    
    cat[] c;

    void Start()
    {

    }

    void Update()
    {
        c = new cat[pointList.Count + 2];

        c[0].pos = pointList[0].position;//增加一個頭
        c[c.Length - 1].pos = pointList[pointList.Count - 1].position;//增加一個尾

        for (int i = 0; i < pointList.Count; i++)
        {
            c[i + 1].pos = pointList[i].position;
        }

        for (int i = 0; i < c.Length; i++)
        {
            var head = c[i].pos - c[Mathf.Max(i - 1, 0)].pos;

            var head2 = c[Mathf.Min(i+1, c.Length-1)].pos - c[i].pos;

            c[i].dis = head.magnitude + head2.magnitude;
        }

    } 

    private void OnDrawGizmos()
    {
        if (c == null) return;

        List<Vector3> finalPosList = new List<Vector3>();
        
        for (int i = 0; i < c.Length - 3; i++)
        {
            Vector3 p0 = c[i + 0].pos;
            Vector3 p1 = c[i + 1].pos;
            Vector3 p2 = c[i + 2].pos;
            Vector3 p3 = c[i + 3].pos;

            int step = (int)c[i + 2].dis;
            for (int t = 0; t < step; t++)
            {
                Vector3 pos = CatMullRom(p0, p1, p2, p3, (float)t/step);
                finalPosList.Add(pos);
            }
            UnityEditor.Handles.Label(p0, $"step:{step}");
        }

        Vector3 postPos = new Vector3();
        for (int i = 0; i < finalPosList.Count; i++)
        {
            Vector3 pos = finalPosList[i];

            Gizmos.DrawSphere(pos, 0.1f);
            
            if (i == 0) postPos = pos;

            //Vector3 dir = (pos - postPos).normalized;
            //Vector3 right = Vector3.Cross(Vector3.up, dir);
            Quaternion q = Quaternion.LookRotation( postPos, Vector3.up);

            Gizmos.color = Color.blue;
            Gizmos.DrawLine(pos, pos + q * Vector3.right);

            Gizmos.color = Color.white;
            Gizmos.DrawLine(pos, postPos);

            postPos = pos;
        }

        for (int i = 0; i < pointList.Count; i++)
        {
            Gizmos.color = Color.red;
            Gizmos.DrawWireSphere(pointList[i].position, 0.25f);
        }
    }

    public Vector3 CatMullRom(Vector3 a, Vector3 b, Vector3 c, Vector3 d, float t)
    {
        return .5f * (
            (-a + 3f * b - 3f * c + d) * (t * t * t)
            + (2f * a - 5f * b + 4f * c - d) * (t * t)
            + (-a + c) * t
            + 2f * b
        );
    }

}
