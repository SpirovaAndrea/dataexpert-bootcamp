# Data Visualization and Impact: Insights and Best Practices — Day 2 Lecture

## 1. Performant Dashboards: Best Practices

### **Key Principles**
- **Pre-aggregate data** — use grouping sets to prepare data efficiently.  
- **Avoid joins on the fly** — reduce expensive real-time computation.  
- At the dashboard layer, remember: this is the **final stage**.  
  - There’s **no downstream system** — the human is the consumer.  
  - Prioritize **clarity and speed** over flexibility.  

**Recommended Storage:**  
Use **low-latency solutions** like **Apache Druid** for fast query responses.

---

## 2. Building Dashboards That Make Sense

### **Identify Your Audience**
- **Executives:** prefer simple, high-level visuals.  
- **Analysts:** need more complex, data-dense views for exploration.

---

## 3. Asking the Right Questions

| **Question Type** | **Purpose / Example** |
|--------------------|------------------------|
| **Top-line** | “How many users?”, “How much revenue?”, “How much time do users spend?” |
| **Trend** | “How does this year compare to last year?”, “What’s the month-over-month growth?” |
| **Composition** | “What % of users are Android vs iOS?”, “What % come from each region?” |

---

## 4. Understanding Which Numbers Matter

### **1. Total Aggregates**
- Represent company-wide performance (e.g., total users, total revenue).  
- Often used for **Wall Street reporting** or **marketing**.

### **2. Time-Based Aggregates**
- Reveal **trends and growth patterns** earlier than totals.

### **3. Time & Entity-Based Aggregates**
- Used for **A/B testing** or segmented performance metrics.

### **4. Derivative Metrics**
- Examples: **WoW**, **MoM**, **YoY** comparisons.  
- Show **growth direction and velocity**.  
- Example: Airbnb used “Year-over-2-Year” growth during COVID-19 disruptions.

### **5. Dimensional Mix Metrics**
- Track shifts in user demographics or platforms (e.g., % Android vs % iPhone).  
- Totals stay constant, but proportions shift — known as **mix shift**.

### **6. Retention / Survivorship Metrics**
- Measure how many users remain after N days (e.g., 30-day retention).  
- Reveal **loyalty** and **product stickiness**.
