import Control.Exception
import Control.Monad
import Control.Monad.Trans.State.Lazy

import Data.List.Index

import Test.Hspec


main :: IO ()
main = hspec $ do
  transformations
  monadicFunctions
  specialFolds
  folds
  search
  zipping

transformations :: Spec
transformations = describe "transformations" $ do
  describe "imap" $ do
    specify "basic" $ do
      imap (-) [1,3..9] `shouldBe` [0-1,1-3,2-5,3-7,4-9]
    specify "empty" $ do
      imap undefined ([] :: [Int]) `shouldBe` ([] :: [Bool])
    specify "x2" $ do
      imap (-) (imap (*) [1..4]) `shouldBe` [0-0*1,1-1*2,2-2*3,3-3*4]

monadicFunctions :: Spec
monadicFunctions = describe "monadic functions" $ do
  describe "imapM/traverse" $ do
    describe "Just" $ do
      specify "success" $ do
        imapM     (\i x -> Just (i-x)) [0..4] `shouldBe` Just [0,0,0,0,0]
        itraverse (\i x -> Just (i-x)) [0..4] `shouldBe` Just [0,0,0,0,0]
      specify "failure" $ do
        imapM     (\i x -> guard (i==x)) [0,1,2,4] `shouldBe` Nothing
        itraverse (\i x -> guard (i==x)) [0,1,2,4] `shouldBe` Nothing
    describe "State" $ do
      specify "basic" $ do
        let f i x = modify ((i,x):) >> return (i-x)
        let (resA, stA) = runState (imapM     f [1,3..9]) []
        let (resB, stB) = runState (itraverse f [1,3..9]) []
        resA `shouldBe` [0-1,1-3,2-5,3-7,4-9]
        resB `shouldBe` [0-1,1-3,2-5,3-7,4-9]
        stA `shouldBe` reverse (zip [0..4] [1,3..9])
        stB `shouldBe` reverse (zip [0..4] [1,3..9])

  describe "imapM_/traverse_" $ do
    describe "Just" $ do
      specify "success" $ do
        imapM_     (\i x -> Just (i-x)) [0..4] `shouldBe` Just ()
        itraverse_ (\i x -> Just (i-x)) [0..4] `shouldBe` Just ()
      specify "failure" $ do
        imapM_     (\i x -> guard (i==x)) [0,1,2,4] `shouldBe` Nothing
        itraverse_ (\i x -> guard (i==x)) [0,1,2,4] `shouldBe` Nothing
    describe "State" $ do
      specify "basic" $ do
        let f i x = modify ((i,x):) >> return (i-x)
        let stA = execState (imapM_     f [1,3..9]) []
        let stB = execState (itraverse_ f [1,3..9]) []
        stA `shouldBe` reverse (zip [0..4] [1,3..9])
        stB `shouldBe` reverse (zip [0..4] [1,3..9])

specialFolds :: Spec
specialFolds = describe "special folds" $ do
  describe "iall" $ do
    specify "full" $ do
      iall (\i x -> i*2==x) [0,2,4,6,8] `shouldBe` True
    specify "early" $ do
      iall (\i x -> i*2==x) [1,2,4,6,8] `shouldBe` False
    specify "empty" $ do
      iall undefined ([] :: [Int]) `shouldBe` True

  describe "iany" $ do
    specify "full" $ do
      iany (\i x -> i*2==x) [1,3,5,7,9] `shouldBe` False
    specify "early" $ do
      iany (\i x -> i*2==x) [0,3,5,7,9] `shouldBe` True
    specify "late" $ do
      iany (\i x -> i*2==x) [1,3,5,7,8] `shouldBe` True
    specify "empty" $ do
      iany undefined ([] :: [Int]) `shouldBe` False

folds :: Spec
folds = describe "folds" $ do
  describe "ifoldr" $ do
    specify "basic" $ do
      ifoldr (\i x a -> if i*2==x then i:a else a) [] [0,2,5,6] `shouldBe` [0,1,3]
    specify "empty" $ do
      ifoldr undefined True [] `shouldBe` True

  describe "ifoldl(')" $ do
    specify "basic" $ do
      ifoldl  (\a i x -> if i*2==x then i:a else a) [] [0,2,5,6] `shouldBe` [3,1,0]
      ifoldl' (\a i x -> if i*2==x then i:a else a) [] [0,2,5,6] `shouldBe` [3,1,0]
    specify "empty" $ do
      ifoldl  undefined True [] `shouldBe` True
      ifoldl' undefined True [] `shouldBe` True
    describe "strictness" $ do
      describe "acc" $ do
        let f a i x = if i==1 then undefined else x:a
        specify "lazy" $ do
          evaluate (take 2 (ifoldl  f [] [1..4::Int]))
            `shouldReturn` [4,3]
        specify "strict" $ do
          evaluate (take 2 (ifoldl' f [] [1..4::Int]))
            `shouldThrow` errorCall "Prelude.undefined"
      describe "elem" $ do
        let f a i _ = a+i
        specify "lazy" $ do
          evaluate (ifoldl  f 1 [undefined, undefined, undefined])
            `shouldReturn` 4
        specify "strict" $ do
          evaluate (ifoldl' f 1 [undefined, undefined, undefined])
            `shouldReturn` 4

search :: Spec
search = describe "search" $ do
  describe "ifilter" $ do
    specify "all" $ do
      ifilter (\i x -> i*2==x) [0,2,4,6] `shouldBe` [0,2,4,6]
    specify "none" $ do
      ifilter (\i x -> i*2/=x) [0,2,4,6] `shouldBe` []
    specify "empty" $ do
      ifilter undefined [] `shouldBe` ([] :: [Bool])

  describe "ifind" $ do
    specify "found" $ do
      ifind (\i x -> i*2==x) [1,3,4,7] `shouldBe` Just 4
    specify "not found" $ do
      ifind (\i x -> i*2==x) [1,3,5,7] `shouldBe` Nothing
    specify "empty" $ do
      ifind undefined [] `shouldBe` (Nothing :: Maybe Bool)

  describe "ifindIndex" $ do
    specify "found" $ do
      ifindIndex (\i x -> i*2==x) [1,3,4,7] `shouldBe` Just 2
    specify "not found" $ do
      ifindIndex (\i x -> i*2==x) [1,3,5,7] `shouldBe` Nothing
    specify "empty" $ do
      ifindIndex undefined [] `shouldBe` Nothing

  describe "ifindIndices" $ do
    specify "all" $ do
      ifindIndices (\i x -> i*2==x) [0,2,4,6] `shouldBe` [0,1,2,3]
    specify "none" $ do
      ifindIndices (\i x -> i*2/=x) [0,2,4,6] `shouldBe` []
    specify "empty" $ do
      ifindIndices undefined [] `shouldBe` []

zipping :: Spec
zipping = describe "zipping" $ do
  describe "basic" $ do
    specify "2" $ do
      izipWith (\i a b -> [i,a,b]) [1,2] [3,4]   `shouldBe` [[0,1,3],[1,2,4]]
      izipWith (\i a b -> [i,a,b]) [1,2] [3,4,0] `shouldBe` [[0,1,3],[1,2,4]]
      izipWith (\i a b -> [i,a,b]) [1,2,0] [3,4] `shouldBe` [[0,1,3],[1,2,4]]
    specify "3" $ do
      izipWith3 (\i a b c -> [i,a,b,c]) [1,2] [3,4] [5,6]
        `shouldBe` [[0,1,3,5],[1,2,4,6]]
      izipWith3 (\i a b c -> [i,a,b,c]) [1,2] [3,4] [5,6,0]
        `shouldBe` [[0,1,3,5],[1,2,4,6]]
      izipWith3 (\i a b c -> [i,a,b,c]) [1,2] [3,4,0] [5,6]
        `shouldBe` [[0,1,3,5],[1,2,4,6]]
      izipWith3 (\i a b c -> [i,a,b,c]) [1,2,0] [3,4] [5,6]
        `shouldBe` [[0,1,3,5],[1,2,4,6]]
  describe "strictness" $ do
    -- The point of this test is that zipWith should stop when it sees an
    -- empty list, even if other lists are undefined
    let u :: Bool
        u = undefined
    let su :: [Bool]
        su = undefined
    let em :: [Bool]
        em = []
    specify "2" $ do
      izipWith undefined em su `shouldBe` em
    specify "3" $ do
      izipWith3 undefined em  su su `shouldBe` em
      izipWith3 undefined [u] em su `shouldBe` em
    specify "4" $ do
      izipWith4 undefined em  su  su su `shouldBe` em
      izipWith4 undefined [u] em  su su `shouldBe` em
      izipWith4 undefined [u] [u] em su `shouldBe` em
