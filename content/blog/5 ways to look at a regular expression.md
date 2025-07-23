---
title: 5 ways to look at a regular expression
date: 2025-07-22
authors:
  - Thanh Dinh
draft: false
type: 'posts'
tags:
  - software-design
  - state-machine
  - functional
---

How does `/^ab*c?$/` accept "a", "abb", and "abc", but still reject "abdc"?

Because under the hood, whether you’re matching a regex, validating a Vue form, or rewriting URLs in nginx—lives a finite‑state machine (FSM). Change your lens and that FSM shapeshifts into a flat data table, a bundle of switches, a tight loop, a chain of little parsers, or a nest of function calls. 

## 0. The problem statement

Our job is to write a `match(s: String) => boolean` function that match a string based on that regular expression `/^ab*c?$/`.

Here is the meaning of the regular expression:
* Check matching against `a`
* Check matching against 0 or more `b`
* Lastly, check matching against an optional `c`

## 1. The Switch‑Statement Lens - Explicit Control Flow

Each of the 3 phases can be kept track with a state variable. Thus, the first way: using a switch inside a for loop to branch on the state.

```javascript
export const match = (str) => {
  let st = 'START';             // START → B_STAR → [AFTER_C]
  for (const ch of str) {
    switch (st) {
      case 'START':
        if (ch === 'a') st = 'B_STAR';
        else return false;
        break;
      case 'B_STAR':
        if (ch === 'b') break;              // loop
        if (ch === 'c') st = 'AFTER_C';
        else return false;
        break;
      case 'AFTER_C':
        return false;                       // junk after optional c
    }
  }
  return st === 'B_STAR' || st === 'AFTER_C';
};
```

**Idea in a tweet**: Keep a state variable; branch on it.

## 2. The Data‑Table Lens - Classic DFA

```javascript
export const match = (str) => {
  const T = {
    0: { a: 1 },
    1: { b: 1, c: 2 },
    2: {}                // accept state
  };
  let s = 0;
  for (const ch of str) {
    s = T[s][ch] ?? -1;
    if (s === -1) return false;
  }
  return s === 2;
};
```

## 3. The Structural‑Loop Lens - Implicit State

```javascript
export const match = (s) => {
  let i = 0;
  if (s[i++] !== 'a') return false;     // START → need 'a'

  while (s[i] === 'b') i++;             // B* self‑loop

  if (s[i++] !== 'c') return false;     // expect 'c'
  return i === s.length;                // ACCEPT at end
};
```

## 4. The Parser‑Combinator Lens - Functional Lego

```javascript
const char = (c) => (s) =>
  s.startsWith(c) ? [c, s.slice(1)] : null;

const seq  = (...ps) => (s) => ps.reduce(
  (acc, p) => acc && p(acc[1]), ['' , s]
);
const many = (p) => (s) => {
  let rest = s, out = [];
  while (p(rest)) {
    const [v, r] = p(rest);
    out.push(v); rest = r;
  }
  return [out, rest];
};

export const match = (s) =>
  seq(char('a'), many(char('b')), char('c'))(s)?.[1] === '';
```

## 5. The Recursive‑Descent Lens - Call‑Stack Automaton

```javascript
export const match = (str) => {
  let i = 0;
  const eat = (c) => str[i] === c && (i++, true);

  const B = () => {                    // B → b B | ε
    while (eat('b'));
    return true;
  };

  const S = () => eat('a') && B() && eat('c');

  return S() && i === str.length;
};
```

## 6. Bonus: The Type Definition Lens - Type Acrobatic

```typescript
/* ------------------------------------------------------------------ */
/*  Utility: does a string consist solely of 'b' characters?          */
/* ------------------------------------------------------------------ */
type IsAllBs<S extends string> =
  S extends ''                         // ε
    ? true
    : S extends `b${infer Rest}`       // peel one 'b'
      ? IsAllBs<Rest>                  // keep checking
      : false;                         // anything else → reject

/* ------------------------------------------------------------------ */
/*  Main matcher: ^ a (b*) (c?) $                                      */
/* ------------------------------------------------------------------ */
type MatchABStarCOpt<S extends string> =
  S extends `a${infer Rest}`           // must start with 'a'
    ? Rest extends ''                  // lone 'a'
        ? true
        : Rest extends `${infer Bs}c`  // ...b* followed by 'c'
            ? IsAllBs<Bs>
            : IsAllBs<Rest>            // ...b* with no 'c'
    : false;                           // anything else

// ✅ accepted
type T0 = MatchABStarCOpt<'a'>;        // true
type T1 = MatchABStarCOpt<'ab'>;       // true
type T2 = MatchABStarCOpt<'abbbbc'>;   // true
type T3 = MatchABStarCOpt<'ac'>;       // true

// ❌ rejected
type F0 = MatchABStarCOpt<'b'>;        // false
type F1 = MatchABStarCOpt<'abdc'>;     // false
type F2 = MatchABStarCOpt<'aac'>;      // false
```
