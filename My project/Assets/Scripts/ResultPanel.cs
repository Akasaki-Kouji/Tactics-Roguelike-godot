using UnityEngine;
using UnityEngine.UI;

public class ResultPanel : MonoBehaviour
{
    [Header("UI Elements")]
    public GameObject victoryPanel;
    public GameObject defeatPanel;
    public Button restartButton;
    public Text resultText;

    void Start()
    {
        if (restartButton != null)
            restartButton.onClick.AddListener(OnRestartClicked);

        HideAllPanels();
    }

    public void ShowVictory()
    {
        HideAllPanels();

        if (victoryPanel != null)
        {
            victoryPanel.SetActive(true);
        }
        else if (resultText != null)
        {
            gameObject.SetActive(true);
            resultText.text = "VICTORY!";
            resultText.color = Color.green;
        }

        Debug.Log("Victory!");
    }

    public void ShowDefeat()
    {
        HideAllPanels();

        if (defeatPanel != null)
        {
            defeatPanel.SetActive(true);
        }
        else if (resultText != null)
        {
            gameObject.SetActive(true);
            resultText.text = "DEFEAT...";
            resultText.color = Color.red;
        }

        Debug.Log("Defeat...");
    }

    void HideAllPanels()
    {
        if (victoryPanel != null)
            victoryPanel.SetActive(false);

        if (defeatPanel != null)
            defeatPanel.SetActive(false);

        gameObject.SetActive(false);
    }

    public void OnRestartClicked()
    {
        TurnManager.Instance.RestartGame();
    }
}