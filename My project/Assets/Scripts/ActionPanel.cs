using UnityEngine;
using UnityEngine.UI;

public class ActionPanel : MonoBehaviour
{
    [Header("UI Buttons")]
    public Button moveButton;
    public Button attackButton;
    public Button itemButton;
    public Button waitButton;
    public Button endTurnButton;

    [Header("Action State")]
    public bool isInMoveMode = false;
    public bool isInAttackMode = false;
    public Unit selectedUnit = null;

    [Header("Item")]
    public int healingPotions = 1;

    void Start()
    {
        SetupButtons();
        UpdateButtonStates();
    }

    void SetupButtons()
    {
        if (moveButton != null)
            moveButton.onClick.AddListener(OnMoveClicked);

        if (attackButton != null)
            attackButton.onClick.AddListener(OnAttackClicked);

        if (itemButton != null)
            itemButton.onClick.AddListener(OnItemClicked);

        if (waitButton != null)
            waitButton.onClick.AddListener(OnWaitClicked);

        if (endTurnButton != null)
            endTurnButton.onClick.AddListener(OnEndTurnClicked);
    }

    void Update()
    {
        if (!TurnManager.Instance.IsPlayerTurn()) return;

        HandleInput();
        UpdateButtonStates();
    }

    void HandleInput()
    {
        if (Input.GetMouseButtonDown(0))
        {
            // Raycastでユニットの直接クリック検出
            Ray ray = Camera.main.ScreenPointToRay(Input.mousePosition);
            RaycastHit hit;

            if (Physics.Raycast(ray, out hit))
            {
                Unit clickedUnit = hit.collider.GetComponent<Unit>();
                if (clickedUnit != null)
                {
                    // ユニットを直接クリックした場合
                    if (!isInMoveMode && !isInAttackMode)
                    {
                        HandleDirectUnitSelection(clickedUnit);
                        return;
                    }
                }
            }

            // グリッド座標での処理（移動・攻撃モード用）
            Vector2Int clickedPos = GridController.Instance.GetClickedGridPosition();

            if (isInMoveMode)
            {
                HandleMoveAction(clickedPos);
            }
            else if (isInAttackMode)
            {
                HandleAttackAction(clickedPos);
            }
            else
            {
                HandleUnitSelection(clickedPos);
            }
        }
    }

    void HandleDirectUnitSelection(Unit clickedUnit)
    {
        if (clickedUnit != null && clickedUnit.isAlly && clickedUnit.IsAlive() && !clickedUnit.hasActed)
        {
            selectedUnit = clickedUnit;
            GridController.Instance.ClearHighlights();
            GridController.Instance.HighlightCell(clickedUnit.gridPosition, Color.green);
        }
    }

    void HandleUnitSelection(Vector2Int gridPos)
    {
        Unit clickedUnit = GridController.Instance.GetUnitAt(gridPos);

        if (clickedUnit != null && clickedUnit.isAlly && clickedUnit.IsAlive() && !clickedUnit.hasActed)
        {
            selectedUnit = clickedUnit;
            GridController.Instance.ClearHighlights();
            GridController.Instance.HighlightCell(gridPos, Color.green);
        }
    }

    void HandleMoveAction(Vector2Int targetPos)
    {
        if (selectedUnit != null)
        {
            // 移動範囲チェックをより柔軟に
            int distance = selectedUnit.GetDistanceTo(targetPos);
            if (distance <= selectedUnit.moveRange && distance > 0)
            {
                Unit occupyingUnit = GridController.Instance.GetUnitAt(targetPos);
                if (occupyingUnit == null && GridController.Instance.IsValidGridPosition(targetPos))
                {
                    Vector2Int oldPos = selectedUnit.gridPosition;
                    GridController.Instance.MoveUnit(oldPos, targetPos);
                    selectedUnit.SetActed();

                    Debug.Log($"Unit moved from {oldPos} to {targetPos}");

                    ExitMoveMode();
                    ClearSelection();
                    return;
                }
            }
        }

        ExitMoveMode();
    }

    void HandleAttackAction(Vector2Int targetPos)
    {
        Unit target = GridController.Instance.GetUnitAt(targetPos);

        if (selectedUnit != null && target != null && !target.isAlly && selectedUnit.CanAttack(target))
        {
            int damage = selectedUnit.attack;
            target.TakeDamage(damage);

            Debug.Log($"{selectedUnit.unitName} attacks {target.unitName} for {damage} damage!");

            selectedUnit.SetActed();
            TurnManager.Instance.CheckWinCondition();

            ExitAttackMode();
            ClearSelection();
        }
        else
        {
            ExitAttackMode();
        }
    }

    public void OnMoveClicked()
    {
        if (selectedUnit == null || selectedUnit.hasActed) return;

        if (!isInMoveMode)
        {
            EnterMoveMode();
        }
        else
        {
            ExitMoveMode();
        }
    }

    public void OnAttackClicked()
    {
        if (selectedUnit == null || selectedUnit.hasActed) return;

        if (!isInAttackMode)
        {
            EnterAttackMode();
        }
        else
        {
            ExitAttackMode();
        }
    }

    public void OnItemClicked()
    {
        if (selectedUnit == null || selectedUnit.hasActed || healingPotions <= 0) return;

        selectedUnit.Heal(10);
        healingPotions--;
        selectedUnit.SetActed();

        Debug.Log($"{selectedUnit.unitName} uses healing potion! HP: {selectedUnit.currentHP}/{selectedUnit.maxHP}");

        ClearSelection();
    }

    public void OnWaitClicked()
    {
        if (selectedUnit == null || selectedUnit.hasActed) return;

        selectedUnit.SetActed();
        ClearSelection();
    }

    public void OnEndTurnClicked()
    {
        ExitAllModes();
        ClearSelection();
        TurnManager.Instance.EndPlayerTurn();
    }

    void EnterMoveMode()
    {
        isInMoveMode = true;
        isInAttackMode = false;

        GridController.Instance.ClearHighlights();

        if (selectedUnit != null)
        {
            var validMoves = GridController.Instance.GetValidMovePositions(
                selectedUnit.gridPosition, selectedUnit.moveRange);

            foreach (var pos in validMoves)
            {
                GridController.Instance.HighlightCell(pos, Color.blue);
            }
        }
    }

    void ExitMoveMode()
    {
        isInMoveMode = false;
        GridController.Instance.ClearHighlights();
    }

    void EnterAttackMode()
    {
        isInAttackMode = true;
        isInMoveMode = false;

        GridController.Instance.ClearHighlights();

        if (selectedUnit != null)
        {
            var enemies = TurnManager.Instance.GetAliveEnemies();
            foreach (var enemy in enemies)
            {
                if (selectedUnit.CanAttack(enemy))
                {
                    GridController.Instance.HighlightCell(enemy.gridPosition, Color.red);
                }
            }
        }
    }

    void ExitAttackMode()
    {
        isInAttackMode = false;
        GridController.Instance.ClearHighlights();
    }

    void ExitAllModes()
    {
        isInMoveMode = false;
        isInAttackMode = false;
        GridController.Instance.ClearHighlights();
    }

    void ClearSelection()
    {
        selectedUnit = null;
        ExitAllModes();
    }

    void UpdateButtonStates()
    {
        bool hasSelection = selectedUnit != null && !selectedUnit.hasActed;

        if (moveButton != null)
            moveButton.interactable = hasSelection;

        if (attackButton != null)
            attackButton.interactable = hasSelection;

        if (itemButton != null)
            itemButton.interactable = hasSelection && healingPotions > 0;

        if (waitButton != null)
            waitButton.interactable = hasSelection;

        if (endTurnButton != null)
            endTurnButton.interactable = TurnManager.Instance.IsPlayerTurn();
    }
}