using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class TrailGizmosScript : MonoBehaviour
{
    public float speed = 10;

    void Start()
    {
        
    }

    void Update()
    {
        if (Input.GetKey(KeyCode.A))
        {
            transform.Rotate(new Vector3(0, -90 * Time.deltaTime), Space.World);
            transform.Rotate(new Vector3(0, 0, 90 * Time.deltaTime), Space.Self);
        }

        if (Input.GetKey(KeyCode.D))
        {
            transform.Rotate(new Vector3(0, 90 * Time.deltaTime, 0), Space.World);
            transform.Rotate(new Vector3(0, 0, -90 * Time.deltaTime), Space.Self);
        }

        if (Input.GetKey(KeyCode.W))
        {
            transform.Translate(speed * Vector3.forward * Time.deltaTime);
        }

        var a = transform.rotation.eulerAngles;
        transform.rotation = Quaternion.Lerp(transform.rotation, Quaternion.Euler(a.x, a.y ,0), 2.0f * Time.deltaTime);
    }

    private void OnDrawGizmos()
    {
        Gizmos.DrawSphere(transform.position, 0.25f);
        Gizmos.color = Color.blue;
        Gizmos.DrawLine(transform.position, transform.position + transform.forward * 1);
        Gizmos.color = Color.green;
        Gizmos.DrawLine(transform.position, transform.position + transform.up * 1);
        Gizmos.color = Color.red;
        Gizmos.DrawLine(transform.position, transform.position + transform.right * 1);
    }
}
