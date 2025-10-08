# Data Pipeline Maintenance Document

## Team Structure
**Data Engineering Team (4 members):**
- Engineer A
- Engineer B
- Engineer C
- Engineer D

---

## Pipeline Ownership Matrix

| Pipeline | Business Area | Primary Owner | Secondary Owner |
|----------|---------------|---------------|-----------------|
| Unit-level Profit Pipeline | Profit (Experiments) | Engineer A | Engineer B |
| Aggregate Profit Pipeline | Profit (Investors) | Engineer A | Engineer B |
| Aggregate Growth Pipeline | Growth (Investors) | Engineer B | Engineer C |
| Daily Growth Pipeline | Growth (Experiments) | Engineer B | Engineer C |
| Aggregate Engagement Pipeline | Engagement (Investors) | Engineer C | Engineer D |

**Ownership Rationale:**
- Engineers A & B share profit pipelines due to business-critical nature
- Engineers B & C share growth pipelines to balance workload
- Engineers C & D handle engagement, with D as backup for critical systems
- Each engineer is primary for 1-2 pipelines and secondary for 1-2 others

---

## On-Call Rotation Schedule

### Regular Weekly Rotation (4-week cycle)

| Week | Primary On-Call | Secondary On-Call |
|------|----------------|-------------------|
| Week 1 | Engineer A | Engineer B |
| Week 2 | Engineer B | Engineer C |
| Week 3 | Engineer C | Engineer D |
| Week 4 | Engineer D | Engineer A |

**Schedule Details:**
- On-call shift: Monday 9:00 AM - Following Monday 9:00 AM
- Handoff meeting: Every Monday at 9:00 AM
- Response time SLA: 30 minutes for P0 issues, 2 hours for P1 issues
- Weekend coverage: Primary on-call handles all issues; secondary available for escalation

### Holiday Coverage

**Major Holidays (US-based team assumed):**

| Holiday Period | Primary On-Call | Secondary On-Call | Notes |
|---------------|----------------|-------------------|-------|
| New Year's Week | Engineer B | Engineer C | Engineer A gets break after Q4 |
| Memorial Day Weekend | Engineer D | Engineer A | 3-day weekend |
| Independence Day Week | Engineer C | Engineer D | Summer holiday |
| Labor Day Weekend | Engineer A | Engineer B | 3-day weekend |
| Thanksgiving Week | Engineer D | Engineer C | High alert - investor reporting |
| Christmas/New Year (Dec 23 - Jan 2) | Rotating daily | All available | Critical period - 2x pay |

**Holiday Rotation Rules:**
1. No engineer covers more than 2 major holidays per year
2. Holiday weeks count as 1.5x regular weeks toward rotation credit
3. Christmas/New Year period rotates daily with premium compensation
4. Engineers can trade holidays with team approval

---

## Pipeline Runbooks (Investor-Facing Only)

---

## 1. Aggregate Profit Pipeline Runbook

**Primary Owner:** Engineer A  
**Secondary Owner:** Engineer B

### Pipeline Overview
Aggregates unit-level profit data for monthly and quarterly investor reporting. Critical for board meetings and SEC filings.

### SLAs
- **Data Landing Time:** 6 hours after UTC midnight
- **Reporting Deadline:** Monthly close + 3 business days
- **Downstream Consumers:** 
  - Executive Dashboard
  - Investor Relations Portal
  - Financial Reporting System

### Common Issues

#### Upstream Datasets

**Transaction Database**
- **Issue:** Refund transactions occasionally missing transaction_type flag
- **Impact:** Overstates profit by 2-5%
- **Detection:** Automated data quality check flags when refund ratio < 1%
- **Symptoms:** Alert email "Refund anomaly detected in profit calculation"

**Payment Processor Exports**
- **Issue:** Export files delayed during payment processor maintenance windows
- **Impact:** Pipeline cannot complete on time
- **Detection:** File not present in S3 bucket by 2 hours after UTC midnight
- **Symptoms:** Airflow task timeout, missing input file error

**Revenue Recognition Table**
- **Issue:** Deferred revenue calculations may have stale data from finance team
- **Impact:** Revenue timing mismatches, understates current period profit
- **Detection:** Last_updated timestamp older than 48 hours
- **Symptoms:** Finance team queries show different numbers than pipeline output

#### Data Quality Issues

**Currency Conversion Rates**
- **Issue:** Exchange rate API occasionally returns cached/stale rates
- **Impact:** International profit miscalculated by up to 3%
- **Detection:** Rate changes less than 0.01% day-over-day for volatile currencies
- **Symptoms:** Alert "Currency rate staleness detected"

**Duplicate Transactions**
- **Issue:** Retry logic in payment system creates duplicate transaction records
- **Impact:** Profit overstated
- **Detection:** Same transaction_id with different timestamps within 5 minutes
- **Symptoms:** Row count spike alert, deduplication step shows high duplicate rate

#### Pipeline Logic Issues

**Timezone Handling**
- **Issue:** Daylight saving time transitions cause transaction misalignment
- **Impact:** Single day shows 23 or 25 hours of data
- **Detection:** Happens twice per year in March and November
- **Symptoms:** Daily profit total 4% higher or lower than expected

### Downstream Impact
- **Executive Dashboard:** Shows incorrect profit margins
- **Investor Relations:** Wrong numbers presented to shareholders
- **Financial Reporting:** Could trigger SEC compliance issues

---

## 2. Aggregate Growth Pipeline Runbook

**Primary Owner:** Engineer B  
**Secondary Owner:** Engineer C

### Pipeline Overview
Calculates key growth metrics (MAU, DAU, new user acquisition, retention rates) for investor reporting and board presentations.

### SLAs
- **Data Landing Time:** 4 hours after UTC midnight
- **Reporting Deadline:** Weekly by Tuesday 10:00 AM PT, Monthly by 5th business day
- **Downstream Consumers:**
  - Investor Dashboards
  - Board Presentation Decks
  - Public Metrics Reporting

### Common Issues

#### Upstream Datasets

**User Events Stream**
- **Issue:** Event stream can have 2-6 hour delays during traffic spikes
- **Impact:** Incomplete day's data, understates active users
- **Detection:** Event count 15%+ below 7-day average
- **Symptoms:** Alert "User events volume anomaly"

**User Authentication Logs**
- **Issue:** Bot traffic not properly filtered in source logs
- **Impact:** Inflates MAU/DAU by 5-15%
- **Detection:** Automated bot detection flags user_agent patterns
- **Symptoms:** Sudden spike in users from specific regions/devices

**Account Database Snapshots**
- **Issue:** Snapshot export occasionally corrupted during high load
- **Impact:** User count and retention calculations incorrect
- **Detection:** Row count differs by >5% from previous day without explanation
- **Symptoms:** Pipeline validation step fails, "Unexpected user count change"

#### Data Quality Issues

**User ID Mapping**
- **Issue:** Anonymous users transitioning to authenticated creates ID conflicts
- **Impact:** Undercounts unique users by 3-8%
- **Detection:** High ratio of orphaned anonymous IDs
- **Symptoms:** User retention rates appear artificially low

**Geographic Data Anomalies**
- **Issue:** IP geolocation service occasionally returns NULL or incorrect countries
- **Impact:** Regional growth metrics incorrect
- **Detection:** Country code NULL for >2% of events
- **Symptoms:** Alert "Geographic attribution failure rate high"

**Time Window Edge Cases**
- **Issue:** Users active near UTC midnight counted in wrong day
- **Impact:** Daily active user counts slightly off
- **Detection:** Manual review shows discontinuities at day boundaries
- **Symptoms:** DAU calculations don't sum to MAU properly

#### Calculation Issues

**Retention Cohort Logic**
- **Issue:** Leap years and month-end dates cause cohort misalignment
- **Impact:** Retention rates appear to drop artificially
- **Detection:** Happens on Feb 29, and last day of months with 31 days
- **Symptoms:** Retention metrics show unexpected dips on specific dates

### Downstream Impact
- **Investor Dashboards:** Shows incorrect growth trajectory
- **Board Presentations:** Wrong metrics presented to board of directors
- **Public Reporting:** Could violate public company reporting requirements

---

## 3. Aggregate Engagement Pipeline Runbook

**Primary Owner:** Engineer C  
**Secondary Owner:** Engineer D

### Pipeline Overview
Aggregates user engagement metrics (sessions per user, time on platform, feature usage, content interactions) for quarterly investor presentations.

### SLAs
- **Data Landing Time:** 5 hours after UTC midnight
- **Reporting Deadline:** Quarterly close + 5 business days
- **Downstream Consumers:**
  - Investor Quarterly Reports
  - Product Analytics Dashboard
  - Executive Presentations

### Common Issues

#### Upstream Datasets

**Clickstream Events**
- **Issue:** Event tracking SDK occasionally fails to send batched events
- **Impact:** Engagement metrics understated by 5-10%
- **Detection:** Event volume drops for specific SDK versions
- **Symptoms:** Alert "Clickstream event drop detected for SDK version X"

**Session Management Service**
- **Issue:** Session timeout logic inconsistent across mobile/web platforms
- **Impact:** Session counts inflated on mobile, deflated on web
- **Detection:** Session duration distribution shows bimodal pattern by platform
- **Symptoms:** Average session time diverges significantly between platforms

**Content Database**
- **Issue:** Content metadata occasionally missing or corrupted during CMS updates
- **Impact:** Cannot attribute engagement to content types
- **Detection:** content_type field NULL for >3% of events
- **Symptoms:** "Content attribution failure" warning in logs

#### Data Quality Issues

**Bot and Automated Traffic**
- **Issue:** Monitoring scripts and health checks counted as engagement
- **Impact:** Inflates engagement by 2-5%
- **Detection:** User agents matching known bot patterns
- **Symptoms:** Engagement spikes at exact 5-minute intervals

**Mobile App Background Activity**
- **Issue:** Apps sending heartbeat events while in background
- **Impact:** Time on platform overstated
- **Detection:** Events with screen_state = "background" not filtered
- **Symptoms:** Average session time unusually high for mobile users

**Feature Flag Rollouts**
- **Issue:** New features with tracking enabled mid-period create data inconsistency
- **Impact:** Engagement appears to increase artificially
- **Detection:** New event types appear mid-period
- **Symptoms:** Engagement metrics jump without corresponding user behavior change

#### Aggregation Issues

**Time Zone Normalization**
- **Issue:** User local time vs server time creates double-counting at day boundaries
- **Impact:** Engagement appears 3-5% higher than actual
- **Detection:** Sessions spanning UTC midnight counted twice
- **Symptoms:** Daily engagement sum exceeds monthly totals

**Outlier Users**
- **Issue:** Power users or test accounts create extreme outliers
- **Impact:** Average engagement inflated by 10-20%
- **Detection:** Single users with >1000 events per day
- **Symptoms:** Median vs mean engagement shows large gap

### Downstream Impact
- **Investor Reports:** Incorrect engagement trends shown to investors
- **Product Analytics:** Wrong signals for product team decisions
- **Executive Presentations:** Could misrepresent platform health to stakeholders

---

## Escalation Procedures

### Severity Levels

**P0 - Critical (Investor-Facing Pipeline Down)**
- Response Time: 15 minutes
- Escalation: Immediately notify primary + secondary owner, engineering manager
- Examples: Pipeline failed on monthly close day, data completely missing

**P1 - High (Data Quality Issue in Investor Pipeline)**
- Response Time: 30 minutes
- Escalation: Notify primary owner, secondary available for backup
- Examples: Metrics off by >5%, SLA breach imminent

**P2 - Medium (Non-Investor Pipeline Issues)**
- Response Time: 2 hours
- Escalation: Primary owner handles during business hours
- Examples: Experimental pipeline delays, minor data quality issues

**P3 - Low (Monitoring or Minor Issues)**
- Response Time: Next business day
- Escalation: Create ticket for primary owner
- Examples: Warning alerts, performance degradation <10%

### Contact Information

| Role | Primary Contact | Secondary Contact |
|------|----------------|-------------------|
| Engineering Manager | Slack @eng-manager | manager@company.com |
| Data Team Lead | Slack @data-lead | datalead@company.com |
| Finance Team (Profit Issues) | Slack #finance-data | finance-data@company.com |
| Product Team (Engagement Issues) | Slack #product-analytics | product@company.com |

### After-Hours Escalation
1. Page on-call engineer via PagerDuty
2. If no response in 15 minutes, page secondary on-call
3. If no response in 30 minutes, page engineering manager
4. For P0 issues affecting investor reporting, notify CFO office

---

## Maintenance Windows

**Planned Maintenance:**
- Every Sunday 2:00 AM - 6:00 AM UTC
- Quarterly infrastructure upgrades (announced 2 weeks in advance)
- No maintenance during month-end close (last 3 days of month)

**Communication:**
- Post in #data-engineering Slack channel 48 hours before maintenance
- Email stakeholders 24 hours before maintenance
- Update status page at status.company.com

---

## Revision History

| Date | Author | Changes |
|------|--------|---------|
| 2025-09-30 | Data Engineering Team | Initial document creation |

---

## Notes
- Review and update this document quarterly
- All pipeline owners must review their sections monthly
- Conduct runbook drill exercises before each quarterly close