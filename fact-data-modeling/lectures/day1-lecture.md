# Fact Data Modeling - Day 1

## What is Fact Data?

Fact data is every event that a user can do. If you have 100 users that can have 1,000,000 events each, that's a lot of fact data.

When you aggregate a fact, it can behave like a dimension and things can get blurry. What's a fact and what's a dimension?

## Date List Data Structure

This is a structure to model user activity. You can look at the last 30 days of activity as one integer, so it compresses data a lot. It allows Facebook to compute monthly active users efficiently.

## Reduced Facts

This is a way to minimize the volume of all of your fact data by preserving the most important bits. By building reduced facts, you can supercharge your analytical patterns.

## What is a Fact?

A fact is something that happened or occurred. An example of an action would be a user logging into an app or sending someone $30 on Venmo.

Running a mile on your Fitbit is more of an aggregation. In a mile you can break down each individual step as the lowest granularity. You can't break down a step into a smaller component. A fact is something that really can't be broken down into a smaller piece. It's atomic.

Facts don't change. You can't go back and change what happened.

Dimensions have a slowly changing property to them. You don't have to worry about that with facts, which makes them easier to model in some aspects.

Facts are more challenging because there's a lot more of them. If you have 10,000 steps a day, that's a lot more data than you as a person. Instead of one row of data for you as a person, you have 10,000 rows of data for every step you took.

How big the fact data is going to balloon is based on how many actions are taken per dimension. For example, if you have 25 to 30 notifications a day from 2 billion users, that balloons to 50 billion notifications. That's a lot.

## Context is Everything

You need context for an effective analysis. For example, say we sent a notification. That fact in isolation is worthless and doesn't provide anything. But say we sent a notification, then 20 minutes later you clicked on it, and 5 minutes later you bought something. We have that funnel analysis. With those 3 facts together you can have a $50 million business.

That's all Facebook and Google are - conversion funnels. You saw a result, you clicked on it, and you took an action.

They tried 40 different shades of blue for the links on their website. One of them caused people to engage more than the others and that made them $10 million.

When working with fact data, something to think about is: what other fact data do we need to make this fact data more valuable?

## Duplicates in Fact Data

Duplicates are way more common in fact data. They can be caused by many things.

For example, the software engineers push out a bug in the logger so every time someone clicks, it logs two records. That's more of a data quality error.

Another example: in notifications, you click on it in hour 1 and again in hour 7. Both are genuine actions we want to log, but not as two separate actions in our metrics. It messes up the click ratios. You have to dedupe because your metrics will not be what you want them to be.

## Normalized vs Denormalized Facts

There are normalized facts and denormalized facts, and both are very important.

If you have a record like "Zach logged in at this time," it wouldn't be Zach but User17. But for your analysis, you wouldn't like to do a join. So instead you say "Zach, 20 years old, Male, who lives in California logged in at this time." You can bring in some of the other dimensions from the other actors or objects in the fact data. You can just make a GROUP BY and not a JOIN, which can make things faster. It can also make duplicates.

The smaller the scale, the better normalization is going to be.

When you have normalized facts, you remove all the duplicates and increase the data integrity. At smaller scale, normalization is a big win.

## Raw Logs vs Fact Data

Raw logs and fact data are not the same, but they are linked, almost married. If you don't have logging right, it's very hard to get fact data right.

The big difference is raw logs are usually owned by people who don't have strong data skills, like software engineers. You can work with the software engineers to get the data logged in the correct format. That's one of the biggest problems - you usually have ugly schemas that are from the online system. They can contain duplicates and other quality errors. Raw logs don't have any quality guarantees.

Fact data has longer retention, nice column names, and quality guarantees. The trust in the fact data should be higher than the trust in the raw logs. You should be able to convert those raw logs into trusted fact data.

## The Five W's and How

**Who** - These fields are usually IDs. User IDs, car IDs. Tesla has a car and there's the ID of you as a user, the ID of the car, the ID of the operating system.

**Where** - Can be location like a country. Where in the app could be the home page, profile page, etc. Can be modeled with IDs as well, but many times it's not. It's modeled just like /where.

**How and Where** are very similar in the virtual world. For example, if someone used an iPhone to make a click, is the iPhone the Where or How? It's a How, and the Where is where on the page or in the app they clicked.

The Tesla car is modeled as a How more than a Who, and it's tricky because there's ownership there - this person owns that car. These two are closely linked.

**What** - In notifications there's a funnel of events: generated, sent, delivered, clicked on, converted into an action downstream (like, comment, purchase), etc.

The What events we should think of as atomic. Someone made a transaction, someone threw a party. There's also events that are more high level. I threw Burning Man as a party - that is an event but that is more of a group of events. It's a week-long thing.

I registered with the Bureau of Land Management to throw this party - that is atomic.

The higher level events are like aggregations - all of those events that are happening at that time. It's like a dimension - all of these events are tied to this one thing. It's like an aggregated view of one set of facts.

**When** - Almost always modeled as a timestamp or a date. I clicked on this notification at this moment in time.

You want to make sure that all of your devices are logging the same time zone. When there's client-side logging, it happens most of the time in the time zone the client's in, which is bad when it gets pushed to the server. You want to make sure in the client app that they are logging things in the same time zone so when it gets pushed to the server it's the same time zone.

Client-side logging is higher fidelity than server-side because you get all the interactions a user makes, not just the ones that cause a web request to happen.

## Fact Dataset Quality Guarantees

Fact datasets should have quality guarantees:
- No duplicates
- The event field (the What) and When field should always be NOT NULL. If they are NULL, you can't analyze that data. The Who field also should be NOT NULL.

Fact data should be smaller than raw logs.

Fact data should parse out hard-to-understand columns.

Fact data should always be just strings, integers, decimals, and enumerations. It shouldn't have much of those complex data types. There could be some like array of string. For example, an array of string could be "this notification was part of these experiment groups," so you can easily slice and dice the notification conversion rates based on the experimental groups they were in.

You shouldn't have blobs of JSON.

## When to Bring Dimensions In

When should we bring dimensions in instead of just the ID?

**Netflix network logs pipeline example:**

Netflix has 2 petabytes of brand new data every single day. The source dataset was every network request that Netflix receives. They wanted to see how the microservices were talking to each other.

Netflix is very famous for pioneering the microservice architecture, which is really great for making your development faster. For security, they're a mess. Instead of having one app to secure, you have 1,000 apps. There are a lot of ways that things can get hacked.

The question was: What are all of the apps and how do they talk to each other? If one app talks with another app and one gets hacked, we need to know. We figured this out by looking at all the network traffic and joining it with a small database of IP address data for Netflix's microservice architecture that we came up with. It worked because that database was small enough (5GB or 6GB) to do a broadcast join.

But instead of the join, what we needed to do was get all of the apps to just log their app. Every time that a network request happened, we needed to log which app it was receiving. Instead of doing the join, the app would be in the network request itself.

A lot of times the impact you have as a data engineer is not writing a pipeline and not optimizing a pipeline. It's going upstream and solving the problem at the source.

Denormalization wins in this case. It's a solution for large-scale problems, not the cause.

## How Logging Fits Into Fact Data

Logging should give you all the columns that you need, except for maybe some of the dimensional columns. Those probably shouldn't even be in the data table to begin with. You should only have the IDs and people should join on those IDs to get the dimensions that they need.

The online system engineers are going to know a lot more about the event generation and when those events are actually being created in the app. Data engineers don't have that much context here.

Don't log everything, only what you really need. A lot of times these raw logs can be very expensive and cost a lot of money on the cloud. Don't log stuff "just in case." It's an antipattern and against the efficiency ethos of data engineering.

Data engineering is about giving you all the answers to all the questions in the most efficient way possible.

## Conformance

When you are logging your data, there should be a contract or schema or shared vision for things. It can be tricky. For example, Netflix uses Ruby and Scala and you can't connect them both directly. There should be some kind of a middle layer between the two and they should share the schema.

Thrift schema is a specification that is language agnostic. It's a way to describe schema and describe data and functions as well in a way that is shared. The Ruby and the Scala code will both reference the schema code.

The Ruby team can't push their code until they inform that they are adding a column so that the Scala team can update their code.

## Working with High Volume Fact Data

Sometimes the solution is to not work with all of it, but to filter it down and not work with all of the data.

**Sampling** - Doesn't work for all cases. In security you can't sample, or for very low probability events you need to capture. It works for metrics and directionality things.

Sampling works because of the law of large numbers. As you have more examples and rows of data, you get a diminishing return of what that distribution looks like.

**Bucketing** - Join within the buckets. It's faster.

## Retention

How long should you hold onto fact data? High volumes make fact data much more costly to hold onto for a long time.

## Deduplication

Deduplication of fact data is challenging.

You can have general actual duplicates of data. You have to think about the time frame. Facebook sent you a notification and you clicked on it today, but you also click on it in a year from now. Do we care about that duplicate? Probably not. There needs to be some time frame where you care about duplicates where they matter and don't matter.

To reduce the latency to the master data, all the other pipelines could start after 9 hours because they were waiting on this data. What are the options for reducing the latency of this deduping? Two big ones are streaming (even lower basis) and micro-batch (hourly basis).

Streaming allows you to capture the most duplicates in a very efficient manner. You can capture the duplicates at whatever window you want. For example, we saw this notification and we're going to hold onto this ID. If we see any duplicate in the next 15-20 minutes, then we can capture most of them that way. The large majority of duplicates happen in a short window after the first event.

Hourly micro-batch dedupe is used to reduce landing time of daily tables that dedupe slowly.