using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Grass
{
    [ExecuteInEditMode]
    public class Mover : MonoBehaviour
    {
        [SerializeField]
        private Vector3 m_centre = Vector3.zero;

        [SerializeField]
        [Min(0f)]
        private float m_radius = 1f;

        [SerializeField]
        private float m_speed = 1f;

        private float m_currentPos = 0f;

        private void Reset() => m_currentPos = 0f;

        private void Update()
        {
            m_currentPos += m_speed * Time.deltaTime;

            Vector3 pos = m_centre + m_radius * new Vector3(Mathf.Cos(m_currentPos * Mathf.PI), 0f, Mathf.Sin(m_currentPos * Mathf.PI));

            transform.position = pos;
        }
    }
}