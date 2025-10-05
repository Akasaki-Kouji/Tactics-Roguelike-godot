using UnityEngine;
using UnityEngine.UI;

public class UIManager : MonoBehaviour
{
    [Header("UI Text")]
    public Text turnText;
    public Text objectiveText;
    public Text allyStatsText;

    [Header("Panels")]
    public ActionPanel actionPanel;
    public ResultPanel resultPanel;

    void Update()
    {
        UpdateUI();
    }

    void UpdateUI()
    {
        UpdateTurnInfo();
        UpdateObjective();
        UpdateAllyStats();
    }

    void UpdateTurnInfo()
    {
        if (turnText != null && TurnManager.Instance != null)
        {
            string stateText = TurnManager.Instance.currentState == GameState.PlayerTurn ? "Player" : "Enemy";
            turnText.text = $"Turn: {TurnManager.Instance.turnCount} | {stateText} Turn";
        }
    }

    void UpdateObjective()
    {
        if (objectiveText != null && TurnManager.Instance != null)
        {
            int enemyCount = TurnManager.Instance.GetAliveEnemies().Count;
            objectiveText.text = $"Objective: Defeat Enemy | Enemy Left: {enemyCount}";
        }
    }

    void UpdateAllyStats()
    {
        if (allyStatsText != null && TurnManager.Instance != null)
        {
            var allies = TurnManager.Instance.GetAliveAllies();
            if (allies.Count > 0)
            {
                Unit ally = allies[0];
                allyStatsText.text = $"Ally HP {ally.currentHP}/{ally.maxHP}  ATK {ally.attack}  DEF {ally.defense}";
            }
        }
    }
}