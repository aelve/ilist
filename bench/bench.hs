{-# LANGUAGE
BangPatterns,
MagicHash
  #-}


import Data.List
import Control.Monad
import Control.Monad.Trans.State.Lazy
import GHC.Exts

import Data.List.Index

import Criterion
import Criterion.Main


main :: IO ()
main = defaultMain [

  bgroup "iall" [
      bgroup "full" [
          bench "zip" $ nf (\n -> iall_zip (==) [0..n]) 100000,
          bench "map" $ nf (\n -> iall_map (==) [0..n]) 100000,
          bench "rec" $ nf (\n -> iall_rec (==) [0..n]) 100000,
          bench "our" $ nf (\n -> iall (==) [0..n]) 100000 ],
      bgroup "early" [
          bench "zip" $ nf (\n -> iall_zip (/=) [0..n]) 100000,
          bench "map" $ nf (\n -> iall_map (/=) [0..n]) 100000,
          bench "rec" $ nf (\n -> iall_rec (/=) [0..n]) 100000,
          bench "our" $ nf (\n -> iall (/=) [0..n]) 100000 ] ],

  bgroup "imap" [
      bgroup "consume" [
          bench "rec" $ nf (\n -> sum $ imap_rec (+) [0..n]) 100000,
          bench "fold" $ nf (\n -> sum $ imap_fold (+) [0..n]) 100000,
          bench "zip" $ nf (\n -> sum $ imap_zip (+) [0..n]) 100000,
          bench "our" $ nf (\n -> sum $ imap (+) [0..n]) 100000 ],
      bgroup "full" [
          bench "rec" $ nf (\n -> imap_rec (+) [0..n]) 100000,
          bench "fold" $ nf (\n -> imap_fold (+) [0..n]) 100000,
          bench "zip" $ nf (\n -> imap_zip (+) [0..n]) 100000,
          bench "our" $ nf (\n -> imap (+) [0..n]) 100000 ] ],

  bgroup "imapM" [
      bgroup "Just" [
          bench "zip" $ nf (\n -> imapM_zip (\i x -> if i==x then Just i else Nothing) [0..n]) 100000,
          bench "zipWith" $ nf (\n -> imapM_zipWith (\i x -> if i==x then Just i else Nothing) [0..n]) 100000,
          bench "rec" $ nf (\n -> imapM_rec (\i x -> if i==x then Just i else Nothing) [0..n]) 100000,
          bench "our" $ nf (\n -> imapM (\i x -> if i==x then Just i else Nothing) [0..n]) 100000 ],
      bgroup "State" [
          bench "zip" $ nf (\n -> flip runState [] $ imapM_zip (\i x -> modify ((i+x):) >> return (i-x)) [0..n]) 100000,
          bench "zipWith" $ nf (\n -> flip runState [] $ imapM_zipWith (\i x -> modify ((i+x):) >> return (i-x)) [0..n]) 100000,
          bench "rec" $ nf (\n -> flip runState [] $ imapM_rec (\i x -> modify ((i+x):) >> return (i-x)) [0..n]) 100000,
          bench "our" $ nf (\n -> flip runState [] $ imapM (\i x -> modify ((i+x):) >> return (i-x)) [0..n]) 100000 ] ],

  bgroup "ifilter" [
      bench "rec" $ nf (\n -> ifilter_rec (\i x -> rem (i+x) 5000 == 0) [0..n]) 100000,
      bench "fold" $ nf (\n -> ifilter_fold (\i x -> rem (i+x) 5000 == 0) [0..n]) 100000,
      bench "zip" $ nf (\n -> ifilter_zip (\i x -> rem (i+x) 5000 == 0) [0..n]) 100000,
      bench "our" $ nf (\n -> ifilter (\i x -> rem (i+x) 5000 == 0) [0..n]) 100000 ],

  bgroup "ifindIndices" [
      bench "rec" $ nf (\n -> ifindIndices_rec (\i x -> rem (i+x) 5000 == 0) [0..n]) 100000,
      bench "fold" $ nf (\n -> ifindIndices_fold (\i x -> rem (i+x) 5000 == 0) [0..n]) 100000,
      bench "zip" $ nf (\n -> ifindIndices_zip (\i x -> rem (i+x) 5000 == 0) [0..n]) 100000,
      bench "our" $ nf (\n -> ifindIndices (\i x -> rem (i+x) 5000 == 0) [0..n]) 100000 ],

  bgroup "ifoldr" [
      bench "zip" $ nf (\n -> ifoldr_zip (\i a x -> if rem x 16 == 0 then a+3*i else a+x) 0 [0..n]) 100000,
      bench "our" $ nf (\n -> ifoldr (\i a x -> if rem x 16 == 0 then a+3*i else a+x) 0 [0..n]) 100000 ],

  bgroup "ifoldr1" [
      bench "zip" $ nf (\n -> ifoldr1_zip (\i a x -> if rem x 16 == 0 then a+3*i else a+x) [0..n]) 100000,
      bench "our" $ nf (\n -> ifoldr1 (\i a x -> if rem x 16 == 0 then a+3*i else a+x) [0..n]) 100000 ],

  bgroup "ifoldl" [
      bench "zip" $ nf (\n -> ifoldl_zip (\a i x -> if rem x 16 == 0 then a+3*i else a+x) 0 [0..n]) 100000,
      bench "fold" $ nf (\n -> ifoldl_fold (\a i x -> if rem x 16 == 0 then a+3*i else a+x) 0 [0..n]) 100000,
      bench "our" $ nf (\n -> ifoldl (\a i x -> if rem x 16 == 0 then a+3*i else a+x) 0 [0..n]) 100000 ],

  bgroup "ifoldl'" [
      bench "zip" $ nf (\n -> ifoldl'_zip (\a i x -> if rem x 16 == 0 then a+3*i else a+x) 0 [0..n]) 100000,
      bench "fold" $ nf (\n -> ifoldl'_fold (\a i x -> if rem x 16 == 0 then a+3*i else a+x) 0 [0..n]) 100000,
      bench "our" $ nf (\n -> ifoldl' (\a i x -> if rem x 16 == 0 then a+3*i else a+x) 0 [0..n]) 100000 ] ]

imapM_zip :: Monad m => (Int -> a -> m b) -> [a] -> m [b]
imapM_zip f xs = mapM (uncurry f) (zip [0..] xs)
{-# INLINE imapM_zip #-}

imapM_zipWith :: Monad m => (Int -> a -> m b) -> [a] -> m [b]
imapM_zipWith f xs = zipWithM f [0..] xs
{-# INLINE imapM_zipWith #-}

imapM_rec :: Monad m => (Int -> a -> m b) -> [a] -> m [b]
imapM_rec f as = go 0# as
  where
    go _ [] = return []
    go i (x:xs) = do
      x' <- f (I# i) x
      xs' <- go (i +# 1#) xs
      return (x':xs')
{-# INLINE imapM_rec #-}

iall_zip :: (Int -> a -> Bool) -> [a] -> Bool
iall_zip p xs = and (zipWith p [0..] xs)
{-# INLINE iall_zip #-}

iall_map :: (Int -> a -> Bool) -> [a] -> Bool
iall_map f xs = and (imap f xs)
{-# INLINE iall_map #-}

iall_rec :: (Int -> a -> Bool) -> [a] -> Bool
iall_rec p = go 0#
  where
    go _ [] = True
    go i (x:xs) = p (I# i) x && go (i +# 1#) xs
{-# INLINE iall_rec #-}

ifoldr_zip :: (Int -> a -> b -> b) -> b -> [a] -> b
ifoldr_zip f a xs = foldr (\(i, x) acc -> f i x acc) a (zip [0..] xs)
{-# INLINE ifoldr_zip #-}

ifoldr1_zip :: (Int -> a -> a -> a) -> [a] -> a
ifoldr1_zip f xs = snd (foldr1 (\(i, x) (j, y) -> (j, f i x y)) (zip [0..] xs))
{-# INLINE ifoldr1_zip #-}

ifoldl_zip :: (b -> Int -> a -> b) -> b -> [a] -> b
ifoldl_zip f a xs = foldl (\acc (!i, x) -> f acc i x) a (zip [0..] xs)
{-# INLINE ifoldl_zip #-}

ifoldl'_zip :: (b -> Int -> a -> b) -> b -> [a] -> b
ifoldl'_zip f a xs = foldl' (\acc (!i, x) -> f acc i x) a (zip [0..] xs)
{-# INLINE ifoldl'_zip #-}

ifoldl_fold :: (b -> Int -> a -> b) -> b -> [a] -> b
ifoldl_fold f z xs = foldl (\g x !i -> f (g (i-1)) i x) (const z) xs (length xs - 1)
{-# INLINE ifoldl_fold #-}

ifoldl'_fold :: (b -> Int -> a -> b) -> b -> [a] -> b
ifoldl'_fold f z xs = foldl' (\g x !i -> f (g (i - 1)) i x) (const z) xs (length xs - 1)
{-# INLINE ifoldl'_fold #-}

imap_rec :: (Int -> a -> b) -> [a] -> [b]
imap_rec p = go 0#
  where
    go _ [] = []
    go i (x:xs) = p (I# i) x : go (i +# 1#) xs
{-# INLINE imap_rec #-}

imap_fold :: (Int -> a -> b) -> [a] -> [b]
imap_fold f = ifoldr (\i x xs -> f i x : xs) []
{-# INLINE imap_fold #-}

imap_zip :: (Int -> a -> b) -> [a] -> [b]
imap_zip p xs = zipWith p [0..] xs
{-# INLINE imap_zip #-}

ifilter_rec :: (Int -> a -> Bool) -> [a] -> [a]
ifilter_rec p = go 0#
  where
    go _ [] = []
    go i (x:xs) | p (I# i) x = x : go (i +# 1#) xs
                | otherwise = go (i +# 1#) xs
{-# INLINE ifilter_rec #-}

ifilter_fold :: (Int -> a -> Bool) -> [a] -> [a]
ifilter_fold p = ifoldr (\i x xs -> if p i x then x : xs else xs) []
{-# INLINE ifilter_fold #-}

ifilter_zip :: (Int -> a -> Bool) -> [a] -> [a]
ifilter_zip p xs = map snd (filter (uncurry p) (zip [0..] xs))
{-# INLINE ifilter_zip #-}

ifindIndices_rec :: (Int -> a -> Bool) -> [a] -> [Int]
ifindIndices_rec p = go 0#
  where
    go _ [] = []
    go i (x:xs) | p (I# i) x = I# i : go (i +# 1#) xs
                | otherwise  = go (i +# 1#) xs

ifindIndices_fold :: (Int -> a -> Bool) -> [a] -> [Int]
ifindIndices_fold p = ifoldr (\i x xs -> if p i x then i : xs else xs) []
{-# INLINE ifindIndices_fold #-}

ifindIndices_zip :: (Int -> a -> Bool) -> [a] -> [Int]
ifindIndices_zip p xs = map fst (filter (uncurry p) (zip [0..] xs))
{-# INLINE ifindIndices_zip #-}