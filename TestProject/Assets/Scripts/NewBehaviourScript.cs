using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.UI;
using NVIDIA.Flex;

public class NewBehaviourScript : MonoBehaviour
{
    // 接触面の法線のy成分がこの値以上なら地面とみなす
    private const float GroundNormalThreshold = 0.7f;

    private Rigidbody rb = null;
    private static int maxHP = 100;
    private int currentHP;
    public Slider slider;

    // Start is called before the first frame update
    void Start()
    {
        this.rb = this.GetComponent<Rigidbody>();
        this.currentHP = maxHP;
        this.slider.value = (float)this.currentHP / (float)maxHP;
    }

    // Update is called once per frame
    void FixedUpdate()
    {
        if (Input.GetKey(KeyCode.LeftArrow))
        {
            this.rb.transform.Rotate(0, -2.0f, 0);
        }
        if (Input.GetKey(KeyCode.RightArrow))
        {
            this.rb.transform.Rotate(0, 2.0f, 0);
        }
        if (Input.GetKey(KeyCode.Space) && this.rb.velocity.magnitude < 5.0f)
        {
            this.rb.AddForce(this.rb.transform.forward * 15.0f, ForceMode.Acceleration);
        }
        if (this.rb.position.y < -1.0f)
        {
            SceneManager.LoadScene("GameOver_fall");
        }
    }

    private static bool IsGroundContact(Collision collision)
    {
        if (collision.contacts.Length == 0)
        {
            return false;
        }
        foreach (ContactPoint contact in collision.contacts)
        {
            if (contact.normal.y < GroundNormalThreshold)
            {
                return false;
            }
        }
        return true;
    }

    private void OnCollisionEnter(Collision collision)
    {
        if (IsGroundContact(collision))
        {
            return;
        }
        // 衝突した場合体力を減らす
        this.currentHP = this.currentHP - 2;
        this.slider.value = (float)this.currentHP / (float)maxHP;
        if (this.currentHP <= 0)
        {
            SceneManager.LoadScene("GameOver_fall");
        }
    }

    private void OnTriggerEnter(Collider other)
    {
        if (other.GetComponentInParent<FlexSourceActor>() == null)
        {
            return;
        }
        // 水流に当たったらクリア
        SceneManager.LoadScene("GameOver_clear");
    }
}
