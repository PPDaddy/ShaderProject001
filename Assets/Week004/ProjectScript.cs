using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class ProjectScript : MonoBehaviour
{
    public Material postProjectShader;

    public Camera projectCamera;

    void Start()
    {
        
    }

    void Update()
    {
        Matrix4x4 P = projectCamera.projectionMatrix;
        Matrix4x4 V = projectCamera.transform.worldToLocalMatrix;
        Matrix4x4 VP = P * V;

        postProjectShader.SetMatrix("utexVPMat", VP );
        postProjectShader.SetMatrix("utexVMat", V );

        //utexPMat
    }
}
