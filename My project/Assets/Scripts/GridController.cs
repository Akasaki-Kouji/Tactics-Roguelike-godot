using UnityEngine;
using System.Collections.Generic;

public class GridController : MonoBehaviour
{
    [Header("Grid Settings")]
    public int gridWidth = 8;
    public int gridHeight = 8;
    public float cellSize = 1f;

    [Header("Grid Visual")]
    public GameObject gridCellPrefab;
    public Color defaultCellColor = Color.white;
    public Color highlightColor = Color.yellow;

    private GameObject[,] gridCells;
    private SpriteRenderer[,] cellRenderers;
    private Unit[,] unitGrid;

    public static GridController Instance;

    void Awake()
    {
        Instance = this;
        InitializeGrid();
    }

    void InitializeGrid()
    {
        gridCells = new GameObject[gridWidth, gridHeight];
        cellRenderers = new SpriteRenderer[gridWidth, gridHeight];
        unitGrid = new Unit[gridWidth, gridHeight];

        for (int x = 0; x < gridWidth; x++)
        {
            for (int y = 0; y < gridHeight; y++)
            {
                Vector3 worldPos = new Vector3(x * cellSize, y * cellSize, 0);

                GameObject cell = CreateGridCell(worldPos);
                cell.name = $"Cell_{x}_{y}";
                cell.transform.parent = transform;

                gridCells[x, y] = cell;
                cellRenderers[x, y] = cell.GetComponent<SpriteRenderer>();

                if (cellRenderers[x, y] != null)
                {
                    cellRenderers[x, y].color = defaultCellColor;
                }
            }
        }
    }

    GameObject CreateGridCell(Vector3 position)
    {
        if (gridCellPrefab != null)
        {
            return Instantiate(gridCellPrefab, position, Quaternion.identity);
        }
        else
        {
            GameObject cell = GameObject.CreatePrimitive(PrimitiveType.Quad);
            cell.transform.position = position;
            cell.transform.localScale = Vector3.one * cellSize * 0.9f;

            Destroy(cell.GetComponent<Collider>());

            return cell;
        }
    }

    public Vector2Int WorldToGrid(Vector3 worldPosition)
    {
        int x = Mathf.RoundToInt(worldPosition.x / cellSize);
        int y = Mathf.RoundToInt(worldPosition.y / cellSize);
        return new Vector2Int(x, y);
    }

    public Vector3 GridToWorld(Vector2Int gridPosition)
    {
        return new Vector3(gridPosition.x * cellSize, gridPosition.y * cellSize, 0);
    }

    public bool IsValidGridPosition(Vector2Int gridPos)
    {
        return gridPos.x >= 0 && gridPos.x < gridWidth &&
               gridPos.y >= 0 && gridPos.y < gridHeight;
    }

    public Unit GetUnitAt(Vector2Int gridPos)
    {
        if (!IsValidGridPosition(gridPos)) return null;
        return unitGrid[gridPos.x, gridPos.y];
    }

    public void PlaceUnit(Unit unit, Vector2Int gridPos)
    {
        if (!IsValidGridPosition(gridPos)) return;

        if (unitGrid[gridPos.x, gridPos.y] != null)
        {
            Debug.LogWarning($"Cell {gridPos} is already occupied!");
            return;
        }

        unitGrid[gridPos.x, gridPos.y] = unit;
        unit.SetGridPosition(gridPos);
    }

    public void RemoveUnit(Vector2Int gridPos)
    {
        if (!IsValidGridPosition(gridPos)) return;
        unitGrid[gridPos.x, gridPos.y] = null;
    }

    public void MoveUnit(Vector2Int from, Vector2Int to)
    {
        if (!IsValidGridPosition(from) || !IsValidGridPosition(to)) return;

        Unit unit = GetUnitAt(from);
        if (unit == null) return;

        RemoveUnit(from);
        PlaceUnit(unit, to);
    }

    public void HighlightCell(Vector2Int gridPos, Color color)
    {
        if (!IsValidGridPosition(gridPos)) return;

        if (cellRenderers[gridPos.x, gridPos.y] != null)
        {
            cellRenderers[gridPos.x, gridPos.y].color = color;
        }
    }

    public void ClearHighlights()
    {
        for (int x = 0; x < gridWidth; x++)
        {
            for (int y = 0; y < gridHeight; y++)
            {
                if (cellRenderers[x, y] != null)
                {
                    cellRenderers[x, y].color = defaultCellColor;
                }
            }
        }
    }

    public List<Vector2Int> GetValidMovePositions(Vector2Int startPos, int moveRange)
    {
        List<Vector2Int> validPositions = new List<Vector2Int>();

        for (int x = 0; x < gridWidth; x++)
        {
            for (int y = 0; y < gridHeight; y++)
            {
                Vector2Int targetPos = new Vector2Int(x, y);
                int distance = Mathf.Abs(startPos.x - x) + Mathf.Abs(startPos.y - y);

                if (distance <= moveRange && distance > 0 && GetUnitAt(targetPos) == null)
                {
                    validPositions.Add(targetPos);
                }
            }
        }

        return validPositions;
    }

    public Vector2Int GetClickedGridPosition()
    {
        Vector3 mouseScreenPos = Input.mousePosition;
        mouseScreenPos.z = Camera.main.transform.position.z * -1; // カメラからの距離
        Vector3 mouseWorldPos = Camera.main.ScreenToWorldPoint(mouseScreenPos);

        Debug.Log($"Mouse Screen: {Input.mousePosition}, World: {mouseWorldPos}, Grid: {WorldToGrid(mouseWorldPos)}");

        return WorldToGrid(mouseWorldPos);
    }
}