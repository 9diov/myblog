---
title: What programming languages to learn? The four-language rule
date: 2017-08-10
draft: false
type: 'posts'
tags:
  - programming-language
  - oop
  - functional
---

Here's the **four-language rule**:  

> A decent programmer needs to be able to code comfortably in **at least one language** in each of the following categories:
> 1. **Business/Enterprise**: Java and/or C#
> 2. **Scripting/Web/Data science/AI**: Python and/or Ruby and JavaScript/TypeScript
> 3. **System level**: C/C++/Go/D/Rust/Zig
> 4. **Academic/Enlightenment**: Lisp/Haskell/Smalltalk/Prolog/Forth

## 1. Business/Enterprise
**Examples**: Java and/or C#

These are the workhorses of the enterprise world. They dominate in corporate environments, financial institutions, and large-scale backend systems. Mastering one means you're immediately employable in a broad range of stable, good-paying jobs.

## 2. Scripting/Web/Data science/AI
**Examples**: Python and/or Ruby and JavaScript/TypeScript

These languages prioritize flexibility and speed of development. They’re essential for modern full-stack web development, rapid prototyping, automation, and scientific computing. If your time is limited, prioritize mastering this category and the previous one—they offer the most immediate career returns.

## 3.System level 
**Examples**: C/C++/Go/D/Rust/Zig

Learning at least one of these languages deepens your understanding of what abstractions cost and how machines actually execute your code. For example, writing asynchronous JavaScript is easier to appreciate once you understand how epoll works in Linux—exposed via C interfaces. 

These languages also dominate niche but crucial domains like:

* Game engines
* Embedded systems
* OS development
* High-performance computing

## 4. Academic/Enlightenment 
**Examples**: Lisp/Haskell/Smalltalk/Prolog/Forth

These languages stretch your mental model of what programming is. They discard mainstream compromises in favor of **conceptual purity**:

* **Lisp**: pure syntactically, [homoiconic](https://en.wikipedia.org/wiki/Homoiconicity), syntax = data, code as list structures
* **Haskell**: purely functional, lazy evaluation, a masterclass in type systems
* **Smalltalk**: pure OOP, everything is an object, even control flow
* **Prolog**: pure [logic programming](https://en.wikipedia.org/wiki/Logic_programming), programs are sets of logical relations, define what should be true, not how.
* **Forth**: pure stack-based [concatenative language](https://en.wikipedia.org/wiki/Concatenative_programming_language), teaches resource constraints and raw control

Once you've grokked these paradigms, new languages feel like hybrids rather than novelties. You’ll start to recognize features like closures, pattern matching, monads, or LINQ not as new hurdles—but as familiar ideas in different clothes.

## Conclusion

Learning these four categories is not about resume padding. It’s about:

* **Mental fluency** in key paradigms
* **Transferable intuition** when learning new tools
* **Deeper debugging ability** when [abstractions leak](https://www.joelonsoftware.com/2002/11/11/the-law-of-leaky-abstractions/)

To put it briefly: once you've written a recursive parser in Lisp, built a concurrent server in Go, and reasoned about types in Haskell, learning “whatever new JS framework is hot this month” becomes trivial.
