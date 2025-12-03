# Analytics Dashboard UI Guide

## Accessing the Dashboard

1. Open the app and tap the menu icon (☰) in the top-left corner
2. In the project drawer, tap the **"View Analytics"** button
3. The analytics dashboard will load and display your financial insights

## Dashboard Layout

### 1. Summary Cards Section
Located at the top of the dashboard, this section displays four key metrics in colorful cards:

```
┌─────────────────────────────────────────────────────┐
│  Summary                                            │
│  ┌────────────────────┬─────────────────────┐      │
│  │ 💚 Income          │ 🔴 Expenses         │      │
│  │ $5,000.00          │ $2,500.00           │      │
│  └────────────────────┴─────────────────────┘      │
│  ┌────────────────────┬─────────────────────┐      │
│  │ 💙 Balance         │ 🟣 Transactions     │      │
│  │ $2,500.00          │ 45                  │      │
│  └────────────────────┴─────────────────────┘      │
└─────────────────────────────────────────────────────┘
```

- **Income** (Green): Total income across all projects
- **Expenses** (Red): Total expenses across all projects
- **Balance** (Blue): Net balance (Income - Expenses)
- **Transactions** (Purple): Total number of transactions

### 2. Project Contributions (Pie Chart)
Shows the income distribution across all your projects:

```
┌─────────────────────────────────────────────────────┐
│  Project Contributions                              │
│                                                     │
│         ╱────╲                                      │
│       ╱   🔵  ╲                                     │
│      │         │                                    │
│       ╲  🟢 🟠╱                                     │
│         ╲────╱                                      │
│                                                     │
│  ● Project A  ● Project B  ● Project C             │
└─────────────────────────────────────────────────────┘
```

- Each slice represents a project's contribution to total income
- Percentage labels show the exact contribution
- Color-coded legend identifies each project
- Helps identify which projects are most profitable

### 3. Financial Timeline (Line Chart)
Displays trends over time with three lines:

```
┌─────────────────────────────────────────────────────┐
│  Financial Timeline                                 │
│                                                     │
│  $                                                  │
│  5K ─                    ╱─────                     │
│     │        ╱───╲      ╱                          │
│  3K ─  ─────       ────                            │
│     │╱───────────────────────╲                     │
│  1K ─                        ╲─────                │
│     │                                               │
│   0 ┴────┬────┬────┬────┬────┬────                │
│         Jan  Feb  Mar  Apr  May  Jun               │
│                                                     │
│  ─ Income  ─ Expenses  ─ Balance                   │
└─────────────────────────────────────────────────────┘
```

- **Green Line**: Income over time
- **Red Line**: Expenses over time
- **Blue Line**: Balance over time (cumulative)
- Monthly granularity by default
- Automatically handles negative balances
- Light shaded areas under income/expenses lines for clarity

### 4. Top Expensive Projects
Lists projects ranked by total expenses:

```
┌─────────────────────────────────────────────────────┐
│  Top Expensive Projects                             │
│                                                     │
│  Project B                            $1,200.00    │
│  Project C                              $800.00    │
│  Project A                              $500.00    │
│  Project D                              $200.00    │
│  Project E                              $100.00    │
└─────────────────────────────────────────────────────┘
```

- Shows up to 5 projects
- Sorted by expense amount (highest first)
- Helps identify projects that need attention
- Red text emphasizes the expense amounts

## Empty State

When no data is available, the dashboard shows a friendly empty state:

```
┌─────────────────────────────────────────────────────┐
│                                                     │
│                    📊                               │
│                                                     │
│               No data available                     │
│                                                     │
│        Add some transactions to see analytics       │
│                                                     │
└─────────────────────────────────────────────────────┘
```

## Color Scheme

- **Green**: Income, positive indicators
- **Red**: Expenses, negative indicators
- **Blue**: Balance, neutral indicators
- **Purple**: Transaction count
- **Background**: Soft gradient (blue to indigo)

## Responsive Design

The dashboard adapts to different screen sizes:
- Mobile: Single column layout with scrolling
- Tablet/Desktop: Optimized spacing and card sizes
- All charts remain interactive and readable

## Navigation

- **Back**: Tap the back arrow to return to the home screen
- **Drawer**: Access via the hamburger menu
- **Refresh**: Return to home and come back to refresh data

## Tips for Best Insights

1. Add transactions regularly for accurate trends
2. Use descriptive project names for clearer charts
3. Check the dashboard weekly to track progress
4. Use top expensive projects to identify cost-cutting opportunities
5. Monitor balance trend to ensure financial health
