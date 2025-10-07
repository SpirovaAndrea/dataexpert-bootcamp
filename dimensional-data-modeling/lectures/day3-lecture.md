# Day 3: Graph Data Modeling

## Introduction

Graph data modeling is different than dimensional and relational modeling. It's more relationship focused and less entity focused. The focus is on how things are connected.

You don't really have much of a schema around properties. The schemas are very flexible and data agnostic.

## Additive vs Non-Additive Dimensions

When you're talking about how to count stuff, if you can take all the subtotals and add them up to get the grand total, that dimension is additive.

The key question is: Can an entity have two dimensional values at the same time over some time frame?

A dimension is additive over a specific time window if and only if the grain of data over that window can only ever be one value at a time. This is about how these dimensions interact with time.

You don't need to use COUNT DISTINCT on pre-aggregated dimensions if they're additive.

Non-additive dimensions are usually non-additive with respect to COUNT aggregations but not SUM aggregations.

The key thing to distinguish if a dimension is additive or not is: Can a user be two of them at the same time in a given day? If they can, it's not additive.

Most dimensions are additive.

For example, you can't say all your users are iPhone users or Android users because a user can be both. This makes device type non-additive in this case.

## Power of Enums

There is a limit to how much you can enumerate. If it's less than 50, it's a great idea.

An ENUM (enumerated type) is a custom data type that lets a column accept only a predefined list of values. It's like saying "this column must be one of these specific values and nothing else."

**Why use Enums:**
- Data quality automatically enforced
- Built-in static fields
- Built-in documentation

Enums can be a good value for your sub-partitions. For example, when processing notifications, you don't want to process all of the notifications together.

If you have a pipeline that has 50 upstream datasets, you want to group them into enumerated datasets. You keep track of all the possible values of stuff.

Check out the Little Book of Enums for more details.

**Use cases:**
- Whenever you have tons of sources mapping to a shared schema
- Airbnb: Unit economics (fees, coupons, credits, taxes)
- Netflix: Infrastructure graph (databases, applications, servers, CI/CD jobs)
- Facebook: Family of apps (Instagram, Facebook, WhatsApp)

## Flexible Schemas

How do you model data from disparate sources into a shared schema? The answer is leveraging map types.

An enumerated list of things is similar to the vertex type in the graph world.

With flexible schemas, if you need to add more things you just put it in the map. You can add more columns to the map. The map can get bigger, though there is a limit.

**Benefits:**
- Manage a lot more columns
- Don't have to run ALTER TABLE
- Don't need to have a ton of NULL columns
- The "other_properties" column is pretty awesome for rarely-used-but-needed columns

**Drawbacks:**
- Compression is usually worse, especially if you use JSON
- Reduced readability

**When should you use flexible data types:**
Map is the only one that's truly flexible. Struct is not flexible. Array usually has to be a specific type.

## Graph Data Modeling Fundamentals

Graph data modeling is relationship focused, not entity focused. We don't care as much about columns.

They all have the same schema. Usually the model looks like this: three columns - identifier (string), type (string), and properties (map).

The focus shifts from how things are to how things are connected.

## How Graph Data Modeling is Different

For vertices, we have that 3-column schema: identifier, type, and properties.

Edges have their own standard schema: subject identifier, subject type, object identifier, object type, edge type, and properties.

The subject is the person doing the thing. The object is the thing being done to.

For example, the relationship between a player and a team:
- Subject identifier: player name
- Subject type: player
- Object identifier: team name
- Object type: team
- Edge type: plays_for
- Properties: how many years they're playing on the team, etc.

## Nodes and Edges

The way they are connected is that an edge takes two nodes and links them through some sort of edge type, and they are linked together.

This model is powerful for representing complex relationships between entities in a flexible, scalable way.