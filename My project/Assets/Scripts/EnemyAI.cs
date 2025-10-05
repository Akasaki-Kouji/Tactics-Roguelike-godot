using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System.Linq;

public class EnemyAI : MonoBehaviour
{
    [Header("AI Settings")]
    public float actionDelay = 1f;

    public static EnemyAI Instance;

    void Awake()
    {
        Instance = this;
    }

    public void ExecuteEnemyTurn()
    {
        StartCoroutine(ProcessEnemyTurn());
    }

    IEnumerator ProcessEnemyTurn()
    {
        List<Unit> aliveEnemies = TurnManager.Instance.GetAliveEnemies();

        foreach (Unit enemy in aliveEnemies)
        {
            if (enemy != null && enemy.IsAlive() && !enemy.hasActed)
            {
                yield return StartCoroutine(ProcessEnemyAction(enemy));
                yield return new WaitForSeconds(actionDelay);
            }
        }

        TurnManager.Instance.EndEnemyTurn();
    }

    IEnumerator ProcessEnemyAction(Unit enemy)
    {
        List<Unit> aliveAllies = TurnManager.Instance.GetAliveAllies();

        if (aliveAllies.Count == 0)
        {
            enemy.SetActed();
            yield break;
        }

        Unit nearestAlly = GetNearestAlly(enemy, aliveAllies);

        if (nearestAlly != null)
        {
            if (enemy.CanAttack(nearestAlly))
            {
                AttackTarget(enemy, nearestAlly);
            }
            else
            {
                MoveTowardsTarget(enemy, nearestAlly);
            }
        }

        enemy.SetActed();
    }

    Unit GetNearestAlly(Unit enemy, List<Unit> allies)
    {
        Unit nearest = null;
        int shortestDistance = int.MaxValue;

        foreach (Unit ally in allies)
        {
            if (ally != null && ally.IsAlive())
            {
                int distance = enemy.GetDistanceTo(ally.gridPosition);
                if (distance < shortestDistance)
                {
                    shortestDistance = distance;
                    nearest = ally;
                }
            }
        }

        return nearest;
    }

    void AttackTarget(Unit attacker, Unit target)
    {
        Debug.Log($"{attacker.unitName} attacks {target.unitName}!");

        int damage = attacker.attack;
        target.TakeDamage(damage);

        Debug.Log($"{target.unitName} takes {damage} damage! HP: {target.currentHP}/{target.maxHP}");

        TurnManager.Instance.CheckWinCondition();
    }

    void MoveTowardsTarget(Unit enemy, Unit target)
    {
        Vector2Int targetDirection = GetBestMoveDirection(enemy, target);

        if (targetDirection != enemy.gridPosition)
        {
            Vector2Int currentPos = enemy.gridPosition;

            if (GridController.Instance.GetUnitAt(targetDirection) == null)
            {
                GridController.Instance.MoveUnit(currentPos, targetDirection);
                Debug.Log($"{enemy.unitName} moves from {currentPos} to {targetDirection}");
            }
        }
    }

    Vector2Int GetBestMoveDirection(Unit enemy, Unit target)
    {
        Vector2Int enemyPos = enemy.gridPosition;
        Vector2Int targetPos = target.gridPosition;

        Vector2Int bestMove = enemyPos;
        int bestDistance = enemy.GetDistanceTo(targetPos);

        Vector2Int[] directions = {
            new Vector2Int(0, 1),   // Up
            new Vector2Int(0, -1),  // Down
            new Vector2Int(1, 0),   // Right
            new Vector2Int(-1, 0)   // Left
        };

        foreach (Vector2Int dir in directions)
        {
            Vector2Int newPos = enemyPos + dir;

            if (GridController.Instance.IsValidGridPosition(newPos) &&
                GridController.Instance.GetUnitAt(newPos) == null)
            {
                int distance = Mathf.Abs(newPos.x - targetPos.x) + Mathf.Abs(newPos.y - targetPos.y);

                if (distance < bestDistance)
                {
                    bestDistance = distance;
                    bestMove = newPos;
                }
            }
        }

        return bestMove;
    }
}