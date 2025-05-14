---
title: 5 causes of Accidental Complexities
date: 2020-04-30
authors:
  - Thanh Dinh
draft: false
type: 'posts'
tags:
  - software-design
  - complexity
  - oop
  - functional
---

The main problem with software complexity is that few people actually deconstruct what exactly is software complexity. In my opinion, an exact definition of software complexity is hard. Yet we can break them down into:

2 types of complexity:

* **Essential complexity**: the inherent complexity that is required to solve the problem which can’t be removed. Mostly this comes from the business requirements and some comes from “the optimal solution” to the problem.
* **Accidental complexity**: the complexity due to the way the solution is structured. This can be managed and reduced

For essential complexity, even though you can’t reduce or remove it, you still can organize it so it is easier to manage by breaking it down to smaller pieces.

For accidental complexity, you can actually reduce it. Here’s how.

Firstly, breaking down complexity to the following 5 causes:

* **Shared mutable state**: Shared mutable state is generally the biggest culprit of complexity in software design. A piece of state that can be mutates in multiple places/times makes it very hard to reason about. It causes implicit dependency on time. It causes explosion of state space. And finally it makes running code concurrently extremely hard.
* **Side effects**: Asynchronous, fallible logic such as rendering call, networking call, IO calls are very hard to properly reason about. Things like callback hell and non-deterministic error handling are the results of side effects.
* **Dependencies**: If your code never change, the only problem with dependencies are just that code is harder to read. However, once you need to modify the design to accommodate new requirements, badly designed dependencies make it extremely hard to reliably change any thing. Every time something is modified, there are cascades of changes that need to be done in order for the design to work again. For dependency management, the golden rule is: **Things that change more often depend on things that change less often**.
* **Control flow**: This includes branching (if/else/case/switch/etc.), looping (for/while/etc.), error handling (try/catch/etc.). The more of these, the harder it is to reason, debug and test the design. The main culprit for this is the failure to decouple a problem into orthogonal sub-problems (See Tim Boudreau's answer to What are the causes of accidental complexity in software?)
* **Code size**: Number of lines of code, the verbosity of the programming languages. This is the least important causes for complexity but still needs to be kept in mind

Each of the above deserves a whole answer to elaborate them in more details and I will try to do so when I have more time.

In general, to manage complexity, you can either:

* Reducing/Minimizing complexity
* Isolating/Encapsulating complexity

The two common programming paradigms of object oriented and functional programming actually solves the complexity problem in two different ways, matching the two strategies above:

* Object oriented solves the problem by isolating/encapsulating complexity
* Functional programming solves the problem by reducing/minimizing complexity

Relevant quote from Michael Feathers:

> OO makes code understandable by encapsulating moving parts. FP makes code understandable by minimizing moving parts — Michael Feathers

By combining the two styles appropriately, you can actually manage complexity pretty well! Gary Bernhardt gave a seminal talk on this topic in 2012. The talk was “Boundaries” and can be found here (Boundaries). It is highly recommended to look at it.

In conclusion, you can manage complexity by tracking down the causes of complexity (the five mentioned above), then try to reduce or isolate them with functional and OOP.
