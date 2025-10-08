# Real-time Pipelines with Flink and Kafka - Day 1: Mastering Streaming and Real-time Pipelines

## What is a Streaming Pipeline?

A streaming pipeline processes data in a low latency way. Instead of waiting to collect batches of data, it processes events as they arrive.

## Streaming vs Near Real-time vs Real-time

These terms are often used interchangeably, but they have different meanings:

**Streaming (or Continuous)**
- Example: Flink
- Processes data continuously as it arrives
- True event-by-event processing

**Near Real-time**
- Example: Spark Structured Streaming
- Processes data in very small batches (micro-batches)
- Small delay between events and processing

**Important note:** Real-time and streaming are often synonyms but not always.

## What Does Real-time Mean to Stakeholders?

When stakeholders ask for "real-time" data, it rarely means streaming. Often they just want fresher data than what batch provides.

Understanding what they actually need is critical before building a streaming pipeline.

## Should You Use Streaming?

Before jumping into streaming, consider these factors:

**Skills on the team**
- Does your team have streaming expertise?
- Are they comfortable debugging streaming systems?

**What is the incremental benefit?**
- How much value does reduced latency actually provide?
- Is the added complexity worth it?

**Homogeneity of your pipelines**
- Mixing batch and streaming adds operational complexity
- Consider whether standardizing on one approach is better

**The tradeoff between daily batch, hourly batch, and streaming**
- Daily batch is simplest
- Hourly batch (micro-batch) is often a good middle ground
- Streaming is most complex

**How should data quality be inserted?**
- Quality checks are harder in streaming
- Need to balance speed with validation

## Streaming-Only Use Cases

These use cases require streaming because low latency makes or breaks them:

**Key principle:** Low latency is critical to the use case

**Examples:**
- Detecting fraud in real-time
- High frequency trading
- Real-time monitoring and alerting

If processing happens even minutes later, the value is lost.

## Gray Area Use Cases

These might work with micro-batch or streaming:

**Data is served to customers**
- Customers see the data directly
- Fresher data improves experience but isn't critical

**Reducing the latency of upstream master data**
- Other pipelines depend on this data
- Faster updates help downstream systems

For these cases, evaluate whether micro-batch (hourly) would be sufficient before investing in full streaming.

## No-Go Streaming Use Cases

Use batch for these instead:

**Key question:** What is the incremental benefit of reduced latency?

**Example of a bad reason:**
"Analysts complaining that data isn't up-to-date"
- This usually just means they want daily data instead of weekly
- Doesn't require streaming, just more frequent batch

If the answer to the incremental benefit question isn't compelling, stick with batch.

## How Are Streaming Pipelines Different from Batch Pipelines?

### The Streaming to Batch Continuum

Real-time is a myth. All pipelines exist on a continuum and can be broken into three categories:

1. **Daily batch** - Processes once per day
2. **Hourly/Micro-batch** - Processes every hour or in small time windows
3. **Continuous processing** - Processes events as they arrive

## The Structure of a Streaming Pipeline

Every streaming pipeline has three main components:

### 1. The Sources

Where data comes from:
- **Kafka** - Most common streaming source
- **RabbitMQ** - Message queue system
- **Enriched dimensional sources** - Reference data for lookups

### 2. The Compute Engine

The system that processes the streaming data:
- Flink
- Spark Structured Streaming
- Others

### 3. The Destination (Sink)

Where processed data goes:

**Common sinks:**
- **Iceberg** - Data lake table format
- **Another Kafka topic** - For downstream processing
- **Postgres** - Relational database
- Other databases or storage systems

## Streaming Challenges

Streaming systems face unique challenges that batch doesn't have to deal with:

### Challenge 1: Out of Order Events

Events don't always arrive in the order they were created. Network delays, multiple sources, and system issues can cause events to arrive out of sequence.

**How Flink handles this:** Watermarking

Watermarks are timestamps that signal "all events before this time have arrived." This lets Flink know when it's safe to compute results for a time window.

### Challenge 2: Late Arriving Data

Sometimes events arrive very late, well after their event time.

**The question:** How late is too late?

You need to decide:
- How long do you wait for late data?
- What do you do with data that arrives too late?

**How batch handles this:** Mostly by waiting. Batch jobs typically run hours after the data period ends, giving time for late data to arrive. Although batch also has issues around midnight UTC cutoffs.

### Challenge 3: Recovering from Failures

Streaming systems need to handle failures without losing data or creating duplicates.

**How Flink manages this:**

**Offsets** - Track position in the source stream (like Kafka offset)
**Checkpoints** - Periodic snapshots of the pipeline state
**Savepoints** - Manual snapshots you can use to restart from a specific point

These mechanisms ensure that if your pipeline crashes, it can resume from where it left off without reprocessing or losing data.

## Summary

Streaming pipelines offer low latency but add complexity. Use them only when:
- Low latency is critical to the use case
- Your team has the skills to manage them
- The incremental benefit justifies the cost

For many use cases, hourly micro-batch is a better middle ground between daily batch and full streaming.