using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class ScreenDepthNormal : MonoBehaviour
{
    public Camera cam;
    //private Material postprocessMaterial;

    void Start()
    {
        cam = GetComponent<Camera>();
        cam.depthTextureMode = DepthTextureMode.DepthNormals;
    }
    
    void Update()
    {

    }

    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        //Graphics.Blit(src, dest);
    }
}
