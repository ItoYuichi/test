using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class NewBehaviourScript : MonoBehaviour
{
    private Rigidbody rb = null;

    // Start is called before the first frame update
    void Start()
    {
        this.rb = this.GetComponent<Rigidbody>();   
    }

    // Update is called once per frame
    void Update()
    {
        if (Input.GetKey(KeyCode.LeftArrow))
        {
            this.rb.transform.Rotate(0, -2.0f, 0);
        }
        if (Input.GetKey(KeyCode.RightArrow))
        {
            this.rb.transform.Rotate(0, 2.0f, 0);
        }
        if (Input.GetKey(KeyCode.Space))
        {
            this.rb.AddForce(transform.forward * 15.0f, ForceMode.Acceleration);
        }
    }
}
