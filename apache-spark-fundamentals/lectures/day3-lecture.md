# Day 3: Unit Testing Spark Jobs – Importance, Challenges, and Leadership Perspectives

## Catching Quality Bugs in Data Engineering

### Where Bugs Can Be Detected
- **Best case:** During development (ideal scenario).  
- **Acceptable:** In production, but not visible in production tables.  
- **Worst case:** In production tables – very serious and costly.  

### How to Catch Bugs
#### In Development
- **Unit tests** and **integration tests**  
- **Linters** to enforce coding and style standards  

#### In Production
- **Write-Audit-Publish (WAP) pattern** to catch issues early  
- Worst-case scenario: A **data analyst finds bugs in production**  

---

## Comparison: Software Engineering vs Data Engineering

- **Quality Standards:** Software engineering is more mature.  
- **Risks:**  
  - Server downtime impacts business more than pipeline delays.  
  - Frontend failures can halt operations.  
- **Maturation:** Practices like **TDD** and **BDD** are well established in software engineering but newer in data engineering.  
- **Talent Diversity:** Data engineers often come from varied backgrounds compared to software engineers.  

---

## Increasing Risk in Data Engineering

- **Data delays** impact machine learning pipelines.  
- **Data quality bugs** affect experimentation and decision-making.  
- As trust in data grows, the **consequences of errors increase**.  

---

## Common Organizational Pitfalls

- Tradeoff between **business velocity** and **sustainability**.  
- Avoid cutting corners to move faster; focus on **robust, maintainable pipelines**.  
- Remember: data engineers **build infrastructure**, not just answer ad-hoc queries.  

---

## Building Data Engineering Capabilities

- Focus on **rows and highways**, not “dirt roads.”  
- Over time, capability standards will include:
  - Latency  
  - Quality  
  - Completeness  
  - Ease-of-access  
  - Usability  

---

## Software Engineering Mindset for Data Engineers

- Code is **90% read by humans**, 10% executed by machines.  
- **Silent failures** are your enemy; **loud failures** provide learning opportunities.  
- Apply **DRY** and **YAGNI** principles.  
- Design documents are valuable.  
- Care about **efficiency**, including **data structures** and **algorithms**.  

---

## Takeaways

- Data engineers should **adopt software engineering best practices** to improve reliability and maintainability.  
- Strong fundamentals in coding, testing, and design **increase trust in data pipelines** and reduce production risk.  
