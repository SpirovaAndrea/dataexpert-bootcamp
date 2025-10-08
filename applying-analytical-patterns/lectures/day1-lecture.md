# Applying Analytical Patterns - Day 1: Exploring SQL, Scaling Projects and Aggregation Analysis

## Introduction

Not all data engineering pipelines are built differently. There are a couple of patterns that you can learn and apply across different problems.

Repeatable analyses are your best friend. You can think in that higher level of abstraction, reduce the cognitive load of thinking about the SQL, and streamline your impact.

## Common Analytical Patterns

There are three main pattern categories you need to learn:

### 1. Aggregation-Based Patterns

These patterns focus on grouping and summarizing data.

**Use cases:**
- Trend analysis
- Root cause analysis

**Key technique:** GROUP BY is your friend.

**Important considerations:**
- Think about the combinations that matter the most
- Be careful when looking at many combinations
- Long time frame analysis

**How it works:**
You aggregate data across dimensions to find patterns, trends, or anomalies. For example, grouping sales by region and time period to identify where performance is strongest or weakest.

### 2. Cumulation-Based Patterns

These patterns care about the relationships between today and yesterday.

**Key technique:** FULL OUTER JOIN is your friend.

**Use cases:**
- State change tracking
- Survival analysis
- Growth accounting

**How it works:**
You compare today's data with yesterday's cumulated data to track how things change over time. This is useful for understanding user retention, feature adoption, or any metric where the transition from one state to another matters.

For example, tracking users who were active yesterday but inactive today, or vice versa.

### 3. Window-Based Patterns

These patterns focus on rolling calculations and comparisons over time.

**Common analyses:**
- Day over day (DoD)
- Week over week (WoW)
- Month over month (MoM)
- Year over year (YoY)
- Rolling sum or average
- Ranking

**Keyword:** Rolling

**Key technique:** Mostly solved using window functions.

**Syntax pattern:**
```
FUNCTION OVER (
  PARTITION BY keys 
  ORDER BY sort 
  ROWS BETWEEN n PRECEDING AND CURRENT ROW
)
```

**How it works:**
Window functions let you perform calculations across a set of rows that are related to the current row. Unlike GROUP BY, window functions don't collapse rows - they add calculated columns while keeping all rows.

For example, calculating a 7-day rolling average of daily revenue or ranking customers by their total purchase amount within each region.

## State Change Tracking

This is a common pattern that appears across all three categories. It involves monitoring and analyzing how entities move from one state to another over time.

Examples:
- Users going from active to inactive
- Orders moving from pending to completed
- Features transitioning from trial to paid

Understanding state changes helps you identify critical moments in user journeys, spot potential issues, and measure the effectiveness of interventions.

## Scaling Your Analysis

When working with these patterns, remember:

**Focus on combinations that matter** - Don't analyze every possible combination of dimensions. Think about what business questions you're trying to answer and which combinations will give you meaningful insights.

**Start simple** - Begin with basic aggregations or windows, then add complexity as needed.

**Reuse patterns** - Once you've built an analysis using one of these patterns, you can often adapt it to similar problems with minimal changes.

## Summary

The three main pattern categories are:
1. Aggregation-based (GROUP BY)
2. Cumulation-based (FULL OUTER JOIN)
3. Window-based (window functions)

Mastering these patterns will help you solve most analytical problems efficiently and consistently.