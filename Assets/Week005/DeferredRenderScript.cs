using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class DeferredRenderScript : MonoBehaviour
{
    public Material deferredRenderMat;

    public Light pointLight;

    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {

    }

    public void LateUpdate()
    {
        if (deferredRenderMat != null && pointLight !=null)
        {
            //deferredRenderMat.SetMatrix("uCameraInvViewMatrix", Camera.main.worldToCameraMatrix.inverse);
            //deferredRenderMat.SetMatrix("uCameraViewMatrix", Camera.main.worldToCameraMatrix);

            Vector4 lightPos = Camera.main.worldToCameraMatrix * pointLight.transform.position;

            deferredRenderMat.SetVector("uPointLightPos", lightPos );
        }

    }
}
