-- vim:ft=haskell:sts=2:sw=2:et:

import XMonad
import XMonad.Actions.NoBorders
import XMonad.Actions.Warp
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.ManageHelpers
import XMonad.Hooks.Place
import XMonad.Layout.Fullscreen
import XMonad.Layout.NoBorders
import XMonad.Util.Run (spawnPipe, safeSpawn, safeSpawnProg)

import Control.Monad
import System.Directory
import System.Exit
import System.IO
import System.Posix.Env (setEnv)
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
      setEnv "_JAVA_AWT_WM_NONREPARENTING" "1" True
      reopenStreams
      executeFile exe True args Nothing

    reopenStreams = do
      null <- openFd "/dev/null" ReadWrite Nothing defaultFileFlags
      let sendTo fd' fd = closeFd fd >> dupTo fd' fd
      mapM_ (sendTo null) $ [ stdInput, stdOutput, stdError ]

mySpawn' :: MonadIO m => FilePath -> m ()
mySpawn' x = mySpawn x []

fraction :: (Integral a, Integral b) => Rational -> a -> b
fraction f x = floor (f * fromIntegral x)

moveWindowToPointer :: Rational -> Rational -> X ()
moveWindowToPointer h v =
  withDisplay $ \d ->
    withFocused $ \w -> do
      io $ raiseWindow d w
      wa <- io $ getWindowAttributes d w
      (_, _, _, px', py', _, _, _) <- io $ queryPointer d w
      let px = fromIntegral px'
          py = fromIntegral py'
      io $ moveWindow d w (px - fraction h (wa_width wa))
                          (py - fraction v (wa_height wa))
      float w

myKeys :: XConfig Layout -> M.Map (KeyMask, KeySym) (X ())
myKeys conf@(XConfig {XMonad.modMask = modMask}) = M.fromList $
    [ ((modMask .|. shiftMask,  xK_Return   ), mySpawn' $ terminal conf)
    , ((modMask              ,  xK_Return   ), mySpawn' "gmrun")
    , ((mod4Mask,               xK_l        ), mySpawn "xscreensaver-command" ["-lock"])
    , ((mod4Mask .|. shiftMask, xK_l        ), mySpawn "systemctl" ["suspend"])

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

    , ((modMask,                xK_d        ), moveWindowToPointer 0.5 0.5)

    , ((modMask,                xK_b        ), sendMessage ToggleStruts)

    , ((modMask .|. shiftMask,  xK_q        ), io exitSuccess)
    , ((modMask,                xK_q        ), spawn (
        "if type xmonad; then xmonad --recompile && xmonad --restart;"
        ++ " else xmessage xmonad not in \\$PATH: \"$PATH\"; fi"))
    ]
    ++
    [ ((m .|. s .|. modMask, k), windows $ f i)
        | (i, (k, m)) <- zip (XMonad.workspaces conf) [ (k, m)
            | m <- [0, controlMask]
            , k <- ([xK_1 .. xK_9] ++ [xK_0, xK_minus, xK_equal])
            ]
        , (f, s) <- [(W.greedyView, 0), (W.shift, shiftMask)]
        ]
    ++
    [((m .|. modMask, key), screenWorkspace sc >>= flip whenJust (windows . f))
        | (key, sc) <- zip [xK_w, xK_e, xK_r] [0..]
        , (f, m) <- [(W.view, 0), (W.shift, shiftMask)]]


isChrome =
       className =? "Chromium-browser"
  <||> className =? "chromium-browser"
  <||> className =? "Chromium"
  <||> className =? "chromium"
  <||> className =? "Google-chrome"
  <||> className =? "google-chrome"


myManageHook = composeAll
  [ isDialog --> doCenterFloat
  , isChrome <&&> title =? "Authy" --> doFloat
  , className =? "mpv" --> doFloat
  , className =? "Gimp" --> doFloat
  , className =? "Pinentry" --> doFloat
  , placeHook( inBounds( underMouse( 0, 0 )))
  , manageDocks
  , fullscreenManageHook
  ]



myEventHook = composeAll
  [ fullscreenEventHook
  , docksEventHook
  ]



myLayoutHook =
  avoidStruts $
  smartBorders $
  fullscreenFull $
  fullscreenFloat $
  layoutHook defaultConfig



setFullscreenSupported :: X()
setFullscreenSupported = withDisplay $ \d -> do
  r <- asks theRoot
  a <- getAtom "_NET_SUPPORTED"
  c <- getAtom "ATOM"
  v <- getAtom "_NET_WM_STATE_FULLSCREEN"
  io $ changeProperty32 d r a c propModeAppend [fromIntegral v]



myStartupHook :: X()
myStartupHook = do
    safeSpawn "trayer"
        [ "--edge", "top", "--align", "left"
        , "--monitor", "primary"
        , "--widthtype", "request"
        , "--heighttype", "pixel", "--height", "24"
        , "--transparent", "true", "--alpha", "255"
        ]

    safeSpawnProg "nm-applet"

    setFullscreenSupported


main = do
    xmproc <- spawnPipe "xmobar"

    xmonad $ defaultConfig
        { terminal = "xterm"
        , workspaces = [ m ++ k
            | m <- ["", "^"]
            , k <- (map show [1..9 :: Int]) ++ ["0", "-", "+"]
            ]
        , keys = myKeys
        , manageHook = myManageHook
        , layoutHook = myLayoutHook
        , handleEventHook = myEventHook
        , startupHook = myStartupHook
        , logHook = dynamicLogWithPP xmobarPP
            { ppOutput = hPutStrLn xmproc
            , ppTitle  = xmobarColor "green" "" . shorten 50
            }
        }
