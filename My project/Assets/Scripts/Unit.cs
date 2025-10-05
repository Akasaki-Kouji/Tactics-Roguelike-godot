using UnityEngine;

public class Unit : MonoBehaviour
{
    [Header("Unit Stats")]
    public int maxHP = 20;
    public int currentHP = 20;
    public int attack = 8;
    public int defense = 3;
    public int moveRange = 5;
    public int attackRange = 1;

    [Header("Unit Info")]
    public bool isAlly = true;
    public string unitName = "Unit";

    [Header("Position")]
    public Vector2Int gridPosition;
    public bool hasActed = false;

    [Header("Visual")]
    public Renderer unitRenderer;

    void Start()
    {
        if (unitRenderer == null)
            unitRenderer = GetComponent<Renderer>();

        currentHP = maxHP;
        UpdateVisual();
    }

    public void TakeDamage(int damage)
    {
        int actualDamage = Mathf.Max(1, damage - defense);
        currentHP -= actualDamage;
        currentHP = Mathf.Max(0, currentHP);

        if (currentHP <= 0)
        {
            Die();
        }
    }

    public void Heal(int amount)
    {
        currentHP += amount;
        currentHP = Mathf.Min(currentHP, maxHP);
    }

    public void Die()
    {
        gameObject.SetActive(false);
    }

    public bool IsAlive()
    {
        return currentHP > 0 && gameObject.activeInHierarchy;
    }

    public void SetGridPosition(Vector2Int newPosition)
    {
        gridPosition = newPosition;
        transform.position = new Vector3(newPosition.x, newPosition.y, 0);
    }

    public void ResetActionState()
    {
        hasActed = false;
    }

    public void SetActed()
    {
        hasActed = true;
    }

    void UpdateVisual()
    {
        if (unitRenderer != null)
        {
            unitRenderer.material.color = isAlly ? Color.blue : Color.red;
        }
    }

    public int GetDistanceTo(Vector2Int targetPosition)
    {
        return Mathf.Abs(gridPosition.x - targetPosition.x) + Mathf.Abs(gridPosition.y - targetPosition.y);
    }

    public bool CanAttack(Unit target)
    {
        if (target == null || !target.IsAlive()) return false;
        return GetDistanceTo(target.gridPosition) <= attackRange;
    }

    public bool CanMoveTo(Vector2Int targetPosition)
    {
        return GetDistanceTo(targetPosition) <= moveRange;
    }
}