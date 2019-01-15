# Type Class Morphisms in Agda

I was recently directed to the paper [Type Class Morphisms][tcm] by Conal Elliot, which details
a technique for reasoning about designing and reasoning about typeclass instances. It repeats
the following mantra:

> The instance’s meaning follows the meaning’s instance.

The way I interpret it, this means you should come up with *denotational semantics* for an
abstract data type, then prove the laws of a typeclass of interest *with respect to the
denotational semantics*, rather than on the precise implementation.

TCM uses Haskell, which doesn't have substantial theorem-proving abilities (yet?), so
Conal does a few equational proofs by hand. I figured I would perform these proofs
formally as an exercise in the [Agda][agda] language, both to strengthen the technique,
and see how you would approach the idea of "semantic instances".

[tcm]: http://conal.net/papers/type-class-morphisms/type-class-morphisms.pdf
[agda]: https://wiki.portal.chalmers.se/agda/pmwiki.php

## Abstract Data Types

TCM uses the notation `abstract type` to define a total map, but `abstract` is not a real
Haskell keyword. In Agda, we would instead create a record interface to represent the
abstract type and its operations:

```agda
-- Interface for total maps
record TotalMap (TMap : Set → Set → Set) : Set₁ where
  field
    -- Operations
    constant : ∀ {K V} → V → TMap K V
    update : ∀ {K V} → K → V → TMap K V → TMap K V
    sample : ∀ {K V} → TMap K V → K → V
    unionWith : ∀ {K A B C} → (A → B → C) → TMap K A → TMap K B → TMap K C

    ...
```

[Note there are slight stylistic and notational differences between Agda and Haskell,
prominently the use of capital letters (`K`, `V`) for type variables, and the explicit
quantification (`∀ {...}`)]

The semantic function is defined as another operation in the interface:

```agda
    -- Denotation
    ⟦_⟧ : ∀ {K V} → TMap K V → (K → V)
```

Since this function is part of the `TotalMap` interface, we cannot know how it behaves.
However, we can define properties that we want to hold, using the propositional equality
type `_≡_`. Thus we add "laws" to our interface for each equation that we wish to be true:

```agda
    -- Laws
    sem-constant : ∀ {K V} (k : K) (v : V)
      → ⟦ constant v ⟧ k ≡ v
    sem-update : ∀ {K V} (k : K) (v : V) (m : TMap K V)
      → ⟦ update k v m ⟧ k ≡ v
    sem-update≠ : ∀ {K V} (k k′ : K) (v : V) (m : TMap K V)
      → k ≢ k′
      → ⟦ update k v m ⟧ k′ ≡ ⟦ m ⟧ k
    sem-sample : ∀ {K V} (m : TMap K V) (k : K)
      → sample m k ≡ ⟦ m ⟧ k
    sem-unionWith : ∀ {K A B C} (f : A → B → C) (m : TMap K A) (n : TMap K B) (k : K)
      → ⟦ unionWith f m n ⟧ k ≡ f (⟦ m ⟧ k) (⟦ n ⟧ k)
```

These of course correspond closely with the equations given in TCM.

## Monoids

The typeclass we are building up to is `Monoid`; we hope to show that `TMap K V` forms a
monoid whenever `V` does, as is shown in TCM. We can't show this directly, since we know
nothing about `TMap` or how its operations actually behave. This is why TCM introduces
"semantic instances": instances not on the data type but on the semantic interpreation of
the data type.

In Agda, we need only to define a single `Monoid` interface. Rather than making a
distinction between an instance and a "semantic instance", we can instance parameterize
each instance *by an equality relation*, then implement an instance using the semantic
function in that relation. To illustrate, let's first look at our definition of `Monoid`:

```agda
-- Interface for monoids (including laws).
record Monoid (A : Set) (_≈_ : Rel A _) : Set where
  infix 7 _⊕_
  field
    -- Operations
    _⊕_ : A → A → A
    ∅ : A
    -- Laws
    right-identity : ∀ a → (a ⊕ ∅) ≈ a
    left-identity : ∀ b → (∅ ⊕ b) ≈ b
    assoc : ∀ a b c → ((a ⊕ b) ⊕ c) ≈ (a ⊕ (b ⊕ c))
```
-
It's crucial that the laws are defined using `_≈_`, which the implemention of the instance
can choose.

## Proving the Laws

In `TotalMap`, we first must define the relation that we are going to use:

```agda
  -- Total-map equivalence relation based on the semantic function.
  _≈_ : ∀ {K V} → Rel (TMap K V) _
  m ≈ n = ∀ k → ⟦ m ⟧ k ≡ ⟦ n ⟧ k
```

As you can see, we use the semantic function `⟦_⟧` rather than comparing the `TMap`s directly.

Our `Monoid` implementation begins by defining the monoid operations;

```agda
  sem-monoid : ∀ {K V} → Monoid V _≡_ → Monoid (TMap K V) _≈_
  sem-monoid value-monoid = record
    { ∅ = unit ; _⊕_ = _∪_ ; ... }
    where
    ...

    unit = constant ∅
    _∪_ = unionWith _⊕_
```

The laws we must prove are then in terms of the semantic function; for instance, our
right-identity proof looks like this (using the `≡-Reasoning` syntax):

```agda
    right-identity : ∀ m k → ⟦ m ∪ unit ⟧ k ≡ ⟦ m ⟧ k
    right-identity m k = begin
      ⟦ m ∪ unit ⟧ k       ≡⟨ sem-unionWith _⊕_ m unit k ⟩
      ⟦ m ⟧ k ⊕ ⟦ unit ⟧ k ≡⟨ P.cong (⟦ m ⟧ k ⊕_) $ sem-constant k ∅ ⟩
      ⟦ m ⟧ k ⊕ ∅          ≡⟨ V.right-identity (⟦ m ⟧ k) ⟩
      ⟦ m ⟧ k               ∎
```

The other two proofs continue in a similar way:

```agda
    left-identity : ∀ m k → ⟦ unit ∪ m ⟧ k ≡ ⟦ m ⟧ k
    left-identity m k = begin
      ⟦ unit ∪ m ⟧ k       ≡⟨ sem-unionWith _⊕_ unit m k ⟩
      ⟦ unit ⟧ k ⊕ ⟦ m ⟧ k ≡⟨ P.cong (_⊕ ⟦ m ⟧ k) $ sem-constant k ∅ ⟩
      ∅ ⊕ ⟦ m ⟧ k          ≡⟨ V.left-identity (⟦ m ⟧ k) ⟩
      ⟦ m ⟧ k               ∎

    assoc : ∀ m n r k → ⟦ (m ∪ n) ∪ r ⟧ k ≡ ⟦ m ∪ (n ∪ r) ⟧ k
    assoc m n r k = begin
      ⟦ (m ∪ n) ∪ r ⟧ k             ≡⟨ sem-unionWith _⊕_ _ r k ⟩
      ⟦ m ∪ n ⟧ k ⊕ ⟦ r ⟧ k         ≡⟨ P.cong (_⊕ ⟦ r ⟧ k) $ sem-unionWith _⊕_ m n k ⟩
      (⟦ m ⟧ k ⊕ ⟦ n ⟧ k) ⊕ ⟦ r ⟧ k ≡⟨ V.assoc (⟦ m ⟧ k) (⟦ n ⟧ k) (⟦ r ⟧ k) ⟩
      ⟦ m ⟧ k ⊕ (⟦ n ⟧ k ⊕ ⟦ r ⟧ k) ≡⟨ P.sym $ P.cong (⟦ m ⟧ k ⊕_) $ sem-unionWith _⊕_ n r k ⟩
      ⟦ m ⟧ k ⊕ ⟦ n ∪ r ⟧ k         ≡⟨ P.sym $ sem-unionWith _⊕_ m _ k ⟩
      ⟦ m ∪ (n ∪ r) ⟧ k              ∎
```

## Partial Maps

For completion, we can define the partial `Map` type in terms of `TMap`, like what was
done in TCM. We're able to reuse the monoid proofs from earlier, as well as `Maybe` proofs
[from the standard library][maybe-props].

```agda
  Map = λ K V → TMap K (Maybe V)
  module _ {K V} where
    open import Data.Maybe.Properties

    _‼_ : Map K V → K → Maybe V
    m ‼ k = sample m k

    _[_≔_] : Map K V → K → V → Map K V
    m [ k ≔ v ] = update k (just v) m

    map-monoid : Monoid (Map K V) _≈_
    map-monoid = sem-monoid (record { _⊕_ = _<∣>_ ; ∅ = nothing
                                    ; right-identity = <∣>-identityʳ
                                    ; left-identity = <∣>-identityˡ
                                    ; assoc = <∣>-assoc })
    open Monoid map-monoid using ()
      renaming (∅ to empty; _⊕_ to _∪_)
```

[maybe-props]: https://agda.github.io/agda-stdlib/Data.Maybe.Properties.html

## Further Work

The main point of this article was to show the utility of custom equality relations in a
language like Agda, and how it enables techniques like Type Class Morphisms. However,
there is a pretty glaring flaw in our `sem-monoid` signature: we do not let the
parameterized monoid use a custom relation, rather we force it to use
propositional-equality by specifying `Monoid V _≡_`.

A proper implementation would parameterize that relation as well (e.g.
`(_≈ᵛ_ : Rel V _) → Monoid V _≈ᵛ_`); in fact, the Agda standard library takes great care to
ensure that relations can be parameterized over whenever possible. While this sometimes
hurts the immediate readability of standard library code, it is of great utility when you
do use a custom relation, such as we did here.
