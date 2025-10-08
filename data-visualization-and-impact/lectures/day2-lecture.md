Data Visualization and Impact: Insights and Best Practices — Day 2 Lecture
1. Performant Dashboards: Best Practices

To build fast, reliable, and responsive dashboards, focus on how data is stored and accessed before visualization.

Best practices:

Pre-aggregate the data — use grouping sets to prepare data at different granularity levels in advance.

Avoid joins on the fly — expensive operations at query time drastically slow down dashboards.

Remember:

When you’re at the dashboard layer, you are at the final stage.
There’s no downstream system — only a human reading the output.
So, prioritize clarity and speed over flexibility.

Low-latency storage:

Use a real-time, columnar database such as Apache Druid for quick, sub-second responses.

2. Building Dashboards That Make Sense

Design dashboards with the audience in mind — not all users want the same level of detail.

Identify your customer:

Executives: prefer simple visuals that are easy to interpret at a glance.
(e.g., high-level KPIs, trend lines, color-coded indicators)

Analysts: prefer dense, detailed dashboards with multiple views and metrics for deeper exploration.

3. Asking the Right Questions

Every effective dashboard answers a specific category of questions:

Question Type	Purpose / Example
Top-line questions	“How many users do we have?”, “How much revenue did we make?”, “How long do people spend on the app?”
Trend questions	“How do this year’s users compare to last year?”, “Are signups increasing month-over-month?”
Composition questions	“What % of users are on Android vs iOS?”, “What % of customers come from Europe?”

A good dashboard balances all three types, giving context to raw numbers.

4. Understanding Which Numbers Matter

Different types of aggregates provide different layers of insight — from global performance to detailed patterns.

1. Total Aggregates

Reported to Wall Street and often used in marketing.

Represent overall company health (e.g., Facebook reaches 2 billion users).

2. Time-Based Aggregates

Capture trends earlier than totals.

Help identify growth or decline patterns before they appear in total numbers.

3. Time & Entity-Based Aggregates

Used in A/B testing frameworks or segmented analysis.

Examples: user engagement by region over time.

4. Derivative Metrics

Include WoW (Week-over-Week), MoM (Month-over-Month), YoY (Year-over-Year) comparisons.

More sensitive to change, showing direction and rate of growth.

Example: In 2021, Airbnb prioritized “Year-over-2-Year” growth to account for COVID-19 disruptions that distorted regular YoY trends.

5. Dimensional Mix Metrics

Measure shifts in user composition (e.g., % US vs % India, % Android vs % iPhone).

Totals stay constant, but proportions shift — called mix shift.

Example: Users migrating from Android to iPhone still exist, but the dimension changes.

6. Retention / Survivorship Metrics

Measure how many users remain active after N days.

Example: “30-day retention rate” shows product stickiness and user loyalty.