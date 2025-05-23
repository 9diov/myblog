---
title: How we reduced our Rails app's response time by 3x with PostgreSQL
date: 2018-01-25T04:14:54+08:00
authors:
  - Thanh Dinh
draft: false
type: 'posts'
tags:
  - performance
  - postgres
---

## Background

The other day I started to notice that our Rails/PostgreSQL web app, [a cloud-based business intelligence app](https://holistics.io) is a bit sluggish. Reaching to our tracking metrics, I found out that the app's average response time is now a whopping ~200ms!

In order to [have a smooth user interaction](https://www.nngroup.com/articles/powers-of-10-time-scales-in-ux/), direct user interactions' response time must stay under 100ms and ideally under 50ms. Since some of our user interaction depend directly on the response time of some Ajax calls, I was determined to start a quest on optimization to improve our app's user experience.

## Where to start?

The first step in doing any kind of optimization is to find out the bottleneck. And you can only do that with visibility on the system's performance. In other words, you start by adding tracking. For each request, Rails logged the total response time, together with time spent in the controller, the view and ActiveRecord. You can build your own tracking logic by sending the logs to a central server, then parse the logs and store the result data somewhere with querying capabilities.

If you are serious about your web application and you don't have any tracking, add one as soon as possible. The cost of a tracking service like NewRelic or in our case, ScoutApp is neglible compared to the insights that they provide. We use ScoutApp since it not only provides the summary metrics but also the ability to drill down on the sluggish endpoints, not to mention the valuable feature of  n + 1 issue detection (I will come to that later).

Note that for summary metrics, don't just focus on average response time, but look into 75th and 90th percentile to have a more accurate picture of your app's performance. This is important since some very long requests or a lot of short requests may skew your perception about the app's performance.

Once you have your tracking data, focus on:

* Ones with long running time
* Ones that noticeably degrades user experience
* Ones with high throughput (executes a lot of times)

In our case, we detected the main 3 problems after looking at the tracking data:

* Navigating folder hierarchy feels very sluggish
* Business object list (e.g. list of users in management page, list of reports in analytics page, etc.) takes a long time to render
* A complex query used in our job scheduling subsystem takes longer time than expected to run

## Slow to navigate folder hierarchy

In our BI app, we organize the reports into a familiar hierarchy of folders, similar to a file system or Google Drive. As we provide a pretty sophisticated permission system at each level in the hierarchy, the permission checking logic got quite complex. As more permission rules are added, browsing through the hierarchy gets slower and slower. As we did some profiling through the code, we found that some endpoint used during the browsing process sends out up to 200 database queries and 80% of the request is spent on those queries.

Our models look like this:

```ruby
class Folder < ActiveRecord::Base
  has_one :parent
end

class Report < ActiveRecord::Base
  has_one :parent, class: 'Folder'
end
```


As a results, the code to get, say, the code to get the ancestors of a report looks like this:

```ruby
def ancestors(report)
  res = []
    folder = report.parent # query sent to database
    while folder.present?
      res << folder
      folder = folder.parent # another query sent to database
    end
  res
end

```
As you can see, at each level of the hierarchy, a query is sent to the database to retrieve the parent folder of the current one. Together with permission checking at each hierarchy with a bunch of similar logic, our app is sending out hundreds of queries just to show the user when she browses through a folder.

I first thought about caching the whole hierarchy in our cache (Redis) to avoid bombarding our database with such queries. However, the trade-off of such strategy is cache invalidation which is very error-prone and hard to maintain as new permission rule is added to the system.

After some more research, I found out that with PostgreSQL, there is a way to query hierarchical/graph-like data with a single query! Behold the *Recursive CTE*!

With recursive CTE, I can now retrieve the whole hierarchy with a query like so:

```sql
with recursive tree as (
  select R.parent_id as id, array[R.parent_id]::integer[] as path
  from #{Folder.table_name} R
  where id = #{folder_id}
  
  union
  
  select C.parent_id, tree.path || C.parent_id
  from #{Folder.table_name} C
  join tree on tree.id = C.id
) select path from tree
where id = 0
```

As I replaced the old logic with these queries, our browsing response time reduces from hundreds milliseconds to under 50ms, a huge step forward!

## The infamous n + 1 problem

The previous problem is an example of the infamous n + 1 problem. The issue occurs as we use Active Record to retrieve a list of n objects (n rows in database). When we need to get the extra information from a relationship, for example, get author of a book from the list of books, an extra query is executed for each of the n books. Thus we need 1 query to get the list, plus n queries to get the authors, which adds up to n + 1 queries. Each query has its own overhead, and when this happens, all the overhead amount to a considerable slowdown of the final web response.

You can easily detect the n + 1 problem by reading the Rails log in development environment for the slow endpoints. If you want a more automatic way to detect the problem, you can use the [Bullet gem](https://github.com/flyerhzm/bullet). This gem detects n + 1 problem and can send out the alerts through JavaScript alert, browser console, Rails log, or even Growl notification!

### Eager loading

Once you have detected the n + 1 problem, now's the time to fix it. The easiest way to fix the issue with Rails is to use eager loading. Instead of getting the list of books like so:

```ruby
books = Book.order(:title)
```

You add the `includes` method, like so:

```ruby
books = Book.includes(:author).order(:title)
```

With eager loading, instead of n + 1 queries being sent out, Rails will execute 2 queries like this:
	
```sql
SELECT * FROM books ORDER BY title
SELECT * FROM author WHERE book_id IN (<IDs gotten from the first query>)
```

Now your response time should be much better since you have reduced the number of database queries from n + 1 to only 2!

### Using JOIN

Eager loading works well for simple cases, but when the extra data needed for each object in the list is not straightforward part of a simple relationship, you will need to manually generate a SQL query with JOIN. It seems complicated but actually pretty easy to do. The upside is that you now can retrieve all the required data with a single query!

There are 2 ways to execute a JOIN query with Rails. The first one is to use [method chaining](http://guides.rubyonrails.org/active_record_querying.html#understanding-the-method-chaining). You can specify the exact columns for retrieval with this method. For example:

```ruby
Book.select('books.id, books.pages, authors.name')
  .joins(:authors)
  .where('authors.created_at > ?', 1.week.ago)
```

You can also make the call reusable by putting it into a class method and chain them together:

```ruby
class Book
  def self.chain_select
    select('books.id, books.pages')
  end

  def self.include_author_name
    select('authors.name')
    .joins(:authors)
    .where('authors.created_at > ?', 1.week.ago)
  end

  def self.include_comments
    select('comments.content')
    .joins(:comments)
  end
end

Book.chain_select
  .include_author_name
  .include_comment
```

The second way to execute a SQL query is to use [find_by_sql](http://guides.rubyonrails.org/active_record_querying.html#finding-by-sql) or [select_all](http://guides.rubyonrails.org/active_record_querying.html#select-all) and write a direct SQL query. `select_all` is similar to `find_by_sql` but returns array of hashes instead of array of book objects.

```ruby
Book.find_by_sql("SELECT books.id, books.page, authors.name 
  FROM books JOIN authors ON authors.book_id = books.id 
  WHERE authors.created_at > now () - interval '1 week'")
```

This method is not portable and reusable and should be avoided unless the chaining method can't support your query.

By using these JOIN queries, you will be able to reduce the overhead to the bare minimum.

## Speed up search with PostgreSQL's trigram indexes

One of the advantage of the recursive CTE queries that I mentioned before is now we can enable search query directly inside the CTE query, instead of doing a string search from Ruby after getting the data out. This speeds up the process but there is still room for improvement.

Basically we can now run the following query for search:

```sql
SELECT *
FROM reports
JOIN ...<omitted>
WHERE reports.content like '%search_term%'
```

As we want to be able to do fuzzy search on the content of the reports, the performance is getting quite slow. Fuzzy search, together with the requirement to support non-English languages also remove the possibility of using PostgreSQL 's [full text search support](https://www.postgresql.org/docs/current/static/textsearch.html).

After digging deeper into PostgreSQL's documentation, I found out that it supports [trigram indexes](https://www.postgresql.org/docs/current/static/pgtrgm.html). Trigram indexes work by breaking text input into chunks of 3 letters. For example, the trigram for the word 'performance' is 'per', 'erf', 'rfo', ..., 'nce'.

To create the index, you can run the following (put it into your migration file):

```sql
CREATE INDEX CONCURRENTLY index_reports_on_content_trigram
ON reports
USING gin (content gin_trgm_ops);
```

In our case, the indexes help reduce our test search query from ~100ms to <5ms, a 20 times improvement in response time!

## Optimizing a complex PostgreSQL query

In our app we have a pretty complex query as part of our job scheduling system. The query itself is a 40-line long query with multiple [CTEs](https://www.postgresql.org/docs/current/static/queries-with.html). Recently our tracking data has shown that this query is gradually getting slower and slower. As this query directly affects the latency of each of our background job, it is important to ensure that it runs as fast as possible.

The default tool whenever we want to check a query's performance is to use [EXPLAIN query](https://www.postgresql.org/docs/current/static/sql-explain.html). For PostgreSQL, using `EXPLAIN ANALYZE` both executes the query and prints out the query plan. Our explain output looks something like this:

[Screenshot of explain output]

If you want better-formatted output, there are some great EXPLAIN visualization tools such as [Postgres Explain Visualizer](http://tatiyants.com/pev/) or [Gocmdpev](https://github.com/simon-engledew/gocmdpev).

Interpreting EXPLAIN output and doing the actual optimization is a huge topic by itself. But there are steps that you can generally follow:

* Focus on the slowest/costliest nodes in the explain output
* Knowing the different between `Heap Scan`, `Index Scan`, etc.

Here is the list of the terms you may find in the explain output and their meaning. Source is from the excellent gocmdpev:

* Append:          Used in a UNION to merge multiple record sets by appending them together
* Limit:           Returns a specified number of rows from a record set
* Sort:            Sorts a record set based on the specified sort key
* NestedLoop:      Merges two record sets by looping through every record in the first set and trying to find a match in the second set. All matching records are returned
* MergeJoin:       Merges two record sets by first sorting them on a join key
* Hash:            Generates a hash table from the records in the input recordset. Hash is used by Hash Join
* HashJoin:        Joins to record sets by hashing one of them (using a Hash Scan)
* Aggregate:       Groups records together based on a GROUP BY or aggregate function (e.g. sum())
* HashAggregate:   Groups records together based on a GROUP BY or aggregate function (e.g. sum()). Hash Aggregate uses a hash to first organize the records by a key
* SequenceScan:    Finds relevant records by sequentially scanning the input record set. When reading from a table, Seq Scans (unlike Index Scans) perform a single read operation (only the table is read)
* IndexScan:       Finds relevant records based on an Index. Index Scans perform 2 read operations: one to read the index and another to read the actual value from the table
* IndexOnlyScan:   Finds relevant records based on an Index. Index Only Scans perform a single read operation from the index and do not read from the corresponding table
* BitmapHeapScan:  Searches through the pages returned by the Bitmap Index Scan for relevant rows
* BitmapIndexScan: Uses a Bitmap Index (index which uses 1 bit per page) to find all relevant pages. Results of this node are fed to the Bitmap Heap Scan
* CTEScan:         Performs a sequential scan of Common Table Expression (CTE) query results. Note that results of a CTE are materialized (calculated and temporarily stored)

Here are some rules that you can follow to 

* If you see `SequenceScan`, it is likely lacking an index. Try adding a relevant index to see if it changes to `IndexScan`.
* If you see `BitmapHeapScan`, look at the number of Heap Blocks, shared hit, read hit and written. A high number of read hit means you've got a lot of cache miss.
* If you find the `Sort` or `MergeJoin` is slow, check your PostgreSQL configuration for [work_mem](https://www.postgresql.org/docs/current/static/runtime-config-resource.html).

In our case, the costliest part of our query is on a `BitmapHeapScan` with a huge number of pages that need to be retrieved due to cache miss. Even with proper indexing, the performance improvement is negligible. The issue stumped me for a while until I tried to replicate the issue locally by getting a database dump and restore it on my local machine. For some reason, the query ran much faster and the amount of cache miss is minimal! What exactly happened here?

Diving deep into PostgreSQL internals, in the end I found out the root cause. Due to the way PostgreSQL's [MVCC](https://wiki.postgresql.org/wiki/MVCC) works, deleted or updated rows are not removed but kept on disks. Without frequent VACUUMs, the `HeapScan` needs to scan through all the deleted/updated rows to retrieve the relevant rows. When the query is executed locally, since there was no baggage from deleted/updated rows, it ran much faster.

Going through PostgreSQL documentation, I also found out that the auto-VACUUM configuration is not appropriate for our case. You can read more on proper configuration values [here](https://www.citusdata.com/blog/2016/11/04/autovacuum-not-the-enemy/).

In our case, setting the following configurations improved our performance by an order of magnitude!

```sql
ALTER TABLE <table> SET (autovacuum_vacuum_scale_factor = 0.0);
ALTER TABLE <table> SET (autovacuum_vacuum_threshold = 1000);
ALTER TABLE <table> SET (autovacuum_analyze_scale_factor = 0.0);
ALTER TABLE <table> SET (autovacuum_analyze_threshold = 1000);
```

## Bonus: Use PostgreSQL indexes to improve query performance

https://github.com/plentz/lol_dba

## Reference

* [EXPLAIN operations](http://use-the-index-luke.com/sql/explain-plan/postgresql/operations)
