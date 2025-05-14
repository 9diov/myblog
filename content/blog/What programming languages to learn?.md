---
title: What programming languages to learn?
date: 2017-08-10
draft: false
type: 'posts'
tags:
  - programming-language
  - oop
  - functional
---

In my opinion, a decent programmer needs to be able to code comfortably in **at least one language** in each of the following categories:

* **Business/Enterprise**: Java and/or C#
* **Scripting/Web/Data science/AI**: Python and/or Ruby and JavaScript/TypeScript
* **System level**: C/C++/Go/D/Rust/Zig
* **Academic/Enlightenment**: Lisp/Haskell/Smalltalk/Prolog/Forth

If your time is limited, at least master the first two categories above. However, the latter two are still highly recommended.

Learning languages in the third category will help you appreciate the **low level details** that needs to be done to make your abstraction works. For example, learn NodeJS for web development but learn bit of C to know how it utilizes epoll (in Linux) for asynchronous operation (technically this is not the language, but still relevant since OS interface is mostly in C).

Learning languages in the fourth category will give you the ability to appreciate programming languages at the **purest level**, removing all the distractions. For example: 

* **Lisp**: pure syntactically, [homoiconic](https://en.wikipedia.org/wiki/Homoiconicity), syntax = data, code as list structures
* **Haskell**: purely functional 
* **Smalltalk**: pure OOP, everything is an object, even control flow
* **Prolog**: pure [logic programming](https://en.wikipedia.org/wiki/Logic_programming), programs are sets of logical relations
* **Forth**: pure stack-based [concatenative language](https://en.wikipedia.org/wiki/Concatenative_programming_language)

The main benefit is that after learning these, you have the confidence that any new language you need to learn is just a diluted and/or mixed version of those paradigms. Thus you rarely need to wrap your head around a new concept (e.g. closure in JavaScript, generator in Python, LINQ in C#, etc.), which I think is the biggest hurdle in learning new programming language. For example, understanding closure in JavaScript is a piece of cake if you know Scheme (dialect of Lisp).
