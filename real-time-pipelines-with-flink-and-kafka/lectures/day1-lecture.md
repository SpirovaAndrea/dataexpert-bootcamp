# Real-time Pipelines with Flink and Kafka - Day 2: Exploring Data Collection and Processing

## Streaming Needs Many Pieces to Work

A complete streaming pipeline involves multiple components working together.

**Example flow: User action to database**

1. User performs an action in the app
2. HTTP interceptor captures the event
3. Kafka producer sends event to Kafka topic
4. Flink processes the event
5. Data written to sink (e.g., Postgres)

Each piece needs to be configured and monitored for the pipeline to work reliably.

## The Big Competing Architectures

There are two main approaches to building data architectures that need both speed and correctness:

### Lambda Architecture

**Philosophy:** Optimize for both latency and correctness by running two parallel pipelines.

**How it works:**
- Batch layer: Processes all historical data, ensures correctness
- Speed layer: Processes recent data for low latency
- Serving layer: Merges results from both

**Pros:**
- Optimizes for both latency and correctness
- Easier to insert data quality checks on the batch side
- Batch layer can fix issues in the speed layer

**Cons:**
- Eats a bit of pain in complexity
- Double the code base (maintain same logic in batch and streaming)
- More infrastructure to manage

### Kappa Architecture

**Philosophy:** You don't need both batch and streaming. Just use streaming for everything.

**How it works:**
- Single streaming pipeline handles all data
- Reprocess historical data by replaying the stream if needed

**Pros:**
- Least complex (one pipeline, one codebase)
- Great latency wins
- Simpler to maintain

**Cons:**
- Can be painful when you need to read a lot of history
- You need to read things sequentially from the stream
- Harder to do data quality checks

**Modern developments:**
Delta Lake, Iceberg, and Hudi are making Kappa architecture much more viable. These table formats let you efficiently read historical data from streaming pipelines, reducing the main weakness of Kappa.

## Flink UDFs (User Defined Functions)

UDFs let you write custom logic in Flink.

**Performance note:**
UDFs generally speaking won't perform as well as built-in functions.

**When to use UDFs:**
- Custom transformations that aren't available built-in
- Integrations with external systems
- Business logic that's too complex for SQL

**Python UDFs:**
Python UDFs are going to be even less performant since Flink isn't native Python. The data has to be serialized to Python, processed, and serialized back to Java.

Use Python UDFs only when necessary. Prefer built-in functions or Java/Scala UDFs when performance matters.

## Flink Windows

Windows group events together for processing. There are two main categories:

### Data-Driven Windows (Count-Based)

**How they work:**
Window stays open until N number of events occur. You need to specify the count.

**Use cases:**
Useful for funnels that have a predictable number of events. For example, a checkout funnel with 5 steps.

**Timeout feature:**
You can specify a timeout since not everybody will finish the funnel. If the window doesn't fill up after a certain time, it closes anyway.

### Time-Driven Windows

These are based on time rather than event count. There are three types:

#### 1. Tumbling Windows

**Characteristics:**
- Fixed size
- No overlap
- Similar to hourly batch data

**Use case:**
Great for chunking data into regular time periods. For example, aggregating events every hour.

**Example:**
```
[00:00 - 01:00] [01:00 - 02:00] [02:00 - 03:00]
```

#### 2. Sliding Windows

**Characteristics:**
- Has overlap between windows
- Captures more windows
- Window "slides" forward by a smaller increment than the window size

**Use cases:**
- Good for finding "peak-use" windows
- Good at handling "across midnight" exceptions that cause problems in batch

**Example:**
```
[00:00 - 01:00]
  [00:15 - 01:15]
    [00:30 - 01:30]
```

A 1-hour window that slides every 15 minutes.

#### 3. Session Windows

**Characteristics:**
- Variable length
- Based on activity
- User-specific, not a fixed window
- Lasts until there's a gap in activity

**Use case:**
Used to determine "normal" user activity. The window closes after a period of inactivity.

**Example:**
A user's session might last 10 minutes if they're active, but if they don't do anything for 5 minutes, the session window closes.

## Watermarking vs Allowed Lateness

These are two different mechanisms for handling late data:

### Watermarks

**Purpose:**
Defines when the computational window will execute.

**What they do:**
- Help define ordering of events that arrive out of order
- Handle idleness (when no events are coming)
- Signal "we've seen all events up to this time"

**How they work:**
The watermark is a timestamp that moves forward as events arrive. When the watermark passes the window end time, the window executes.

### Allowed Lateness

**Purpose:**
Allows for reprocessing of events that fall within the late window.

**Default:**
Usually set to 0, meaning no late data is accepted after the window closes.

**What it does:**
If you set allowed lateness to 5 minutes, events that arrive up to 5 minutes after the window closes will still be processed.

**Caution:**
Will generate updates or merge with other records. This means downstream systems need to handle updates, not just inserts.

**Trade-off:**
- Allowed lateness = 0: Simpler, but you lose late data
- Allowed lateness > 0: More complete data, but more complex to handle updates

## Summary

**Architectures:**
- Lambda: Two pipelines (batch + streaming) for correctness and speed
- Kappa: One streaming pipeline, simpler but harder to read history

**Flink UDFs:**
- Use built-in functions when possible
- Python UDFs are slowest

**Windows:**
- Data-driven: Count-based, good for funnels
- Tumbling: Fixed, no overlap, like batch
- Sliding: Overlapping, good for peak detection
- Session: Variable, based on activity gaps

**Handling Late Data:**
- Watermarks: When to close windows
- Allowed Lateness: Whether to accept late data and reprocess