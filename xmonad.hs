-- vim:ft=haskell:sts=2:sw=2:et:

import XMonad
import XMonad.Actions.NoBorders
import XMonad.Hooks.ManageHelpers
import XMonad.Layout.NoBorders

import Control.Monad
import System.Directory
import System.Exit
import System.Posix.IO
import System.Posix.Process
import System.Posix.Signals

import qualified XMonad.StackSet as W

import qualified Data.Map as M

-- This implements the process for becoming a daemon as described
-- in Stevens with a few exceptions. The current directory is changed
-- to the user's home directory instead of the root directory as that
-- feels more natural for shells. We leave the file creation mask
-- alone as the user's default is probably what they want.
-- File descriptors other than standard IO aren't closed as doing so
-- is not reasonably possible in Haskell.
mySpawn :: MonadIO m => FilePath -> [String] -> m ()
mySpawn exe args = io $ void $ forkProcess $ doFork
  where
    doFork = do
      XMonad.uninstallSignalHandlers
      createSession
      void $ forkProcess $ doExec
      exitImmediately ExitSuccess

    doExec = do
      getHomeDirectory >>= setCurrentDirectory
      reopenStreams
      executeFile exe True args Nothing

    reopenStreams = do
      null <- openFd "/dev/null" ReadWrite Nothing defaultFileFlags
      let sendTo fd' fd = closeFd fd >> dupTo fd' fd
      mapM_ (sendTo null) $ [ stdInput, stdOutput, stdError ]

mySpawn' :: MonadIO m => FilePath -> m ()
mySpawn' x = mySpawn x []

myKeys :: XConfig Layout -> M.Map (KeyMask, KeySym) (X ())
myKeys conf@(XConfig {XMonad.modMask = modMask}) = M.fromList $
    [ ((modMask .|. shiftMask,  xK_Return   ), mySpawn' $ terminal conf)
    , ((modMask              ,  xK_Return   ), mySpawn' "gmrun")
    , ((mod4Mask,               xK_l        ), mySpawn' "slock")

    , ((modMask,                xK_space    ), sendMessage NextLayout)
    , ((modMask .|. shiftMask,  xK_space    ), setLayout $ layoutHook conf)

    , ((modMask .|. shiftMask,  xK_c        ), kill)

    , ((modMask,                xK_j        ), windows W.focusDown)
    , ((modMask,                xK_k        ), windows W.focusUp)
    , ((modMask,                xK_m        ), windows W.focusMaster)

    , ((modMask .|. shiftMask,  xK_j        ), windows W.swapDown)
    , ((modMask .|. shiftMask,  xK_k        ), windows W.swapUp)
    , ((modMask .|. shiftMask,  xK_m        ), windows W.swapMaster)

    , ((modMask,                xK_h        ), sendMessage Shrink)
    , ((modMask,                xK_l        ), sendMessage Expand)

    , ((modMask,                xK_comma    ), sendMessage (IncMasterN 1))
    , ((modMask,                xK_period   ), sendMessage (IncMasterN (-1)))

    , ((modMask,                xK_t        ), withFocused $ windows . W.sink)
--    , ((modMask .|. shiftMask,  xK_t        ), withFocused $ windows . W.float)

    , ((modMask,                xK_g        ), withFocused $ toggleBorder)

    , ((modMask .|. shiftMask,  xK_q        ), io exitSuccess)
    , ((modMask,                xK_q        ), spawn (
        "if type xmonad; then xmonad --recompile && xmonad --restart;"
        ++ " else xmessage xmonad not in \\$PATH: \"$PATH\"; fi"))
    ]
    ++
    [ ((m .|. modMask, k), windows $ f i)
        | (i, k) <- zip (XMonad.workspaces conf) ([xK_1 .. xK_9]++[xK_0,xK_minus,xK_equal])
        , (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)] ]
    ++
    [((m .|. modMask, key), screenWorkspace sc >>= flip whenJust (windows . f))
        | (key, sc) <- zip [xK_w, xK_e, xK_r] [0..]
        , (f, m) <- [(W.view, 0), (W.shift, shiftMask)]]

main = xmonad $ defaultConfig
    { terminal = "xterm"
    , workspaces = map show [1 .. 12 :: Int]
    , keys = myKeys
    , layoutHook = smartBorders $ layoutHook defaultConfig
    }
