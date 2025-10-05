using UnityEngine;

public class BattleEntry : MonoBehaviour
{
    [Header("Unit Setup")]
    public GameObject unitPrefab;

    [Header("Initial Positions")]
    public Vector2Int allyStartPosition = new Vector2Int(1, 3);
    public Vector2Int enemyStartPosition = new Vector2Int(6, 4);

    void Start()
    {
        InitializeBattle();
    }

    void InitializeBattle()
    {
        CreateAllyUnit();
        CreateEnemyUnit();
    }

    void CreateAllyUnit()
    {
        GameObject allyObj = CreateUnitObject("Ally Swordsman", true);
        Unit allyUnit = allyObj.GetComponent<Unit>();

        allyUnit.maxHP = 20;
        allyUnit.currentHP = 20;
        allyUnit.attack = 8;
        allyUnit.defense = 3;
        allyUnit.moveRange = 5;
        allyUnit.attackRange = 1;
        allyUnit.isAlly = true;
        allyUnit.unitName = "Swordsman";

        GridController.Instance.PlaceUnit(allyUnit, allyStartPosition);
    }

    void CreateEnemyUnit()
    {
        GameObject enemyObj = CreateUnitObject("Enemy Lancer", false);
        Unit enemyUnit = enemyObj.GetComponent<Unit>();

        enemyUnit.maxHP = 22;
        enemyUnit.currentHP = 22;
        enemyUnit.attack = 9;
        enemyUnit.defense = 4;
        enemyUnit.moveRange = 4;
        enemyUnit.attackRange = 1;
        enemyUnit.isAlly = false;
        enemyUnit.unitName = "Lancer";

        GridController.Instance.PlaceUnit(enemyUnit, enemyStartPosition);
    }

    GameObject CreateUnitObject(string unitName, bool isAlly)
    {
        GameObject unitObj;

        if (unitPrefab != null)
        {
            unitObj = Instantiate(unitPrefab);
        }
        else
        {
            unitObj = GameObject.CreatePrimitive(PrimitiveType.Quad);
            unitObj.transform.localScale = Vector3.one * 0.8f;

            Destroy(unitObj.GetComponent<Collider>());

            if (!unitObj.GetComponent<Unit>())
                unitObj.AddComponent<Unit>();
        }

        unitObj.name = unitName;

        SpriteRenderer spriteRenderer = unitObj.GetComponent<SpriteRenderer>();
        if (spriteRenderer != null)
        {
            spriteRenderer.color = isAlly ? Color.blue : Color.red;
        }

        return unitObj;
    }
}