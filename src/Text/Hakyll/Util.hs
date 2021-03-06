module Text.Hakyll.Util 
    ( toDestination,
      toCache,
      makeDirectories,
      getRecursiveContents,
      trim,
      split,
      isCacheFileValid
    ) where

import System.Directory
import System.FilePath
import Control.Monad
import Data.Char
import Data.List

toDestination :: FilePath -> FilePath
toDestination path = "_site" </> path

toCache :: FilePath -> FilePath
toCache path = "_cache" </> path

-- | Given a path to a file, try to make the path writable by making
--   all directories on the path.
makeDirectories :: FilePath -> IO ()
makeDirectories path = createDirectoryIfMissing True dir
    where dir = takeDirectory path

-- | Get all contents of a directory. Note that files starting with a dot (.)
--   will be ignored.
getRecursiveContents :: FilePath -> IO [FilePath]
getRecursiveContents topdir = do
    names <- getDirectoryContents topdir
    let properNames = filter isProper names
    paths <- forM properNames $ \name -> do
        let path = topdir </> name
        isDirectory <- doesDirectoryExist path
        if isDirectory
            then getRecursiveContents path
            else return [path]
    return (concat paths)
    where isProper = not . (== '.') . head

-- | Trim a string (drop spaces and tabs at both sides).
trim :: String -> String
trim = reverse . trim' . reverse . trim'
    where trim' = dropWhile isSpace

-- | Split a list at a certain element.
split :: (Eq a) => a -> [a] -> [[a]]
split element = unfoldr splitOnce
    where splitOnce l = let r = break (== element) l
                        in case r of ([], []) -> Nothing
                                     (x, xs) -> if null xs
                                                    then Just (x, [])
                                                    else Just (x, tail xs)

-- | Check is a cache file is still valid.
isCacheFileValid :: FilePath -> FilePath -> IO Bool
isCacheFileValid cache file = doesFileExist cache >>= \exists ->
    if not exists then return False
                  else liftM2 (<=) (getModificationTime file)
                                   (getModificationTime cache)
