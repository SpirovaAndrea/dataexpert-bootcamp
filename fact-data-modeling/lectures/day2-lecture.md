# Day 2: Dimensions and Facts

## Fact vs Dimension

- Questions to consider:
  - Did a user log in today?
  - Did they show up for a minute or were they engaged?
- If a dimension is based on an event, is it a dimension or an aggregation of facts? Answer: it can be both.
- Facts can be aggregated and turned into dimensions.
- Using `CASE WHEN` to bucketize aggregated facts is very useful to reduce cardinality.
- Think about `dim_is_active` vs the state `dim_is_activated`.
- Dimensions and facts can get blurry; consider the **cardinality** of the dimension.

---

## Bucketizing

- **Definition:** Bucketizing (also called binning) is a data processing technique where you group continuous values or a large range of discrete values into a smaller number of categories or "buckets."
- **Purpose:**
  - Simplification: Convert granular data into manageable categories
  - Analysis: Make patterns more visible
  - Performance: Reduce computational complexity
  - Visualization: Create cleaner charts and reports
  - Business Logic: Align data with business rules

- Practical tip: 5 to 10 buckets is often a good value when slicing data.

---

## Properties of Facts vs Dimensions

### Dimensions
- Attributes you group by
- Can have high or low cardinality
- Usually come from snapshots of state
- Can be difficult or expensive to change
  - Example: Number of friends on Facebook
  - Example: Airbnb availability rules

### Facts
- Generated when an event occurs (logs, transactions)
- Aggregated for analytics using `SUM`, `AVG`, `COUNT`
- Can be aggregated to create new dimensions
- Can model state changes of a dimension as an event or fact

---

## Examples

- Airbnb pricing:
  - Is the price of a night a fact or a dimension?
    - It can be summed or averaged → fact
    - The host setting the price → event/fact
    - Changes that affect the price → can be a dimension
- Boolean/existence-based facts/dimensions:
  - `dim_has_ever_booked`
  - `dim_ever_labeled_fake`
- Categorical facts/dimensions:
  - Derived from fact data using `CASE WHEN` logic and bucketizing
  - Example: Airbnb Superhost status

---

## Dimension Considerations

- Dimensions can have a strong **anchoring effect** on a product.
- Changing dimension definitions is difficult and expensive.
  - Example: Redefining Airbnb availability for a night in a trip.

---

## Using Dimensions vs Facts for Analysis

- Which metric is better: `dim_is_activated` or `dim_is_active` logs?
- Understand the difference between **signups** and **growth** metrics.

---

## Efficient Historical Data Storage

- Example: Facebook’s approach for daily/monthly active users
  - Naive approach: Last 30 days of data → billions of rows
  - Solution: **Cumulative table design** 
    - Process new days incrementally
    - Use integers as highly compressible data types
