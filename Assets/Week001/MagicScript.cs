using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class MagicScript : MonoBehaviour
{
    [Range(0,1.5f)]
    public float intensity; 
    public bool autoPlay;
    public Material PlanMat;
    public Material TowerMat;

    void Update()
    {
        if (PlanMat != null)
        {
            PlanMat.SetFloat("uSlant", intensity);
        }

        if (TowerMat != null)
        {
            TowerMat.SetFloat("uIntensity", intensity - 0.5f);
        }

        if (autoPlay && intensity <= 1.5f)
        {
            intensity = Mathf.Clamp(intensity + 1 * Time.deltaTime, 0, 1.5f);
        }
    }
}
