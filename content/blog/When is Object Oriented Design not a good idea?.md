---
title: When is Object Oriented Design not a good idea?
date: 2020-03-21
draft: false
type: 'posts'
tags:
  - oop
  - software-design
---

The main premise of object oriented design is **breaking down the behaviors of a program into independent, well encapsulated objects** that interact with each other. Each object maintains its own private state, ensure the state satisfies its own **invariants**. Each object contains sets of behaviors that are encapsulated. The only way to execute the behaviors is via a well-defined API that the object exposes.

Good object oriented architecture depends on the assumption that **the problem can be cleanly broken down into encapsulated objects**. When this is not the case, object oriented mostly does not help. Generally speaking, this happens when there are **cross-cutting concerns** that involves multiple objects.

For a very simple example, let’s say we need to model a problem where students enrolls in different courses. Using OOP, we create two classes:

- Student
- Course

This is well and good, but the “enrollment” part, should it be part of Student class interface, or the Course class interface? Or instead, we introduce a new EnrollmentManager class to manage this:

- `student.enroll(course)`
- `course.enroll(student)`
- `EnrollmentManager.enroll(student, course)`

The 3rd option is against the pure OOP ideal of having behavior just as objects interacting with each other. It resembles the “bad old days” where procedural programming was the norm. However, in many cases, it is the best option. Why?

- It decouples Student class from Course class
- It is easy to add new behavior without modifying Student and Course’s intefaces

If you have done software development in the real world, you may have seen the bloated class problem where any new requirements that is related to “Student” get thrown into this class and the code gets harder and harder to understand and manage.

Another, more complex example to illustrate how messy real-world requirements are. Let’s say, you need to model a bicycle that can travel. Simple, right. But what if there are more requirements:

- A bicycle can be made from metal (steel or iron), which mean it interacts with magnets. Furthermore, other things such as cars, motorbikes, paperclips, etc. can be made from metal too.
- A bicycle can be made from bamboo, which can burn when lit on fire
- People can buy and sell stuff, including bicycles, and you need a banking system to record the transaction.
- A bicycle can be ridden by people, but so are motorbikes
- A bicycle can travel on roads, not on rivers (which boats can)
- A bicycle has wheels, and so do motorbikes and cars

Without generic functions/procedures outside of objects, OOP polymorphism and interfaces can get you half-way there, but not all the way. Game developers faced this problem almost 20 years ago and came up with [ECS architecture](https://en.wikipedia.org/wiki/Entity_component_system "en.wikipedia.org") to solve it.

[Domain-driven design](https://en.wikipedia.org/wiki/Domain-driven_design "en.wikipedia.org") separates the concepts of Value Objects, Entity Objects, and Services for the exact same reason.

I would like to end with quote from Alexander Stepanov, the orignial author of C++ STL:

> I find OOP technically unsound. It attempts to decompose the world in terms of interfaces that vary on a single type. To deal with the real problems you need multisorted algebras - families of interfaces that span multiple types. I find OOP philosophically unsound. It claims that everything is an object. Even if it is true it is not very interesting - saying that everything is an object is saying nothing at all. I find OOP methodologically wrong. It starts with classes. It is as if mathematicians would start with axioms. You do not start with axioms - you start with proofs. Only when you have found a bunch of related proofs, can you come up with axioms. You end with axioms. The same thing is true in programming: you have to start with interesting algorithms. Only when you understand them well, can you come up with an interface that will let them work.

## Conclusion

The best thing about OOP is about encapsulation and it works well when the problem can be broken down to cleanly separated concerns. When it is not the case, plain old procedural programming and functional programming makes more sense.

In any case, the best advice is don’t be dogmatic about it. Don’t rule out a potential good design because it is “not object-oriented”. Sometimes putting data and behavior together (OOP) makes more sense, sometimes separating them (functional/procedural) makes more sense. What is important is how that design decision impact readability, maintainability, and extensibility. Only you know that in your context, not some architect astronaut.