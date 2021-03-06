using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

[ExecuteInEditMode]
public class Week004_Phong : MonoBehaviour
{
    public Light[] lights;

    List<Vector4> _LightColor = new List<Vector4>();
    List<Vector4> _LightPos = new List<Vector4>();
    List<Vector4> _LightDir = new List<Vector4>();
    List<Vector4> _LightParam = new List<Vector4>();

    const int kMaxLightCount = 8;

    public void LateUpdate()
    {
        lights = Object.FindObjectsOfType<Light>();

        _LightPos.Clear();
        _LightDir.Clear();
        _LightColor.Clear();
        _LightParam.Clear();
        foreach (var li in lights)
        {
            Vector4 col = li.color;
            col.w = li.intensity;

            Vector4 pos = li.transform.position;
            pos.w = 1;

            Vector4 dir = li.transform.forward;
            dir.w = li.type == LightType.Directional ? 1 : 0;

            Vector4 param = Vector4.zero;
            if (li.type == LightType.Spot)
            {
                param.x = 1;
                param.y = Mathf.Cos(li.spotAngle * Mathf.Deg2Rad * 0.5f);
                param.z = Mathf.Cos(li.innerSpotAngle * Mathf.Deg2Rad * 0.5f);
            }
            param.w = li.range;

            _LightColor.Add(col);
            _LightPos.Add(pos);
            _LightDir.Add(dir);
            _LightParam.Add(param);
        }

        for (int i = _LightPos.Count; i < kMaxLightCount; i++)
        {
            _LightColor.Add(Vector4.zero);
            _LightDir.Add(Vector4.zero);
            _LightPos.Add(Vector4.zero);
            _LightParam.Add(Vector4.zero);
        }

        Shader.SetGlobalInt("uLightCount", lights.Length);
        Shader.SetGlobalVectorArray("uLightColor", _LightColor);
        Shader.SetGlobalVectorArray("uLightPos", _LightPos);
        Shader.SetGlobalVectorArray("uLightDir", _LightDir);
        Shader.SetGlobalVectorArray("uLightParam", _LightParam);
    }
}