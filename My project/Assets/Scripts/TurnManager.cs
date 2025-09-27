using UnityEngine;
using System.Collections.Generic;
using System.Linq;

public enum GameState
{
    PlayerTurn,
    EnemyTurn,
    Victory,
    Defeat
}

public class TurnManager : MonoBehaviour
{
    [Header("Game State")]
    public GameState currentState = GameState.PlayerTurn;
    public int turnCount = 1;

    [Header("Units")]
    public List<Unit> allyUnits = new List<Unit>();
    public List<Unit> enemyUnits = new List<Unit>();

    [Header("UI References")]
    public ActionPanel actionPanel;
    public ResultPanel resultPanel;

    public static TurnManager Instance;

    void Awake()
    {
        Instance = this;
    }

    void Start()
    {
        FindAllUnits();
        StartPlayerTurn();
    }

    void FindAllUnits()
    {
        Unit[] allUnits = FindObjectsOfType<Unit>();

        allyUnits.Clear();
        enemyUnits.Clear();

        foreach (Unit unit in allUnits)
        {
            if (unit.isAlly)
                allyUnits.Add(unit);
            else
                enemyUnits.Add(unit);
        }
    }

    public void StartPlayerTurn()
    {
        currentState = GameState.PlayerTurn;
        ResetAlliedUnitsActions();

        if (actionPanel != null)
            actionPanel.gameObject.SetActive(true);

        CheckWinCondition();
    }

    public void EndPlayerTurn()
    {
        if (actionPanel != null)
            actionPanel.gameObject.SetActive(false);

        currentState = GameState.EnemyTurn;
        StartEnemyTurn();
    }

    void StartEnemyTurn()
    {
        currentState = GameState.EnemyTurn;
        ResetEnemyUnitsActions();

        EnemyAI.Instance?.ExecuteEnemyTurn();
    }

    public void EndEnemyTurn()
    {
        turnCount++;
        StartPlayerTurn();
    }

    void ResetAlliedUnitsActions()
    {
        foreach (Unit unit in allyUnits)
        {
            if (unit != null && unit.IsAlive())
                unit.ResetActionState();
        }
    }

    void ResetEnemyUnitsActions()
    {
        foreach (Unit unit in enemyUnits)
        {
            if (unit != null && unit.IsAlive())
                unit.ResetActionState();
        }
    }

    public bool CheckWinCondition()
    {
        List<Unit> aliveEnemies = enemyUnits.Where(u => u != null && u.IsAlive()).ToList();
        List<Unit> aliveAllies = allyUnits.Where(u => u != null && u.IsAlive()).ToList();

        if (aliveEnemies.Count == 0)
        {
            Victory();
            return true;
        }
        else if (aliveAllies.Count == 0)
        {
            Defeat();
            return true;
        }

        return false;
    }

    void Victory()
    {
        currentState = GameState.Victory;
        if (resultPanel != null)
            resultPanel.ShowVictory();
    }

    void Defeat()
    {
        currentState = GameState.Defeat;
        if (resultPanel != null)
            resultPanel.ShowDefeat();
    }

    public void RestartGame()
    {
        UnityEngine.SceneManagement.SceneManager.LoadScene(
            UnityEngine.SceneManagement.SceneManager.GetActiveScene().name);
    }

    public List<Unit> GetAliveAllies()
    {
        return allyUnits.Where(u => u != null && u.IsAlive()).ToList();
    }

    public List<Unit> GetAliveEnemies()
    {
        return enemyUnits.Where(u => u != null && u.IsAlive()).ToList();
    }

    public bool IsPlayerTurn()
    {
        return currentState == GameState.PlayerTurn;
    }

    public bool IsGameOver()
    {
        return currentState == GameState.Victory || currentState == GameState.Defeat;
    }
}