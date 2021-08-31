using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ShadowCameraScript : MonoBehaviour
{
    Camera myCamera;
    public Shader shadowShader;
    
    void Start()
    {
        myCamera = GetComponent<Camera>();
        myCamera.depthTextureMode = DepthTextureMode.Depth;
    }

    // Update is called once per frame
    void Update()
    {
        myCamera.SetReplacementShader(shadowShader, null);
    }
}
